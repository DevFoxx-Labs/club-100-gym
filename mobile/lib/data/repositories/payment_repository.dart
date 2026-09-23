import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';

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

  Future<String> generateNextReceiptNumber() async {
    final year = DateTime.now().year;
    final prefix = 'GYM-$year-';

    if (await DataModeService.instance.isOnline) {
      final receipts = await MongoCollectionStore.all('receipts');
      final matching = receipts
          .map((r) => r['receiptNumber'] as String?)
          .whereType<String>()
          .where((no) => no.startsWith(prefix))
          .toList();
      if (matching.isEmpty) return '${prefix}00001';
      matching.sort();
      final lastNoStr = matching.last;
      final numPart = int.tryParse(lastNoStr.replaceAll(prefix, '')) ?? 0;
      final nextNum = numPart + 1;
      return '$prefix${nextNum.toString().padLeft(5, '0')}';
    }

    final db = await AppDatabase.instance.database;
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
