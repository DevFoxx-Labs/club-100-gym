import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data_mode.dart';

/// Persists the Online/Offline storage mode and the admin's own MongoDB
/// connection details.
///
/// Kept in [FlutterSecureStorage] — the same mechanism already used for the
/// login MPIN — rather than the SQLite `app_settings` table, so the
/// connection string (which embeds DB credentials) never sits in the very
/// database it might get wiped/reset with, and is never exposed by a
/// backup/export of the SQLite file.
class DataModeService {
  DataModeService._internal();
  static final DataModeService instance = DataModeService._internal();

  final _storage = const FlutterSecureStorage();

  static const _modeKey = 'data_mode';
  static const _mongoUriKey = 'mongo_connection_uri';
  static const _mongoDbNameKey = 'mongo_database_name';
  static const _lastMigratedAtKey = 'mongo_last_migrated_at';
  static const _lastSyncAtKey = 'mongo_last_sync_at';

  Future<DataMode> getMode() async {
    final value = await _storage.read(key: _modeKey);
    return DataMode.fromStorageValue(value);
  }

  /// Convenience check used at the top of every repository method to decide
  /// whether to route to the MongoDB (Online) or SQLite (Offline) code path.
  Future<bool> get isOnline async => (await getMode()) == DataMode.online;

  Future<void> setMode(DataMode mode) async {
    await _storage.write(key: _modeKey, value: mode.toStorageValue());
  }

  Future<String?> getMongoUri() => _storage.read(key: _mongoUriKey);

  Future<String?> getMongoDatabaseName() => _storage.read(key: _mongoDbNameKey);

  Future<void> saveMongoConnection({required String uri, required String databaseName}) async {
    await _storage.write(key: _mongoUriKey, value: uri.trim());
    await _storage.write(key: _mongoDbNameKey, value: databaseName.trim());
  }

  Future<void> clearMongoConnection() async {
    await _storage.delete(key: _mongoUriKey);
    await _storage.delete(key: _mongoDbNameKey);
  }

  Future<bool> hasMongoConnectionConfigured() async {
    final uri = await getMongoUri();
    final dbName = await getMongoDatabaseName();
    return uri != null && uri.trim().isNotEmpty && dbName != null && dbName.trim().isNotEmpty;
  }

  Future<DateTime?> getLastMigratedAt() async {
    final value = await _storage.read(key: _lastMigratedAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markMigrated() async {
    await _storage.write(key: _lastMigratedAtKey, value: DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSyncAt() async {
    final value = await _storage.read(key: _lastSyncAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markSyncedNow() async {
    await _storage.write(key: _lastSyncAtKey, value: DateTime.now().toIso8601String());
  }
}
