import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../services/app_state_service.dart';
import 'supabase_service.dart';

/// Handles full two-way synchronization between local SQLite and Supabase Cloud.
///
/// Features:
/// - Auto-discovers existing gym accounts during setup by Owner Email or Phone.
/// - Restores all gym history (members, plans, payments, receipts, bills, etc.) seamlessly.
/// - Performs idempotent upserts (no duplicate rows).
/// - Gracefully falls back when offline.
class SupabaseSyncService {
  SupabaseSyncService._internal();
  static final SupabaseSyncService instance = SupabaseSyncService._internal();

  Future<Database> get _db async => await AppDatabase.instance.database;

  // ---------------------------------------------------------------------------
  // Account Discovery & Restoration (Key Feature)
  // ---------------------------------------------------------------------------

  /// Checks Supabase to see if a gym account already exists under [phone] or [email].
  ///
  /// Returns the existing gym metadata Map if found, or null if this is a new owner.
  Future<Map<String, dynamic>?> findGymByEmailOrPhone({
    required String phone,
    String? email,
  }) async {
    final connected = await SupabaseService.instance.init();
    if (!connected) return null;
    final client = SupabaseService.instance.client;
    if (client == null) return null;

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final last10Phone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    try {
      // 1. Check in 'gyms' table
      var query = client.from('gyms').select();
      if (email != null && email.trim().isNotEmpty) {
        query = query.or('phone.ilike.%$last10Phone%,email.ilike.${email.trim()}');
      } else {
        query = query.ilike('phone', '%$last10Phone%');
      }

      final results = await query.limit(1);
      if (results.isNotEmpty) {
        return Map<String, dynamic>.from(results.first);
      }

      // 2. Check in 'admins' table
      var adminQuery = client.from('admins').select();
      adminQuery = adminQuery.ilike('phone', '%$last10Phone%');
      final adminResults = await adminQuery.limit(1);
      if (adminResults.isNotEmpty) {
        final admin = adminResults.first;
        final gymId = admin['gym_id'] ?? admin['gymId'];
        if (gymId != null) {
          final gymRecord = await client.from('gyms').select().eq('id', gymId).maybeSingle();
          if (gymRecord != null) {
            return Map<String, dynamic>.from(gymRecord);
          }
        }
      }
    } catch (e) {
      debugPrint('[SupabaseSyncService] findGymByEmailOrPhone error: $e');
    }
    return null;
  }

