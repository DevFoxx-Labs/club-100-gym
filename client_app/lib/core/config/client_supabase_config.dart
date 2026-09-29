import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Supabase Configuration for Client App.
class ClientSupabaseConfig {
  /// Default Supabase Project URL (can be edited here or in-app).
  static const String defaultUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Default Supabase Anon Public API Key.
  static const String defaultAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String _keyUrl = 'client_supabase_url';
  static const String _keyAnonKey = 'client_supabase_anon_key';
  static const String _keyGymId = 'client_supabase_gym_id';

  /// Returns the configured URL from SharedPreferences, falling back to [defaultUrl] if valid.
  static Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_keyUrl);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    if (defaultUrl.isNotEmpty && !defaultUrl.contains('YOUR_PROJECT_ID')) {
      return defaultUrl;
    }
    return null;
  }

  /// Returns the configured Anon Key from SharedPreferences, falling back to [defaultAnonKey] if valid.
  static Future<String?> getAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(_keyAnonKey);
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
  static Future<void> saveCredentials({required String url, required String anonKey, String? gymId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url.trim());
    await prefs.setString(_keyAnonKey, anonKey.trim());
    if (gymId != null && gymId.trim().isNotEmpty) {
      await prefs.setString(_keyGymId, gymId.trim());
    }
  }

  /// Returns the bound gym UUID, if specified.
  static Future<String?> getGymId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGymId);
  }

  /// Clears stored credentials.
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyAnonKey);
    await prefs.remove(_keyGymId);
  }
}
