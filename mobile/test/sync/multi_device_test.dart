import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_elite_fitness/core/database/app_database.dart';
import 'package:the_elite_fitness/core/sync/device_code_service.dart';
import 'package:the_elite_fitness/core/sync/document_numbering.dart';
import 'package:the_elite_fitness/core/sync/sync_engine.dart';
import 'package:the_elite_fitness/data/models/bill_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentNumbering', () {
    test('legacy installs (no code) keep the old format', () {
      expect(
        DocumentNumbering.next(prefix: 'GYM-2026-', deviceCode: null, existing: ['GYM-2026-00011', 'GYM-2026-00009']),
        'GYM-2026-00012',
      );
    });

    test('each phone counts only its own series', () {
      final existing = ['GYM-2026-00050', 'GYM-2026-A00007', 'GYM-2026-B00031', 'GYM-2026-AB00099'];
      expect(DocumentNumbering.next(prefix: 'GYM-2026-', deviceCode: 'A', existing: existing), 'GYM-2026-A00008');
      expect(DocumentNumbering.next(prefix: 'GYM-2026-', deviceCode: 'B', existing: existing), 'GYM-2026-B00032');
      expect(DocumentNumbering.next(prefix: 'GYM-2026-', deviceCode: 'C', existing: existing), 'GYM-2026-C00001');
    });

    test('coded numbers never disturb the legacy series (and vice versa)', () {
      // Old code compared strings, so 'GYM-2026-A00012' sorted after the
      // legacy numbers, failed to parse and restarted the series at 00001.
      final existing = ['GYM-2026-00041', 'GYM-2026-A00012'];
      expect(DocumentNumbering.next(prefix: 'GYM-2026-', deviceCode: null, existing: existing), 'GYM-2026-00042');
    });

    test('two phones offline produce different numbers', () {
      final a = DocumentNumbering.next(prefix: 'BILL-2026-', deviceCode: 'A', existing: const []);
      final b = DocumentNumbering.next(prefix: 'BILL-2026-', deviceCode: 'B', existing: const []);
      expect(a, isNot(b));
    });
  });

  group('DeviceCodeService', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('no code for installs not linked to a cloud gym', () async {
      expect(await DeviceCodeService.instance.currentCode(), isNull);
    });

    test('uses the cached server code for the active gym', () async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_active_gym_id': 'gym-1',
        'sync_device_code:gym-1': 'B',
      });
      expect(await DeviceCodeService.instance.currentCode(), 'B');
    });

    test('offline before registration: stable provisional code, distinct from server codes', () async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_active_gym_id': 'gym-1',
        'sync_device_id': 'abc12345-0000-0000-0000-000000000000',
      });
      final code = await DeviceCodeService.instance.currentCode();
      expect(code, 'XABC');
      expect(await DeviceCodeService.instance.currentCode(), code);
    });
  });

  group('SyncEngine.reconcileBillTotals', () {
    late Database db;
    final now = DateTime(2026, 10, 1);

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      // Own folder: test files run in parallel and must not share the DB file.
      await databaseFactory.setDatabasesPath((await Directory.systemTemp.createTemp('multi_device_test')).path);
    });

    setUp(() async {
      await AppDatabase.instance.close().catchError((_) {});
      await databaseFactoryFfi.deleteDatabase(p.join(await getDatabasesPath(), 'club_100_gym.db'));
      db = await AppDatabase.instance.database;
    });

    tearDownAll(() async => AppDatabase.instance.close());

    Future<void> insertBill(String id, {double paid = 0, String status = 'Pending'}) => db.insert(
          'bills',
          BillModel(
            id: id,
            billNumber: 'BILL-$id',
            memberId: 'm1',
            memberName: 'Rahul',
            memberPhone: '1',
            planName: 'Monthly',
            amount: 2000,
            billDate: now,
            dueDate: now,
            status: status,
            paidAmount: paid,
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );

    Future<void> insertPayment(String id, String billId, double amount) => db.insert('payments', {
          'id': id,
          'memberId': 'm1',
          'billId': billId,
          'amount': amount,
          'paymentDate': now.toIso8601String(),
          'paymentMethod': 'Cash',
          'receiptId': 'r-$id',
          'receiptNumber': 'GYM-$id',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

    Future<BillModel> bill(String id) async =>
        BillModel.fromMap((await db.query('bills', where: 'id = ?', whereArgs: [id])).first);

    test('installments from two phones add up instead of last-write-wins', () async {
      // Phone A paid 500 and pushed paidAmount 500; phone B paid 500 offline and
      // pushed paidAmount 500 too. After pulling both payments the bill is fixed.
      await insertBill('b1', paid: 500, status: 'Partially Paid');
      await insertPayment('p1', 'b1', 500);
      await insertPayment('p2', 'b1', 500);
      await db.delete('sync_outbox');

      expect(await SyncEngine.reconcileBillTotals(db, {'b1'}), 1);
      final b = await bill('b1');
      expect(b.paidAmount, 1000);
      expect(b.status, 'Partially Paid');
      expect(b.remainingBalance, 1000);

      // The correction is queued for upload so every phone converges.
      final queued = await db.query('sync_outbox', where: "tableName = 'bills'");
      expect(queued, isNotEmpty);
    });

    test('becomes Paid when the installments cover the bill; overpayment is kept', () async {
      await insertBill('b2', paid: 2000, status: 'Paid');
      await insertPayment('p3', 'b2', 2000);
      await insertPayment('p4', 'b2', 2000);
      await SyncEngine.reconcileBillTotals(db, {'b2'});
      final b = await bill('b2');
      expect(b.status, 'Paid');
      expect(b.paidAmount, 4000);
    });

    test('no change when already correct (no endless push/pull loop)', () async {
      await insertBill('b3', paid: 700, status: 'Partially Paid');
      await insertPayment('p5', 'b3', 700);
      expect(await SyncEngine.reconcileBillTotals(db, {'b3'}), 0);
    });

    test('legacy paid bills without linked payments are left alone', () async {
      await insertBill('b4', paid: 2000, status: 'Paid');
      expect(await SyncEngine.reconcileBillTotals(db, {'b4'}), 0);
      expect((await bill('b4')).status, 'Paid');
    });

    test('cancelled bills keep their status', () async {
      await insertBill('b5', status: 'Cancelled');
      await insertPayment('p6', 'b5', 300);
      await SyncEngine.reconcileBillTotals(db, {'b5'});
      expect((await bill('b5')).status, 'Cancelled');
    });
  });
}
