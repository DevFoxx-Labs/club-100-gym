import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  final _storage = const FlutterSecureStorage();
  static const String _mpinHashKey = 'admin_mpin_hash';
  static const String _mpinSaltKey = 'admin_mpin_salt';
  static const String _isSetupCompleteKey = 'is_setup_complete';

  Future<void> setMPIN(String mpin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hashMpin(mpin, salt);

    await _storage.write(key: _mpinSaltKey, value: salt);
    await _storage.write(key: _mpinHashKey, value: hash);
  }

  Future<bool> verifyMPIN(String mpin) async {
    final salt = await _storage.read(key: _mpinSaltKey);
    final storedHash = await _storage.read(key: _mpinHashKey);

    if (salt == null || storedHash == null) return false;

    final hash = _hashMpin(mpin, salt);
    return hash == storedHash;
  }

  Future<bool> hasMPIN() async {
    final hash = await _storage.read(key: _mpinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setSetupComplete(bool complete) async {
    await _storage.write(key: _isSetupCompleteKey, value: complete ? 'true' : 'false');
  }

  Future<bool> isSetupComplete() async {
    final val = await _storage.read(key: _isSetupCompleteKey);
    return val == 'true';
  }

  Future<void> clearSecurityData() async {
    await _storage.deleteAll();
  }

  String _hashMpin(String mpin, String salt) {
    final bytes = utf8.encode('$mpin:$salt:club100gym');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

