import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
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
    final year = DateTime.now().year;
    final prefix = 'BILL-$year-';

    if (await DataModeService.instance.isOnline) {
      final bills = await MongoCollectionStore.all('bills');
      final matching = bills
          .map((b) => b['billNumber'] as String?)
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

    final db = await _db;
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
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('bills', 'id', bill.toMap());
      return;
    }
    final db = await _db;
    await db.insert('bills', bill.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BillModel>> getBills({String? status}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      final filtered = docs.where((m) => status == null || m['status'] == status).map((m) => BillModel.fromMap(m)).toList();
      filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      final filtered = docs.where((m) => m['status'] == 'Pending' || m['status'] == 'Overdue').map((m) => BillModel.fromMap(m)).toList();
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      final filtered = docs.where((m) => m['memberId'] == memberId).map((m) => BillModel.fromMap(m)).toList();
      filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('bills', id);
      return doc == null ? null : BillModel.fromMap(doc);
    }
    final db = await _db;
    final maps = await db.query('bills', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return BillModel.fromMap(maps.first);
  }

  Future<bool> billExistsForCycle(String membershipId, DateTime dueDate) async {
    final key = cycleKeyFor(membershipId, dueDate);
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      return docs.any((m) => m['cycleKey'] == key);
    }
    final db = await _db;
    final maps = await db.query('bills', where: 'cycleKey = ?', whereArgs: [key], limit: 1);
    return maps.isNotEmpty;
  }

  /// Finds the oldest outstanding (Pending/Overdue) bill tied to a membership,
  /// used to auto-settle the right bill when a payment is recorded against it.
  Future<BillModel?> getOldestDueBillForMembership(String membershipId) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      final filtered = docs
          .where((m) => m['membershipId'] == membershipId && (m['status'] == 'Pending' || m['status'] == 'Overdue'))
          .map((m) => BillModel.fromMap(m))
          .toList();
      if (filtered.isEmpty) return null;
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return filtered.first;
    }
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
    final fields = {
      'status': 'Paid',
      'paymentId': paymentId,
      'receiptId': receiptId,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('bills', billId, fields);
      return;
    }
    final db = await _db;
    await db.update('bills', fields, where: 'id = ?', whereArgs: [billId]);
  }

  Future<void> cancelBill(String billId) async {
    final fields = {'status': 'Cancelled', 'updatedAt': DateTime.now().toIso8601String()};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('bills', billId, fields);
      return;
    }
    final db = await _db;
    await db.update('bills', fields, where: 'id = ?', whereArgs: [billId]);
  }

  /// Marks any Pending bill whose due date has passed as Overdue. Called during
  /// the daily reminder/billing scan so bill status always reflects reality.
  Future<void> refreshOverdueStatuses({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fields = {'status': 'Overdue', 'updatedAt': DateTime.now().toIso8601String()};

    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateWhere(
        'bills',
        (m) {
          if (m['status'] != 'Pending') return false;
          final dueDate = DateTime.tryParse(m['dueDate'] as String? ?? '');
          return dueDate != null && dueDate.isBefore(today);
        },
        fields,
      );
      return;
    }

    final db = await _db;
    await db.update(
      'bills',
      fields,
      where: 'status = ? AND dueDate < ?',
      whereArgs: ['Pending', today.toIso8601String()],
    );
  }

  /// Permanently deletes a bill. Restricted to Cancelled bills so Paid/Pending/Overdue
  /// bills — which represent real dues or payment history — can never be erased.
  Future<void> deleteCancelledBill(String billId) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteWhere('bills', (m) => m['id'] == billId && m['status'] == 'Cancelled');
      return;
    }
    final db = await _db;
    await db.delete(
      'bills',
      where: 'id = ? AND status = ?',
      whereArgs: [billId, 'Cancelled'],
    );
  }

  /// Cancels a stale (Pending/Overdue) bill left over from a member's absence
  /// and raises a fresh replacement bill dated [resumeDate] (defaults to today).
  /// Used by the "Resume From Today" shortcut so billing restarts from the
  /// member's actual return date instead of the old, lapsed cycle date. This
  /// is purely a convenience wrapper around the existing cancelBill + createBill
  /// flow — the manual Cancel Bill / Generate Bill screens keep working as-is.
  Future<BillModel> resumeBillFromToday(BillModel staleBill, {DateTime? resumeDate}) async {
    await cancelBill(staleBill.id);

    final now = DateTime.now();
    final dueDate = resumeDate ?? now;
    final newBill = BillModel(
      id: const Uuid().v4(),
      billNumber: await generateNextBillNumber(),
      memberId: staleBill.memberId,
      memberName: staleBill.memberName,
      memberPhone: staleBill.memberPhone,
      membershipId: staleBill.membershipId,
      planName: staleBill.planName,
      amount: staleBill.amount,
      billDate: now,
      dueDate: dueDate,
      status: 'Pending',
      notes: 'Resumed after a gap — replaces cancelled bill ${staleBill.billNumber}',
      isAutoGenerated: false,
      cycleKey: staleBill.membershipId != null ? cycleKeyFor(staleBill.membershipId!, dueDate) : null,
      createdAt: now,
      updatedAt: now,
    );
    await createBill(newBill);
    return newBill;
  }

  Future<double> getTotalDueAmount() async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('bills');
      var total = 0.0;
      for (final doc in docs) {
        if (doc['status'] == 'Pending' || doc['status'] == 'Overdue') {
          total += (doc['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    }
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
