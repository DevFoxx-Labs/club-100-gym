import 'package:sqflite/sqflite.dart';
import 'sync_tables.dart';

/// Local bookkeeping for offline-first sync:
/// - `sync_outbox`: one row per local change waiting to be pushed.
/// - `sync_meta`: key/value store (per-table pull cursors).
/// - `sync_control`: single-row flag that mutes the change-capture triggers
///   while remote rows are being applied, so pulled data isn't pushed back.
class SyncSchema {
  static Future<void> ensure(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        rowKey TEXT NOT NULL,
        op TEXT NOT NULL,
        enqueuedAt TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        lastError TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_outbox_row ON sync_outbox(tableName, rowKey);');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_control (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        applyingRemote INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute('INSERT OR IGNORE INTO sync_control (id, applyingRemote) VALUES (1, 0);');
    // Recover from a crash in the middle of applying remote rows.
    await db.execute('UPDATE sync_control SET applyingRemote = 0 WHERE id = 1;');

    for (final t in SyncTables.all) {
      for (final (event, ref, op) in const [
        ('INSERT', 'NEW', 'upsert'),
        ('UPDATE', 'NEW', 'upsert'),
        ('DELETE', 'OLD', 'delete'),
      ]) {
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS trg_sync_${t.local}_${event.toLowerCase()}
          AFTER $event ON ${t.local}
          WHEN (SELECT applyingRemote FROM sync_control WHERE id = 1) = 0
          BEGIN
            INSERT INTO sync_outbox (tableName, rowKey, op, enqueuedAt)
            VALUES ('${t.local}', $ref."${t.key}", '$op', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
          END;
        ''');
      }
    }
  }

  /// Queues every existing local row for upload. Used when a gym is first
  /// bound to a cloud account (new signup, or an existing offline install
  /// connecting to the cloud for the first time).
  static Future<void> enqueueAll(DatabaseExecutor db) async {
    for (final t in SyncTables.all) {
      await db.rawInsert('''
        INSERT INTO sync_outbox (tableName, rowKey, op, enqueuedAt)
        SELECT '${t.local}', "${t.key}", 'upsert', strftime('%Y-%m-%dT%H:%M:%fZ', 'now') FROM ${t.local}
      ''');
    }
  }

  /// Runs [body] with change-capture triggers muted. Must be called inside a
  /// transaction so the flag can never leak to normal app writes.
  static Future<T> muted<T>(Transaction txn, Future<T> Function() body) async {
    await txn.update('sync_control', {'applyingRemote': 1}, where: 'id = 1');
    try {
      return await body();
    } finally {
      await txn.update('sync_control', {'applyingRemote': 0}, where: 'id = 1');
    }
  }

  /// Wipes all synced tables + sync bookkeeping without generating outbox
  /// entries (used before a full cloud restore and on sign-out/reset).
  static Future<void> wipeLocalData(Database db) async {
    await db.transaction((txn) async {
      await muted(txn, () async {
        for (final t in SyncTables.all) {
          await txn.delete(t.local);
        }
      });
      await txn.delete('sync_outbox');
      await txn.delete('sync_meta');
    });
  }
}

