import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

/// Gives this phone a short code ('A', 'B', …) that is unique among all the
/// phones using the same gym, so bill/receipt numbers created offline on two
/// phones can never collide (see [DocumentNumbering]).
///
/// The code is assigned by the server (`register_device` RPC) the first time
/// this phone is bound to a gym and cached in secure storage. If the phone has
/// never been online since binding, a provisional code derived from this
/// install's random id ('X' + 3 hex chars) is used instead — distinct from
/// every server code, and practically unique per phone.
class DeviceCodeService {
  DeviceCodeService._internal();
  static final DeviceCodeService instance = DeviceCodeService._internal();

  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'sync_device_id';
  static String _codeKey(String gymId) => 'sync_device_code:$gymId';

  /// Random id of this install, generated once.
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  /// Asks the server for this phone's code in [gymId] (assigning one on first
  /// call) and caches it. Returns null when offline / not signed in.
  Future<String?> ensureRegistered(String gymId) async {
    final cached = await _storage.read(key: _codeKey(gymId));
    if (cached != null && cached.isNotEmpty) return cached;
    final client = SupabaseService.instance.client;
    if (client == null || client.auth.currentUser == null) return null;
    try {
      // Short timeout: this runs while saving a payment, which must never hang
      // on a bad connection — the provisional code is used instead.
      final code = await client
          .rpc('register_device', params: {'p_gym_id': gymId, 'p_device_id': await deviceId()})
          .timeout(const Duration(seconds: 4)) as String?;
      if (code == null || code.isEmpty) return null;
      await _storage.write(key: _codeKey(gymId), value: code);
      return code;
    } catch (e) {
      debugPrint('[DeviceCodeService] register_device failed: $e');
      return null;
    }
  }

  /// The code to put in new bill/receipt numbers, or null for installs that
  /// are not linked to a cloud gym (legacy code-less numbering).
  Future<String?> currentCode() async {
    final gymId = await SupabaseConfig.getActiveGymId();
    if (gymId == null) return null;
    final code = await ensureRegistered(gymId);
    if (code != null) return code;
    final id = (await deviceId()).replaceAll('-', '');
    return 'X${id.substring(0, 3).toUpperCase()}';
  }
}
