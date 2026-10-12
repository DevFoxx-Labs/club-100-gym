import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/device_code_service.dart';
import '../../core/sync/document_numbering.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/bill_model.dart';
import '../models/membership_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import 'bill_repository.dart';
import 'member_repository.dart';

class PaymentRepository {
  /// Mirrors the SQL `LEFT JOIN` used by the offline queries: attaches the
  /// receipt's memberName/planName (falling back to the member's own name)
  /// to each payment map.
  Future<List<Map<String, dynamic>>> _joinedPayments(List<Map<String, dynamic>> payments) async {
    final receipts = await MongoCollectionStore.all('receipts');
    final members = await MongoCollectionStore.all('members');
    final receiptsByPaymentId = {for (final r in receipts) r['paymentId']: r};
    final membersById = {for (final m in members) m['id']: m};

    return payments.map((p) {
      final receipt = receiptsByPaymentId[p['id']];
      final member = membersById[p['memberId']];
      final map = Map<String, dynamic>.from(p);
      map['memberName'] = receipt?['memberName'] ?? member?['name'];
      map['planName'] = receipt?['planName'];
      return map;
    }).toList();
  }

  Future<List<PaymentModel>> getPayments() async {
    if (await DataModeService.instance.isOnline) {
      final payments = await MongoCollectionStore.all('payments');
      final joined = await _joinedPayments(payments);
      final list = joined.map((map) => PaymentModel.fromMap(map)).toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, COALESCE(r.memberName, m.name) AS memberName, r.planName AS planName
      FROM payments p
      LEFT JOIN receipts r ON p.id = r.paymentId
      LEFT JOIN members m ON p.memberId = m.id
      ORDER BY p.paymentDate DESC
    ''');
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<List<PaymentModel>> getPaymentsByMember(String memberId) async {
    if (await DataModeService.instance.isOnline) {
      final payments = (await MongoCollectionStore.all('payments')).where((p) => p['memberId'] == memberId).toList();
      final joined = await _joinedPayments(payments);
      final list = joined.map((map) => PaymentModel.fromMap(map)).toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, COALESCE(r.memberName, m.name) AS memberName, r.planName AS planName
      FROM payments p
      LEFT JOIN receipts r ON p.id = r.paymentId
      LEFT JOIN members m ON p.memberId = m.id
      WHERE p.memberId = ?
      ORDER BY p.paymentDate DESC
    ''', [memberId]);
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  /// Every installment paid against [billId], oldest first.
  Future<List<PaymentModel>> getPaymentsByBill(String billId) async {
    if (await DataModeService.instance.isOnline) {
      final payments = (await MongoCollectionStore.all('payments')).where((p) => p['billId'] == billId).toList();
      final joined = await _joinedPayments(payments);
      final list = joined.map((map) => PaymentModel.fromMap(map)).toList();
      list.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
      return list;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, COALESCE(r.memberName, m.name) AS memberName, r.planName AS planName
      FROM payments p
      LEFT JOIN receipts r ON p.id = r.paymentId
      LEFT JOIN members m ON p.memberId = m.id
      WHERE p.billId = ?
      ORDER BY p.paymentDate ASC, p.createdAt ASC
    ''', [billId]);
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  /// Records a payment and everything it affects as ONE atomic unit, so a
  /// crash or error can never leave e.g. a payment saved but its bill still
  /// showing the old balance:
  /// - [newBill]: a bill raised on the spot for this cycle (a part payment
  ///   made before any bill existed), inserted first;
  /// - [updatedMembership]: the membership's new validity period;
  /// - the payment and its receipt;
  /// - [settleBillId]: the bill this payment is applied to.
  ///
  /// When settling a bill, the bill is re-read inside the transaction: the
  /// payment is rejected if the bill is no longer open or the amount exceeds
  /// what is still owed, and the returned receipt carries a snapshot of the
  /// bill total and the balance left after this payment.
  Future<ReceiptModel> recordPayment({
    required PaymentModel payment,
    required ReceiptModel receipt,
    MembershipModel? updatedMembership,
    BillModel? newBill,
    String? settleBillId,
  }) async {
    if (await DataModeService.instance.isOnline) {
      final billRepo = BillRepository();
      if (newBill != null) await billRepo.createBill(newBill);
      var finalReceipt = receipt;
      if (settleBillId != null) {
        final bill = await billRepo.getBillById(settleBillId);
        if (bill != null) {
          finalReceipt = receipt.copyWith(
            billTotal: bill.amount,
            balanceDue: _balanceAfter(bill, payment.amount),
          );
        }
      }
      if (updatedMembership != null) await MemberRepository().updateMembership(updatedMembership);
      await addPayment(payment, finalReceipt);
      if (settleBillId != null) {
        await billRepo.applyPaymentToBill(
          billId: settleBillId,
          paymentId: payment.id,
          receiptId: finalReceipt.id,
          paymentAmount: payment.amount,
        );
      }
      return finalReceipt;
    }

    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      if (newBill != null) {
        await txn.insert('bills', newBill.toMap());
      }

      var finalReceipt = receipt;
      if (settleBillId != null) {
        final rows = await txn.query('bills', where: 'id = ?', whereArgs: [settleBillId], limit: 1);
        if (rows.isEmpty) throw const PaymentRejected(PaymentRejectedReason.billNotFound);
        final bill = BillModel.fromMap(rows.first);
        if (!bill.isDue) throw const PaymentRejected(PaymentRejectedReason.billClosed);
        if (payment.amount > bill.remainingBalance + 0.01) {
          throw PaymentRejected(PaymentRejectedReason.exceedsBalance, remaining: bill.remainingBalance);
        }
        finalReceipt = receipt.copyWith(
          billTotal: bill.amount,
          balanceDue: _balanceAfter(bill, payment.amount),
        );
      }

      if (updatedMembership != null) {
        await txn.update(
          'memberships',
          updatedMembership.toMap(),
          where: 'id = ?',
          whereArgs: [updatedMembership.id],
        );
      }
      await txn.insert('payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('receipts', finalReceipt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      if (settleBillId != null) {
        await BillRepository.applyPaymentInTxn(
          txn,
          billId: settleBillId,
          paymentId: payment.id,
          receiptId: finalReceipt.id,
          amount: payment.amount,
        );
      }
      return finalReceipt;
    });
  }

  static double _balanceAfter(BillModel bill, double paymentAmount) {
    final left = bill.amount - bill.paidAmount - paymentAmount;
    return left < 0.01 ? 0.0 : double.parse(left.toStringAsFixed(2));
  }

  Future<List<PaymentModel>> getRecentPayments({int limit = 5}) async {
    if (await DataModeService.instance.isOnline) {
      final payments = await MongoCollectionStore.all('payments');
      final joined = await _joinedPayments(payments);
      final list = joined.map((map) => PaymentModel.fromMap(map)).toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list.take(limit).toList();
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, COALESCE(r.memberName, m.name) AS memberName, r.planName AS planName
      FROM payments p
      LEFT JOIN receipts r ON p.id = r.paymentId
      LEFT JOIN members m ON p.memberId = m.id
      ORDER BY p.paymentDate DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  /// Next receipt number in this phone's series, e.g. `GYM-2026-A00012`
  /// (see [DocumentNumbering] for why every phone has its own series).
  Future<String> generateNextReceiptNumber() async {
    final prefix = 'GYM-${DateTime.now().year}-';
    final code = await DeviceCodeService.instance.currentCode();
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'receipts',
      columns: ['receiptNumber'],
      where: 'receiptNumber LIKE ?',
      whereArgs: ['$prefix${code ?? ''}%'],
    );
    return DocumentNumbering.next(
      prefix: prefix,
      deviceCode: code,
      existing: rows.map((r) => r['receiptNumber'] as String),
    );
  }

  Future<void> addPayment(PaymentModel payment, ReceiptModel receipt) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('payments', 'id', payment.toMap());
      await MongoCollectionStore.upsert('receipts', 'id', receipt.toMap());
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert('payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('receipts', receipt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<ReceiptModel?> getReceiptByPaymentId(String paymentId) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('receipts');
      for (final doc in docs) {
        if (doc['paymentId'] == paymentId) return ReceiptModel.fromMap(doc);
      }
      return null;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
    if (maps.isNotEmpty) {
      return ReceiptModel.fromMap(maps.first);
    }
    return null;
  }

  Future<ReceiptModel?> getReceiptByNumber(String receiptNumber) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('receipts');
      for (final doc in docs) {
        if (doc['receiptNumber'] == receiptNumber) return ReceiptModel.fromMap(doc);
      }
      return null;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'receiptNumber = ?',
      whereArgs: [receiptNumber],
    );
    if (maps.isNotEmpty) {
      return ReceiptModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deletePayment(String paymentId) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteById('payments', paymentId);
      await MongoCollectionStore.deleteWhere('receipts', (map) => map['paymentId'] == paymentId);
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    await db.delete('receipts', where: 'paymentId = ?', whereArgs: [paymentId]);
  }

  Future<double> getTotalPaidForMembership(String membershipId) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('payments');
      var total = 0.0;
      for (final doc in docs) {
        if (doc['membershipId'] == membershipId) {
          total += (doc['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    }
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM payments WHERE membershipId = ?',
      [membershipId],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}

enum PaymentRejectedReason { billNotFound, billClosed, exceedsBalance }

/// Thrown by [PaymentRepository.recordPayment] when the bill changed since
/// the payment screen was opened (e.g. already settled from another phone).
class PaymentRejected implements Exception {
  final PaymentRejectedReason reason;
  final double? remaining;

  const PaymentRejected(this.reason, {this.remaining});

  @override
  String toString() => 'PaymentRejected($reason, remaining: $remaining)';
}
