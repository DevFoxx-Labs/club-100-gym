import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/core/security/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('first wrong attempts only count down, then entry locks for 30s', () async {
    final security = SecurityService();
    for (var i = 1; i < SecurityService.freeAttempts; i++) {
      expect(await security.registerFailedAttempt(), isNull);
      expect(await security.remainingFreeAttempts(), SecurityService.freeAttempts - i);
    }
    final lock = await security.registerFailedAttempt();
    expect(lock, const Duration(seconds: 30));
    expect(await security.getLockRemaining(), isNotNull);
  });

  test('lock doubles with every further failure, capped at 15 minutes', () async {
    final security = SecurityService();
    final locks = <Duration?>[];
    for (var i = 0; i < SecurityService.freeAttempts + 8; i++) {
      locks.add(await security.registerFailedAttempt());
    }
    final applied = locks.whereType<Duration>().map((d) => d.inSeconds).toList();
    expect(applied.take(4), [30, 60, 120, 240]);
    expect(applied.last, 900);
  });

  test('setting a new MPIN (forgot-MPIN reset) clears the lock', () async {
    final security = SecurityService();
    for (var i = 0; i < SecurityService.freeAttempts; i++) {
      await security.registerFailedAttempt();
    }
    await security.setMPIN('4321');
    expect(await security.getLockRemaining(), isNull);
    expect(await security.remainingFreeAttempts(), SecurityService.freeAttempts);
    expect(await security.verifyMPIN('4321'), isTrue);
  });
}
