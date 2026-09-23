import 'package:mongo_dart/mongo_dart.dart';
import 'data_mode_service.dart';

/// Result of a connection attempt/test, used by the Settings UI to show a
/// clear success/failure message instead of a raw exception.
class MongoConnectionResult {
  final bool success;
  final String message;
  const MongoConnectionResult(this.success, this.message);
}

/// Owns the single live [Db] connection used while the app is in
/// [DataMode.online]. The connection URI/credentials are never hardcoded —
/// they're supplied at runtime by the admin via Settings and read from
/// [DataModeService] (secure storage) only when actually needed.
class MongoConnectionService {
  MongoConnectionService._internal();
  static final MongoConnectionService instance = MongoConnectionService._internal();

  Db? _db;
  String? _connectedUri;

  /// Returns the active, open [Db] for the given connection URI, opening a
  /// new connection only if none is open yet or the URI changed.
  Future<Db> _open(String uri) async {
    if (_db != null && _connectedUri == uri && _db!.state == State.open) {
      return _db!;
    }
    await _closeQuietly();
    final db = await Db.create(uri);
    await db.open();
    _db = db;
    _connectedUri = uri;
    return db;
  }

  /// Opens (or reuses) the connection configured in Settings. Throws a
  /// [StateError] if MongoDB connection details haven't been saved yet.
  Future<Db> getActiveDb() async {
    final uri = await DataModeService.instance.getMongoUri();
    if (uri == null || uri.trim().isEmpty) {
      throw StateError('MongoDB connection is not configured yet. Set it up in Settings first.');
    }
    return _open(uri.trim());
  }

  /// Opens a throwaway connection to verify the given URI/credentials work,
  /// without affecting the currently active connection. Always closes
  /// afterwards. Used by the "Test Connection" button in Settings.
  Future<MongoConnectionResult> testConnection(String uri) async {
    Db? testDb;
    try {
      testDb = await Db.create(uri.trim());
      await testDb.open();
      await testDb.pingCommand();
      return const MongoConnectionResult(true, 'Connected successfully.');
    } catch (e) {
      return MongoConnectionResult(false, _friendlyError(e));
    } finally {
      try {
        await testDb?.close();
      } catch (_) {}
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Authentication failed') || msg.contains('AuthenticationFailed')) {
      return 'Authentication failed — check username/password in the connection string.';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('Connection timed out')) {
      return 'Could not reach the server — check the host/network and that your IP is allow-listed on the MongoDB cluster.';
    }
    return 'Connection failed: $msg';
  }

  Future<void> _closeQuietly() async {
    try {
      await _db?.close();
    } catch (_) {}
    _db = null;
    _connectedUri = null;
  }

  Future<void> close() => _closeQuietly();
}
