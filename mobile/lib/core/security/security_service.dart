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
    await clearFailedAttempts();
  }

  Future<bool> verifyMPIN(String mpin) async {
    final salt = await _storage.read(key: _mpinSaltKey);
    final storedHash = await _storage.read(key: _mpinHashKey);

    if (salt == null || storedHash == null) return false;

    final hash = _hashMpin(mpin, salt);
    return hash == storedHash;
  }

  // --- Wrong-MPIN lockout ---------------------------------------------------
  // Stored in secure storage (not memory) so killing and reopening the app
  // doesn't reset the counter and allow unlimited guesses of a 4-digit PIN.
  static const String _failedAttemptsKey = 'mpin_failed_attempts';
  static const String _lockedUntilKey = 'mpin_locked_until';
  static const int freeAttempts = 5;

  /// Time left before MPIN entry is allowed again, or null if not locked.
  Future<Duration?> getLockRemaining() async {
    final value = await _storage.read(key: _lockedUntilKey);
    final until = value == null ? null : DateTime.tryParse(value);
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  /// Records a wrong MPIN. After [freeAttempts] failures entry is locked for
  /// 30 seconds, doubling with every further failure (max 15 minutes).
  /// Returns the lock duration, or null if the admin may simply retry.
  Future<Duration?> registerFailedAttempt() async {
    final attempts = int.parse(await _storage.read(key: _failedAttemptsKey) ?? '0') + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$attempts');
    if (attempts < freeAttempts) return null;
    final seconds = (30 * (1 << (attempts - freeAttempts).clamp(0, 5))).clamp(30, 900);
    final lock = Duration(seconds: seconds);
    await _storage.write(key: _lockedUntilKey, value: DateTime.now().add(lock).toIso8601String());
    return lock;
  }

  Future<int> remainingFreeAttempts() async {
    final attempts = int.parse(await _storage.read(key: _failedAttemptsKey) ?? '0');
    return (freeAttempts - attempts).clamp(0, freeAttempts);
  }

  Future<void> clearFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockedUntilKey);
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

