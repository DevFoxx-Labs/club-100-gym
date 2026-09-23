import '../database/app_database.dart';
import 'data_mode_service.dart';
import 'mongo_connection_service.dart';

/// One-time, full push of every local SQLite table into the equivalent
/// MongoDB collection (same table/collection name), run when the admin
/// switches from Offline to Online mode for the first time.
///
/// Automatic two-way sync is intentionally not implemented yet — this is a
/// single one-directional copy (SQLite -> MongoDB) so existing offline data
/// isn't lost the moment Online mode is turned on.
class SyncMigrationService {
  SyncMigrationService._internal();
  static final SyncMigrationService instance = SyncMigrationService._internal();

  /// Table name -> its SQLite primary key column. Used as the Mongo `_id`
  /// for each migrated document.
  static const Map<String, String> tablesAndPrimaryKeys = {
    'gym': 'id',
    'admins': 'id',
    'membership_packages': 'id',
    'membership_plans': 'id',
    'trainers': 'id',
    'trainer_payouts': 'id',
    'trainer_change_logs': 'id',
    'events': 'id',
    'members': 'id',
    'memberships': 'id',
    'membership_change_logs': 'id',
    'payments': 'id',
    'receipts': 'id',
    'notifications': 'id',
    'notification_settings': 'id',
    'announcements': 'id',
    'expenses': 'id',
    'bills': 'id',
    'app_settings': 'key',
    'dismissed_notifications': 'dismissKey',
  };

  /// Pushes every row currently in SQLite into the matching Mongo
  /// collection, upserting by the row's own id (mapped onto Mongo's `_id`).
  /// Upserting by a stable id — instead of inserting — is what makes this
  /// safe to re-run: the same local row always overwrites the same Mongo
  /// document instead of creating a duplicate, and the local copy always
  /// wins since this is a one-directional push.
  Future<Map<String, int>> migrateAllTablesToMongo({
    void Function(String table, int tableIndex, int totalTables)? onProgress,
  }) async {
    final sqliteDb = await AppDatabase.instance.database;
    final mongoDb = await MongoConnectionService.instance.getActiveDb();

    final counts = <String, int>{};
    final tables = tablesAndPrimaryKeys.entries.toList();

    for (var i = 0; i < tables.length; i++) {
      final tableName = tables[i].key;
      final pk = tables[i].value;
      onProgress?.call(tableName, i + 1, tables.length);

      final rows = await sqliteDb.query(tableName);
      final collection = mongoDb.collection(tableName);
      var written = 0;
      for (final row in rows) {
        final id = row[pk];
        if (id == null) continue;
        final doc = Map<String, dynamic>.from(row);
        doc['_id'] = id;
        await collection.replaceOne({'_id': id}, doc, upsert: true);
        written++;
      }
      counts[tableName] = written;
    }

    await DataModeService.instance.markMigrated();
    await DataModeService.instance.markSyncedNow();
    return counts;
  }
}
