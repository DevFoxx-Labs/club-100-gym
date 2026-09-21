import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';

class PaymentRepository {
  Future<List<PaymentModel>> getPayments() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      orderBy: 'paymentDate DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<List<PaymentModel>> getPaymentsByMember(String memberId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'paymentDate DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<List<PaymentModel>> getRecentPayments({int limit = 5}) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      orderBy: 'paymentDate DESC',
      limit: limit,
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<String> generateNextReceiptNumber() async {
    final db = await AppDatabase.instance.database;
    final year = DateTime.now().year;
    final prefix = 'GYM-$year-';

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT receiptNumber FROM receipts WHERE receiptNumber LIKE '$prefix%' ORDER BY receiptNumber DESC LIMIT 1"
    );

    if (result.isNotEmpty) {
      final lastNoStr = result.first['receiptNumber'] as String;
      final numPart = int.tryParse(lastNoStr.replaceAll(prefix, '')) ?? 0;
      final nextNum = numPart + 1;
      return '$prefix${nextNum.toString().padLeft(5, '0')}';
    } else {
      return '${prefix}00001';
    }
  }

  Future<void> addPayment(PaymentModel payment, ReceiptModel receipt) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert('payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('receipts', receipt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<ReceiptModel?> getReceiptByPaymentId(String paymentId) async {
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
    final db = await AppDatabase.instance.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    await db.delete('receipts', where: 'paymentId = ?', whereArgs: [paymentId]);
  }
}

