import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized configuration for the Supabase integration.
///
/// The project URL and anon key are injected at build time via
/// `--dart-define-from-file=env/supabase.json`, so gym owners never have to
/// type credentials. The anon key is safe to ship because every table is
/// protected by row-level security tied to the signed-in owner.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const _storage = FlutterSecureStorage();
  static const String _keyGymId = 'supabase_active_gym_id';
  static const String _keyLastSyncAt = 'supabase_last_sync_at';

  /// The cloud gym id (UUID) this device is bound to. Null until the admin
  /// creates or restores a gym under their account.
  static Future<String?> getActiveGymId() => _storage.read(key: _keyGymId);

  static Future<void> setActiveGymId(String gymId) async {
    await _storage.write(key: _keyGymId, value: gymId);
  }

  static Future<DateTime?> getLastSyncAt() async {
    final val = await _storage.read(key: _keyLastSyncAt);
    return val != null ? DateTime.tryParse(val) : null;
  }

  static Future<void> setLastSyncAt(DateTime time) async {
    await _storage.write(key: _keyLastSyncAt, value: time.toIso8601String());
  }

  /// Forgets the cloud binding (used on sign-out / reset).
  static Future<void> clearBinding() async {
    await _storage.delete(key: _keyGymId);
    await _storage.delete(key: _keyLastSyncAt);
  }
}
