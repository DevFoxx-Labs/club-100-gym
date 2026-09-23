import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/bill_model.dart';

class BillRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  /// Builds the dedupe key used to guarantee only one bill is ever raised
  /// for a given membership renewal cycle (one per due date).
  static String cycleKeyFor(String membershipId, DateTime dueDate) {
    final d = DateFormat('yyyy-MM-dd').format(dueDate);
    return '$membershipId|$d';
  }

  Future<String> generateNextBillNumber() async {
    final db = await _db;
    final year = DateTime.now().year;
    final prefix = 'BILL-$year-';

    final result = await db.rawQuery(
      "SELECT billNumber FROM bills WHERE billNumber LIKE '$prefix%' ORDER BY billNumber DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      final lastNoStr = result.first['billNumber'] as String;
      final numPart = int.tryParse(lastNoStr.replaceAll(prefix, '')) ?? 0;
      final nextNum = numPart + 1;
      return '$prefix${nextNum.toString().padLeft(5, '0')}';
    }
    return '${prefix}00001';
  }

  Future<void> createBill(BillModel bill) async {
    final db = await _db;
    await db.insert('bills', bill.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BillModel>> getBills({String? status}) async {
    final db = await _db;
    final maps = await db.query(
      'bills',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'dueDate DESC',
    );
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  Future<List<BillModel>> getDueBills() async {
    final db = await _db;
    final maps = await db.query(
      'bills',
      where: 'status IN (?, ?)',
      whereArgs: ['Pending', 'Overdue'],
      orderBy: 'dueDate ASC',
    );
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  Future<List<BillModel>> getBillsByMember(String memberId) async {
    final db = await _db;
    final maps = await db.query(
      'bills',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'dueDate DESC',
    );
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  Future<BillModel?> getBillById(String id) async {
    final db = await _db;
    final maps = await db.query('bills', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return BillModel.fromMap(maps.first);
  }

  Future<bool> billExistsForCycle(String membershipId, DateTime dueDate) async {
    final db = await _db;
    final key = cycleKeyFor(membershipId, dueDate);
    final maps = await db.query('bills', where: 'cycleKey = ?', whereArgs: [key], limit: 1);
    return maps.isNotEmpty;
  }

  /// Finds the oldest outstanding (Pending/Overdue) bill tied to a membership,
  /// used to auto-settle the right bill when a payment is recorded against it.
  Future<BillModel?> getOldestDueBillForMembership(String membershipId) async {
    final db = await _db;
    final maps = await db.query(
      'bills',
      where: 'membershipId = ? AND status IN (?, ?)',
      whereArgs: [membershipId, 'Pending', 'Overdue'],
      orderBy: 'dueDate ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BillModel.fromMap(maps.first);
  }

  Future<void> markBillPaid({
    required String billId,
    required String paymentId,
    required String receiptId,
  }) async {
    final db = await _db;
    await db.update(
      'bills',
      {
        'status': 'Paid',
        'paymentId': paymentId,
        'receiptId': receiptId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  Future<void> cancelBill(String billId) async {
    final db = await _db;
    await db.update(
      'bills',
      {'status': 'Cancelled', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  /// Marks any Pending bill whose due date has passed as Overdue. Called during
  /// the daily reminder/billing scan so bill status always reflects reality.
  Future<void> refreshOverdueStatuses({DateTime? referenceDate}) async {
    final db = await _db;
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    await db.update(
      'bills',
      {'status': 'Overdue', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'status = ? AND dueDate < ?',
      whereArgs: ['Pending', today],
    );
  }

  /// Permanently deletes a bill. Restricted to Cancelled bills so Paid/Pending/Overdue
  /// bills — which represent real dues or payment history — can never be erased.
  Future<void> deleteCancelledBill(String billId) async {
    final db = await _db;
    await db.delete(
      'bills',
      where: 'id = ? AND status = ?',
      whereArgs: [billId, 'Cancelled'],
    );
  }

  Future<double> getTotalDueAmount() async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT SUM(amount) AS total FROM bills WHERE status IN ('Pending', 'Overdue')",
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}
