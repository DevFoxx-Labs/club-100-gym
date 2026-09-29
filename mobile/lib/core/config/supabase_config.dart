import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized configuration for Supabase integration.
///
/// Gym owners can paste their project URL and Anon Key directly in the code
/// below, or configure them through the in-app "Supabase Cloud Sync" settings.
class SupabaseConfig {
  /// Default Supabase Project URL (can be edited here or in-app).
  /// Example: 'https://xyzcompany.supabase.co'
  static const String defaultUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Default Supabase Anon Public API Key.
  /// Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String defaultAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const _storage = FlutterSecureStorage();
  static const String _keyUrl = 'supabase_project_url';
  static const String _keyAnonKey = 'supabase_anon_key';
  static const String _keyGymId = 'supabase_active_gym_id';
  static const String _keyLastSyncAt = 'supabase_last_sync_at';

  /// Returns the configured URL from secure storage, falling back to [defaultUrl] if valid.
  static Future<String?> getUrl() async {
    final customUrl = await _storage.read(key: _keyUrl);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    if (defaultUrl.isNotEmpty && !defaultUrl.contains('YOUR_PROJECT_ID')) {
      return defaultUrl;
    }
    return null;
  }

  /// Returns the configured Anon Key from secure storage, falling back to [defaultAnonKey] if valid.
  static Future<String?> getAnonKey() async {
    final customKey = await _storage.read(key: _keyAnonKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    if (defaultAnonKey.isNotEmpty && !defaultAnonKey.contains('YOUR_SUPABASE_ANON_KEY')) {
      return defaultAnonKey;
    }
    return null;
  }

  /// Checks if valid Supabase credentials are configured.
  static Future<bool> isConfigured() async {
    final url = await getUrl();
    final key = await getAnonKey();
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }

  /// Saves custom credentials entered in the app settings.
  static Future<void> saveCredentials({required String url, required String anonKey}) async {
    await _storage.write(key: _keyUrl, value: url.trim());
    await _storage.write(key: _keyAnonKey, value: anonKey.trim());
  }

  /// Clears stored credentials.
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyUrl);
    await _storage.delete(key: _keyAnonKey);
    await _storage.delete(key: _keyGymId);
  }

  /// Gets the currently bound gym UUID in Supabase.
  static Future<String?> getActiveGymId() => _storage.read(key: _keyGymId);

  /// Sets the currently bound gym UUID in Supabase.
  static Future<void> setActiveGymId(String gymId) async {
    await _storage.write(key: _keyGymId, value: gymId);
  }

  /// Gets the last successful cloud sync timestamp.
  static Future<DateTime?> getLastSyncAt() async {
    final val = await _storage.read(key: _keyLastSyncAt);
    return val != null ? DateTime.tryParse(val) : null;
  }

  /// Records the last successful cloud sync timestamp.
  static Future<void> setLastSyncAt(DateTime time) async {
    await _storage.write(key: _keyLastSyncAt, value: time.toIso8601String());
  }
}
