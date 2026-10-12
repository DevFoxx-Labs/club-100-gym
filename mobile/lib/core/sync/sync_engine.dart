import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../services/app_state_service.dart';
import 'cloud_mapper.dart';
import 'media_sync.dart';
import 'supabase_service.dart';
import 'sync_schema.dart';
import 'sync_tables.dart';

enum SyncPhase { disabled, signedOut, idle, syncing, offline, error }

class SyncStatus {
  final SyncPhase phase;
  final int pendingChanges;
  final DateTime? lastSyncedAt;
  final String? error;

  const SyncStatus({required this.phase, this.pendingChanges = 0, this.lastSyncedAt, this.error});
}

/// Offline-first sync between local SQLite and Supabase.
///
/// Push: drains `sync_outbox` (filled by SQLite triggers) in batches —
/// rows that still exist locally are upserted, rows that no longer exist are
/// soft-deleted in the cloud. Pull: fetches rows changed since each table's
/// `server_updated_at` cursor and applies them with triggers muted, skipping
/// rows that still have un-pushed local edits.
class SyncEngine {
  SyncEngine._internal();
  static final SyncEngine instance = SyncEngine._internal();

  static const _pushBatchSize = 500;
  static const _pullPageSize = 1000;
  static const _inClauseChunk = 200;
  static const _mediaConcurrency = 6;

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus(phase: SyncPhase.idle));

  Timer? _debounce;
  Timer? _periodic;
  Timer? _outboxWatcher;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _running = false;
  bool _rerunRequested = false;
  bool _started = false;
  final Map<String, Set<String>> _columnCache = {};

  /// Automatic retries are held back until this time after a failed or
  /// offline attempt (exponential backoff). Manual "Sync Now" ignores it.
  DateTime? _retryNotBefore;
  int _consecutiveFailures = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Back online: drop any backoff and flush pending changes right away.
        _resetBackoff();
        requestSync(immediate: true);
      }
    });
    // Pulls remote changes made from other devices.
    _periodic = Timer.periodic(const Duration(minutes: 3), (_) => requestSync());
    // Every local write lands in sync_outbox via SQLite triggers; this cheap
    // local check pushes it within seconds, whichever screen made the change.
    _outboxWatcher = Timer.periodic(const Duration(seconds: 5), (_) => _syncIfPending());
    AppStateService.instance.addListener(_onAppStateChanged);
    requestSync(immediate: true);
  }

  void stop() {
    _debounce?.cancel();
    _periodic?.cancel();
    _outboxWatcher?.cancel();
    _connectivitySub?.cancel();
    AppStateService.instance.removeListener(_onAppStateChanged);
    _started = false;
  }

  Future<void> _syncIfPending() async {
    if (_running) return;
    final retryAt = _retryNotBefore;
    if (retryAt != null && DateTime.now().isBefore(retryAt)) return;
    if (SupabaseService.instance.client?.auth.currentUser == null) return;
    try {
      final db = await AppDatabase.instance.database;
      final hasPending =
          Sqflite.firstIntValue(await db.rawQuery('SELECT EXISTS(SELECT 1 FROM sync_outbox)')) == 1;
      if (hasPending) unawaited(syncNow());
    } catch (e) {
      debugPrint('[SyncEngine] outbox check failed: $e');
    }
  }

  void _resetBackoff() {
    _consecutiveFailures = 0;
    _retryNotBefore = null;
  }

  void _scheduleBackoff() {
    _consecutiveFailures++;
    final seconds = math.min(300, 5 * math.pow(2, _consecutiveFailures).toInt());
    _retryNotBefore = DateTime.now().add(Duration(seconds: seconds));
  }

  void _onAppStateChanged() {
    switch (AppStateService.instance.lastEventType) {
      // Pure UI events, or the notifyAll() this engine itself fires after a pull.
      case AppStateEventType.themeChanged:
      case AppStateEventType.languageChanged:
      case AppStateEventType.listDisplayStyleChanged:
      case AppStateEventType.all:
      case null:
        return;
      default:
        requestSync();
    }
  }

  /// Debounced sync request; safe to call from anywhere, any number of times.
  void requestSync({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediate ? Duration.zero : const Duration(seconds: 1), () => syncNow());
  }

  Future<int> pendingCount() async {
    final db = await AppDatabase.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(DISTINCT tableName || rowKey) FROM sync_outbox')) ?? 0;
  }

  Future<bool> syncNow() async {
    if (_running) {
      _rerunRequested = true;
      return false;
    }
    _running = true;
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        await _emit(SyncPhase.disabled);
        return false;
      }
      final user = client.auth.currentUser;
      final gymId = await SupabaseConfig.getActiveGymId();
      if (user == null || gymId == null) {
        await _emit(SyncPhase.signedOut);
        return false;
      }
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        _scheduleBackoff();
        await _emit(SyncPhase.offline);
        return false;
      }

      await _emit(SyncPhase.syncing);
      await _push(client, gymId, user.id);
      final pulled = await _pull(client, gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());
      _resetBackoff();
      if (pulled > 0) AppStateService.instance.notifyAll();
      await _emit(SyncPhase.idle);
      return true;
    } on AuthException catch (e) {
      debugPrint('[SyncEngine] auth error: $e');
      _scheduleBackoff();
      await _emit(SyncPhase.signedOut, error: e.message);
      return false;
    } catch (e, stackTrace) {
      debugPrint('[SyncEngine] sync failed: $e\n$stackTrace');
      _scheduleBackoff();
      final offline = _isNetworkError(e);
      // Network failures are expected (changes stay queued); don't surface
      // them as a red error to the admin.
      await _emit(offline ? SyncPhase.offline : SyncPhase.error, error: offline ? null : e.toString());
      return false;
    } finally {
      _running = false;
      if (_rerunRequested) {
        _rerunRequested = false;
        requestSync();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Push
  // ---------------------------------------------------------------------------

  Future<void> _push(SupabaseClient client, String gymId, String ownerId) async {
    final db = await AppDatabase.instance.database;
    while (true) {
      final batch = await db.query('sync_outbox', orderBy: 'id ASC', limit: _pushBatchSize);
      if (batch.isEmpty) return;
      final maxId = batch.last['id'] as int;

      final keysByTable = <String, Set<String>>{};
      for (final r in batch) {
        keysByTable.putIfAbsent(r['tableName'] as String, () => <String>{}).add(r['rowKey'] as String);
      }

      try {
        for (final table in SyncTables.all) {
          final keys = keysByTable[table.local]?.toList();
          if (keys == null || keys.isEmpty) continue;

          final localRows = <Map<String, Object?>>[];
          for (var i = 0; i < keys.length; i += _inClauseChunk) {
            final chunk = keys.sublist(i, i + _inClauseChunk > keys.length ? keys.length : i + _inClauseChunk);
            localRows.addAll(await db.query(
              table.local,
              where: '"${table.key}" IN (${List.filled(chunk.length, '?').join(',')})',
              whereArgs: chunk,
            ));
          }

          if (localRows.isNotEmpty) {
            var payload = localRows
                .map((r) => CloudMapper.toCloud(table, r, gymId: gymId, ownerId: ownerId))
                .toList();
            payload = await _mapInBatches(payload, (p) => MediaSync.uploadIfLocal(table, p, gymId));
            await client.from(table.cloud).upsert(payload, onConflict: table.isGym ? 'id' : 'gym_id,${table.key}');
          }

          final present = localRows.map((r) => r[table.key].toString()).toSet();
          final deleted = keys.where((k) => !present.contains(k)).toList();
          if (deleted.isNotEmpty && !table.isGym) {
            await client
                .from(table.cloud)
                .update({'is_deleted': true})
                .eq('gym_id', gymId)
                .inFilter(table.key, deleted);
          }
        }
      } catch (e) {
        await db.rawUpdate(
          'UPDATE sync_outbox SET attempts = attempts + 1, lastError = ? WHERE id <= ?',
          [e.toString(), maxId],
        );
        rethrow;
      }

      // Entries enqueued after this batch was read have larger ids and stay queued.
      await db.delete('sync_outbox', where: 'id <= ?', whereArgs: [maxId]);
    }
  }

  // ---------------------------------------------------------------------------
  // Pull
  // ---------------------------------------------------------------------------

  /// Returns the number of remote rows applied locally.
  Future<int> _pull(SupabaseClient client, String gymId) async {
    final db = await AppDatabase.instance.database;
    var applied = 0;
    for (final table in SyncTables.all) {
      final cursorKey = 'pull_cursor:${table.local}';
      final cursor = await _getMeta(db, cursorKey);

      final rows = <Map<String, dynamic>>[];
      var from = 0;
      while (true) {
        var query = client.from(table.cloud).select().eq(table.isGym ? 'id' : 'gym_id', gymId);
        if (cursor != null) query = query.gt('server_updated_at', cursor);
        final page = await query
            .order('server_updated_at', ascending: true)
            .range(from, from + _pullPageSize - 1);
        rows.addAll(page);
        if (page.length < _pullPageSize) break;
        from += _pullPageSize;
      }
      if (rows.isEmpty) continue;

      applied += await _applyRemoteRows(db, table, rows);
      await _setMeta(db, cursorKey, rows.last['server_updated_at'] as String);
    }
    return applied;
  }

  Future<int> _applyRemoteRows(Database db, SyncTable table, List<Map<String, dynamic>> rows) async {
    // Download any remote media files before the transaction (network I/O must
    // not run inside a sqflite transaction).
    final downloadedRows = await _mapInBatches(rows, (r) => MediaSync.downloadIfRemote(table, r));

    final columns = await _localColumns(db, table.local);
    final pending = (await db.query(
      'sync_outbox',
      columns: ['rowKey'],
      where: 'tableName = ?',
      whereArgs: [table.local],
    ))
        .map((r) => r['rowKey'] as String)
        .toSet();

    var applied = 0;
    await db.transaction((txn) async {
      await SyncSchema.muted(txn, () async {
        for (final row in downloadedRows) {
          final local = CloudMapper.toLocal(table, row, columns);
          final key = local[table.key]?.toString();
          if (key == null || pending.contains(key)) continue; // un-pushed local edit wins
          if (row['is_deleted'] == true) {
            await txn.delete(table.local, where: '"${table.key}" = ?', whereArgs: [key]);
          } else {
            await txn.insert(table.local, local, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          applied++;
        }
      });
    });
    return applied;
  }

  // ---------------------------------------------------------------------------
  // Full restore (fresh install / new phone)
  // ---------------------------------------------------------------------------

  /// Replaces ALL local synced data with the cloud copy of [gymId].
  ///
  /// If this device is already bound to [gymId], un-pushed local changes are
  /// uploaded first; when that upload fails the restore is aborted so those
  /// changes are never silently discarded.
  Future<({bool success, int restored, String? error})> restoreFromCloud(String gymId) async {
    final client = SupabaseService.instance.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return (success: false, restored: 0, error: 'Not signed in.');
    }

    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    _running = true;
    try {
      if (await SupabaseConfig.getActiveGymId() == gymId && await pendingCount() > 0) {
        await _push(client, gymId, user.id);
      }
      final db = await AppDatabase.instance.database;
      await SyncSchema.wipeLocalData(db); // also removes seeded default packages/plans
      await SupabaseConfig.setActiveGymId(gymId);
      final restored = await _pull(client, gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());
      _resetBackoff();
      AppStateService.instance.notifyAll();
      await _emit(SyncPhase.idle);
      return (success: true, restored: restored, error: null);
    } catch (e, stackTrace) {
      debugPrint('[SyncEngine] restoreFromCloud failed: $e\n$stackTrace');
      final message = _isNetworkError(e)
          ? 'No internet connection. Please connect and try again.'
          : e.toString();
      return (success: false, restored: 0, error: message);
    } finally {
      _running = false;
    }
  }

  /// Best-effort upload of every pending change, e.g. right before sign-out.
  /// Returns the number of changes still waiting afterwards.
  Future<int> flushPending() async {
    await syncNow();
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return pendingCount();
  }

  /// Runs [fn] over [items] a few at a time, so restoring or uploading
  /// hundreds of member photos doesn't open hundreds of sockets at once.
  static Future<List<Map<String, dynamic>>> _mapInBatches(
    List<Map<String, dynamic>> items,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) fn,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i += _mediaConcurrency) {
      final end = math.min(i + _mediaConcurrency, items.length);
      out.addAll(await Future.wait(items.sublist(i, end).map(fn)));
    }
    return out;
  }

  static bool _isNetworkError(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection closed') ||
        text.contains('Connection refused');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Set<String>> _localColumns(Database db, String table) async {
    final cached = _columnCache[table];
    if (cached != null) return cached;
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final cols = info.map((c) => c['name'] as String).toSet();
    _columnCache[table] = cols;
    return cols;
  }

  Future<String?> _getMeta(Database db, String key) async {
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _setMeta(Database db, String key, String value) async {
    await db.insert('sync_meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _emit(SyncPhase phase, {String? error}) async {
    status.value = SyncStatus(
      phase: phase,
      pendingChanges: await pendingCount(),
      lastSyncedAt: await SupabaseConfig.getLastSyncAt(),
      error: error,
    );
  }
}

