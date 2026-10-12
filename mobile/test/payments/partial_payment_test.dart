import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_elite_fitness/core/database/app_database.dart';
import 'package:the_elite_fitness/data/models/bill_model.dart';
import 'package:the_elite_fitness/data/models/membership_model.dart';
import 'package:the_elite_fitness/data/models/payment_model.dart';
import 'package:the_elite_fitness/data/models/receipt_model.dart';
import 'package:the_elite_fitness/data/repositories/bill_repository.dart';
import 'package:the_elite_fitness/data/repositories/payment_repository.dart';

final _now = DateTime(2026, 10, 1);

BillModel _bill({String id = 'bill-1', double amount = 2000, String status = 'Pending', double paid = 0}) => BillModel(
      id: id,
      billNumber: 'BILL-2026-$id',
      memberId: 'member-1',
      memberName: 'Rahul',
      memberPhone: '+919999999999',
      membershipId: 'ms-1',
      planName: 'Monthly',
      amount: amount,
      billDate: _now,
      dueDate: _now,
      status: status,
      paidAmount: paid,
      cycleKey: 'ms-1|$id',
      createdAt: _now,
      updatedAt: _now,
    );

MembershipModel _membership() => MembershipModel(
      id: 'ms-1',
      memberId: 'member-1',
      planId: 'plan-1',
      planName: 'Monthly',
      trainerId: 'trainer-1',
      personalTrainingFee: 500,
      startDate: _now,
      endDate: _now.add(const Duration(days: 30)),
      feeAmount: 2000,
      status: 'Active',
      createdAt: _now,
      updatedAt: _now,
    );

int _seq = 0;

