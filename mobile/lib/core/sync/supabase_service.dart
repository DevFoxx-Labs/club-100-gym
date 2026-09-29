import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes the Supabase client with credentials from [SupabaseConfig].
  Future<bool> init({bool force = false}) async {
    if (_isInitialized && !force) return true;

    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      debugPrint('[SupabaseService] Credentials not configured yet.');
      _isInitialized = false;
      return false;
    }

    try {
      // If already initialized, we may need to re-initialize or check instance
      try {
        final existingClient = Supabase.instance.client;
        if (existingClient.rest.url.toString().contains(Uri.parse(url).host)) {
          _isInitialized = true;
          return true;
        }
      } catch (_) {}

      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      debugPrint('[SupabaseService] Successfully connected to $url');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[SupabaseService] Initialization failed: $e\n$stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Pings Supabase to verify connectivity.
  Future<({bool success, String? error})> testConnection({String? customUrl, String? customAnonKey}) async {
    final url = customUrl ?? await SupabaseConfig.getUrl();
    final anonKey = customAnonKey ?? await SupabaseConfig.getAnonKey();

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      return (success: false, error: 'Supabase URL and Anon Key are required.');
    }

    try {
      // Use temporary client to test without disturbing the global singleton if custom
      final testClient = SupabaseClient(url, anonKey);
      await testClient.from('gyms').select('id').limit(1);
      return (success: true, error: null);
    } catch (e) {
      // If table 'gyms' doesn't exist yet, but connection was reached, we still consider auth valid
      final errorStr = e.toString();
      if (errorStr.contains('relation "gyms" does not exist') || errorStr.contains('PGRST204') || errorStr.contains('404')) {
        return (success: true, error: 'Connected to Supabase! (Database tables need to be created with SQL schema)');
      }
      return (success: false, error: errorStr);
    }
  }
}