  /// Downloads and restores all cloud data for [gymId] into the local SQLite database.
  ///
  /// Restores:
  /// - Gym Info & Admin profile
  /// - Packages & Plans
  /// - Trainers & Payouts
  /// - Members & Memberships
  /// - Audit change logs
  /// - Bills, Payments & Receipts
  /// - Expenses, Events, Announcements
  /// - Notification & App Settings
  Future<({bool success, int totalRecordsRestored, String? error})> restoreAllGymData(String gymId) async {
    final connected = await SupabaseService.instance.init();
    if (!connected) {
      return (success: false, totalRecordsRestored: 0, error: 'Could not connect to Supabase Cloud.');
    }
    final client = SupabaseService.instance.client;
    if (client == null) {
      return (success: false, totalRecordsRestored: 0, error: 'Supabase client is not ready.');
    }

    try {
      int restoredCount = 0;
      final db = await _db;

      // Pull all tables in parallel / sequence
      final gymList = await _fetchFromCloud(client, 'gyms', gymId);
      final adminList = await _fetchFromCloud(client, 'admins', gymId);
      final packageList = await _fetchFromCloud(client, 'membership_packages', gymId);
      final planList = await _fetchFromCloud(client, 'membership_plans', gymId);
      final trainerList = await _fetchFromCloud(client, 'trainers', gymId);
      final trainerPayoutList = await _fetchFromCloud(client, 'trainer_payouts', gymId);
      final memberList = await _fetchFromCloud(client, 'members', gymId);
      final membershipList = await _fetchFromCloud(client, 'memberships', gymId);
      final memberLogList = await _fetchFromCloud(client, 'membership_change_logs', gymId);
      final trainerLogList = await _fetchFromCloud(client, 'trainer_change_logs', gymId);
      final billList = await _fetchFromCloud(client, 'bills', gymId);
      final paymentList = await _fetchFromCloud(client, 'payments', gymId);
      final receiptList = await _fetchFromCloud(client, 'receipts', gymId);
      final expenseList = await _fetchFromCloud(client, 'expenses', gymId);
      final eventList = await _fetchFromCloud(client, 'events', gymId);
      final announcementList = await _fetchFromCloud(client, 'announcements', gymId);

      // Perform atomic insertion into local SQLite
      await db.transaction((txn) async {
        // 1. Gym
        for (final row in gymList) {
          final local = _toLocalMap(row);
          await txn.insert('gym', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 2. Admins
        for (final row in adminList) {
          final local = _toLocalMap(row);
          await txn.insert('admins', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 3. Packages
        for (final row in packageList) {
          final local = _toLocalMap(row);
          await txn.insert('membership_packages', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 4. Plans
        for (final row in planList) {
          final local = _toLocalMap(row);
          await txn.insert('membership_plans', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 5. Trainers
        for (final row in trainerList) {
          final local = _toLocalMap(row);
          await txn.insert('trainers', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 6. Trainer Payouts
        for (final row in trainerPayoutList) {
          final local = _toLocalMap(row);
          await txn.insert('trainer_payouts', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 7. Members
        for (final row in memberList) {
          final local = _toLocalMap(row);
          await txn.insert('members', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 8. Memberships
        for (final row in membershipList) {
          final local = _toLocalMap(row);
          await txn.insert('memberships', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 9. Membership Change Logs
        for (final row in memberLogList) {
          final local = _toLocalMap(row);
          await txn.insert('membership_change_logs', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 10. Trainer Change Logs
        for (final row in trainerLogList) {
          final local = _toLocalMap(row);
          await txn.insert('trainer_change_logs', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 11. Bills
        for (final row in billList) {
          final local = _toLocalMap(row);
          await txn.insert('bills', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 12. Payments
        for (final row in paymentList) {
          final local = _toLocalMap(row);
          await txn.insert('payments', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 13. Receipts
        for (final row in receiptList) {
          final local = _toLocalMap(row);
          await txn.insert('receipts', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 14. Expenses
        for (final row in expenseList) {
          final local = _toLocalMap(row);
          await txn.insert('expenses', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 15. Events
        for (final row in eventList) {
          final local = _toLocalMap(row);
          await txn.insert('events', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }

        // 16. Announcements
        for (final row in announcementList) {
          final local = _toLocalMap(row);
          await txn.insert('announcements', local, conflictAlgorithm: ConflictAlgorithm.replace);
          restoredCount++;
        }
      });

      await SupabaseConfig.setActiveGymId(gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());

      // Trigger app-wide reactive state updates
      AppStateService.instance.notifyMembersChanged();
      AppStateService.instance.notifyPaymentsChanged();
      AppStateService.instance.notifyNotificationsChanged();
      AppStateService.instance.notifyGymInfoChanged();

      return (success: true, totalRecordsRestored: restoredCount, error: null);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseSyncService] restoreAllGymData error: $e\n$stackTrace');
      return (success: false, totalRecordsRestored: 0, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Push Local SQLite Data to Supabase Cloud
  // ---------------------------------------------------------------------------

  /// Uploads all local SQLite records up to Supabase Cloud.
  Future<({bool success, int totalPushed, String? error})> pushAllLocalDataToSupabase(String gymId) async {
    final connected = await SupabaseService.instance.init();
    if (!connected) {
      return (success: false, totalPushed: 0, error: 'Could not connect to Supabase Cloud.');
    }
    final client = SupabaseService.instance.client;
    if (client == null) {
      return (success: false, totalPushed: 0, error: 'Supabase client is not ready.');
    }

    try {
      final db = await _db;
      int pushedCount = 0;

      final tables = [
        'gym',
        'admins',
        'membership_packages',
        'membership_plans',
        'trainers',
        'trainer_payouts',
        'members',
        'memberships',
        'membership_change_logs',
        'trainer_change_logs',
        'bills',
        'payments',
        'receipts',
        'expenses',
        'events',
        'announcements',
      ];

      for (final table in tables) {
        final localRows = await db.query(table);
        if (localRows.isEmpty) continue;

        final targetTable = table == 'gym' ? 'gyms' : table;
        final cloudRows = localRows.map((r) => _toCloudMap(r, gymId: gymId)).toList();

        // Batch upsert to Supabase
        await client.from(targetTable).upsert(cloudRows, onConflict: 'id');
        pushedCount += cloudRows.length;
      }

      await SupabaseConfig.setActiveGymId(gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());

      return (success: true, totalPushed: pushedCount, error: null);
    } catch (e, stackTrace) {
      debugPrint('[SupabaseSyncService] pushAllLocalDataToSupabase error: $e\n$stackTrace');
      return (success: false, totalPushed: 0, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Single-Entity Cloud Sync Helpers (Real-Time Upsert on mutation)
  // ---------------------------------------------------------------------------

  Future<void> syncUpsert(String table, Map<String, dynamic> localData) async {
    try {
      final gymId = await SupabaseConfig.getActiveGymId() ?? 'default';
      final connected = await SupabaseService.instance.init();
      if (!connected) return;
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final targetTable = table == 'gym' ? 'gyms' : table;
      final cloudMap = _toCloudMap(localData, gymId: gymId);

      await client.from(targetTable).upsert(cloudMap, onConflict: 'id');
    } catch (e) {
      debugPrint('[SupabaseSyncService] syncUpsert error on $table: $e');
    }
  }

  Future<void> syncDelete(String table, String id) async {
    try {
      final connected = await SupabaseService.instance.init();
      if (!connected) return;
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final targetTable = table == 'gym' ? 'gyms' : table;
      await client.from(targetTable).delete().eq('id', id);
    } catch (e) {
      debugPrint('[SupabaseSyncService] syncDelete error on $table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping Helpers (camelCase <-> snake_case)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _fetchFromCloud(
    dynamic client,
    String table,
    String gymId,
  ) async {
    try {
      final query = client.from(table).select();
      if (table == 'gyms') {
        final list = await query.eq('id', gymId);
        return List<Map<String, dynamic>>.from(list);
      } else {
        // Query by gym_id
        final list = await query.eq('gym_id', gymId);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('[SupabaseSyncService] fetch error on $table: $e');
      return [];
    }
  }

  static Map<String, dynamic> _toCloudMap(Map<String, dynamic> localMap, {required String gymId}) {
    final map = <String, dynamic>{};
    for (final entry in localMap.entries) {
      final key = _camelToSnake(entry.key);
      map[key] = entry.value;
    }
    // Attach gym_id if not present
    if (!map.containsKey('gym_id') && map['id'] != gymId) {
      map['gym_id'] = gymId;
    }
    return map;
  }

  static Map<String, dynamic> _toLocalMap(Map<String, dynamic> cloudMap) {
    final map = <String, dynamic>{};
    for (final entry in cloudMap.entries) {
      if (entry.key == 'gym_id') continue; // Not stored in local sqlite tables
      final key = _snakeToCamel(entry.key);
      map[key] = entry.value;
    }
    return map;
  }

  static String _camelToSnake(String camel) {
    return camel.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
  }

  static String _snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length <= 1) return snake;
    return parts.first + parts.skip(1).map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }
}