({PaymentModel payment, ReceiptModel receipt}) _payment(double amount, {String? billId}) {
  _seq++;
  final payment = PaymentModel(
    id: 'pay-$_seq',
    memberId: 'member-1',
    membershipId: 'ms-1',
    billId: billId,
    amount: amount,
    paymentDate: _now,
    paymentMethod: 'Cash',
    receiptId: 'rec-$_seq',
    receiptNumber: 'GYM-2026-0000$_seq',
    createdAt: _now,
    updatedAt: _now,
  );
  final receipt = ReceiptModel(
    id: 'rec-$_seq',
    paymentId: 'pay-$_seq',
    receiptNumber: 'GYM-2026-0000$_seq',
    memberName: 'Rahul',
    memberPhone: '+919999999999',
    planName: 'Monthly',
    amount: amount,
    paymentMethod: 'Cash',
    paymentDate: _now,
    startDate: _now,
    endDate: _now.add(const Duration(days: 30)),
    qrPayload: 'qr',
    createdAt: _now,
  );
  return (payment: payment, receipt: receipt);
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BillModel display helpers', () {
    test('settled bill shows its amount, never ₹0', () {
      final bill = _bill(status: 'Paid', paid: 2000);
      expect(bill.remainingBalance, 0);
      expect(bill.displayAmount, 2000);
    });

    test('part-paid bill shows the remaining balance', () {
      expect(_bill(status: 'Partially Paid', paid: 500).displayAmount, 1500);
    });

    test('money keeps paise only when present', () {
      expect(BillModel.money(1500), '₹1500');
      expect(BillModel.money(333.33), '₹333.33');
    });
  });

  group('ReceiptModel installment snapshot', () {
    test('round-trips billTotal / balanceDue and flags installments', () {
      final receipt = _payment(1000).receipt.copyWith(billTotal: 2000, balanceDue: 1000);
      final restored = ReceiptModel.fromMap(receipt.toMap());
      expect(restored.billTotal, 2000);
      expect(restored.balanceDue, 1000);
      expect(restored.isInstallment, isTrue);
      expect(restored.leavesBalance, isTrue);
    });

    test('older receipts without the snapshot are not installments', () {
      final map = _payment(2000).receipt.toMap()
        ..remove('billTotal')
        ..remove('balanceDue');
      final restored = ReceiptModel.fromMap(map);
      expect(restored.isInstallment, isFalse);
      expect(restored.leavesBalance, isFalse);
    });
  });

  group('PaymentRepository.recordPayment (SQLite)', () {
    late Database db;
    final repo = PaymentRepository();

    setUp(() async {
      await AppDatabase.instance.close().catchError((_) {});
      await databaseFactoryFfi.deleteDatabase(p.join(await getDatabasesPath(), 'club_100_gym.db'));
      db = await AppDatabase.instance.database;
      await db.insert('memberships', _membership().toMap());
    });

    tearDownAll(() async {
      await AppDatabase.instance.close();
    });

    Future<BillModel> reloadBill(String id) async =>
        BillModel.fromMap((await db.query('bills', where: 'id = ?', whereArgs: [id])).first);

    test('two installments: Partially Paid, then Paid, with balance snapshots', () async {
      await db.insert('bills', _bill().toMap());

      final first = _payment(1200, billId: 'bill-1');
      final r1 = await repo.recordPayment(payment: first.payment, receipt: first.receipt, settleBillId: 'bill-1');
      var bill = await reloadBill('bill-1');
      expect(bill.status, 'Partially Paid');
      expect(bill.paidAmount, 1200);
      expect(r1.billTotal, 2000);
      expect(r1.balanceDue, 800);

      final second = _payment(800, billId: 'bill-1');
      final r2 = await repo.recordPayment(payment: second.payment, receipt: second.receipt, settleBillId: 'bill-1');
      bill = await reloadBill('bill-1');
      expect(bill.status, 'Paid');
      expect(bill.remainingBalance, 0);
      expect(r2.balanceDue, 0);
      expect(r2.leavesBalance, isFalse);

      final installments = await repo.getPaymentsByBill('bill-1');
      expect(installments.map((p) => p.amount), [1200, 800]);
    });

    test('paise balances close exactly (333.33 + 333.33 + 333.34)', () async {
      await db.insert('bills', _bill(amount: 1000).toMap());
      for (final amount in [333.33, 333.33, 333.34]) {
        final pay = _payment(amount, billId: 'bill-1');
        await repo.recordPayment(payment: pay.payment, receipt: pay.receipt, settleBillId: 'bill-1');
      }
      expect((await reloadBill('bill-1')).status, 'Paid');
    });

    test('an Overdue bill becomes Partially Paid after an installment', () async {
      await db.insert('bills', _bill(status: 'Overdue').toMap());
      final pay = _payment(500, billId: 'bill-1');
      await repo.recordPayment(payment: pay.payment, receipt: pay.receipt, settleBillId: 'bill-1');
      expect((await reloadBill('bill-1')).status, 'Partially Paid');
    });

    test('rejects paying more than the balance and saves nothing', () async {
      await db.insert('bills', _bill(status: 'Partially Paid', paid: 1500).toMap());
      final pay = _payment(800, billId: 'bill-1');

      await expectLater(
        repo.recordPayment(payment: pay.payment, receipt: pay.receipt, settleBillId: 'bill-1'),
        throwsA(isA<PaymentRejected>()
            .having((e) => e.reason, 'reason', PaymentRejectedReason.exceedsBalance)
            .having((e) => e.remaining, 'remaining', 500)),
      );
      expect(await db.query('payments'), isEmpty);
      expect(await db.query('receipts'), isEmpty);
      expect((await reloadBill('bill-1')).paidAmount, 1500);
    });

    test('rejects payments on a settled or cancelled bill', () async {
      await db.insert('bills', _bill(status: 'Cancelled').toMap());
      final pay = _payment(100, billId: 'bill-1');
      await expectLater(
        repo.recordPayment(payment: pay.payment, receipt: pay.receipt, settleBillId: 'bill-1'),
        throwsA(isA<PaymentRejected>().having((e) => e.reason, 'reason', PaymentRejectedReason.billClosed)),
      );
    });

    test('part payment with no bill yet creates the bill in the same transaction', () async {
      final newBill = _bill(id: 'new-bill');
      final pay = _payment(700, billId: 'new-bill');
      final receipt = await repo.recordPayment(
        payment: pay.payment,
        receipt: pay.receipt,
        newBill: newBill,
        settleBillId: 'new-bill',
      );
      final bill = await reloadBill('new-bill');
      expect(bill.status, 'Partially Paid');
      expect(bill.remainingBalance, 1300);
      expect(receipt.balanceDue, 1300);
      expect(await BillRepository().getOutstandingForMembership('ms-1'), 1300);
    });

    test('membership keeps its full PT fee after a part payment', () async {
      await db.insert('bills', _bill().toMap());
      final pay = _payment(300, billId: 'bill-1');
      await repo.recordPayment(
        payment: pay.payment,
        receipt: pay.receipt,
        updatedMembership: _membership().copyWith(updatedAt: _now.add(const Duration(minutes: 1))),
        settleBillId: 'bill-1',
      );
      final row = (await db.query('memberships', where: 'id = ?', whereArgs: ['ms-1'])).first;
      expect(row['personalTrainingFee'], 500);
      expect(row['feeAmount'], 2000);
    });

    test('outstanding is null for memberships that have no bills at all', () async {
      expect(await BillRepository().getOutstandingForMembership('ms-1'), isNull);
    });

    test('every write is queued for cloud sync', () async {
      await db.insert('bills', _bill().toMap());
      await db.delete('sync_outbox');
      final pay = _payment(1000, billId: 'bill-1');
      await repo.recordPayment(payment: pay.payment, receipt: pay.receipt, settleBillId: 'bill-1');
      final queued = (await db.query('sync_outbox')).map((r) => r['tableName']).toSet();
      expect(queued, containsAll(['payments', 'receipts', 'bills']));
    });
  });
}
