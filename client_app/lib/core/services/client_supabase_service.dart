import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/client_supabase_config.dart';
import '../models/client_announcement_model.dart';

class ClientSupabaseService {
  ClientSupabaseService._internal();
  static final ClientSupabaseService instance = ClientSupabaseService._internal();

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

  Future<bool> initialize({bool force = false}) async {
    if (_isInitialized && !force) return true;

    final url = await ClientSupabaseConfig.getUrl();
    final anonKey = await ClientSupabaseConfig.getAnonKey();

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      debugPrint('[ClientSupabaseService] Credentials not configured yet.');
      _isInitialized = false;
      return false;
    }

    try {
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
      debugPrint('[ClientSupabaseService] Connected to Supabase: $url');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[ClientSupabaseService] Initialization failed: $e\n$stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Fetches announcements for the gym from Supabase.
  Future<List<ClientAnnouncementModel>> fetchLiveAnnouncements() async {
    final c = client;
    if (c == null) return [];

    try {
      final gymId = await ClientSupabaseConfig.getGymId();
      var query = c.from('announcements').select();
      if (gymId != null && gymId.isNotEmpty) {
        query = query.eq('gym_id', gymId);
      }
      final response = await query.order('created_at', ascending: false);

      final List<dynamic> records = response as List<dynamic>;
      return records
          .map((r) => ClientAnnouncementModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ClientSupabaseService] fetchLiveAnnouncements error: $e');
      return [];
    }
  }

  /// Streams real-time announcements from Supabase.
  Stream<List<Map<String, dynamic>>>? streamAnnouncements() {
    final c = client;
    if (c == null) return null;

    try {
      return c.from('announcements').stream(primaryKey: ['id']).order('created_at', ascending: false);
    } catch (e) {
      debugPrint('[ClientSupabaseService] streamAnnouncements error: $e');
      return null;
    }
  }
}
