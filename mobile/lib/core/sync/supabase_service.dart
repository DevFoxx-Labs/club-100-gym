import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Initializes Supabase once at startup. Returns false (non-fatal) when the
  /// build has no Supabase keys, so the app keeps working fully offline.
  Future<bool> init() async {
    if (_isInitialized) return true;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] SUPABASE_URL / SUPABASE_ANON_KEY not provided; cloud sync disabled.');
      return false;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[SupabaseService] Initialization failed: $e\n$stackTrace');
      return false;
    }
  }
}
