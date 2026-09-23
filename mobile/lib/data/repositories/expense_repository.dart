import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/expense_model.dart';
import '../../core/services/app_state_service.dart';

class ExpenseRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  List<ExpenseModel> _sortDescending(List<Map<String, dynamic>> docs) {
    final list = docs.map((m) => ExpenseModel.fromMap(m)).toList();
    list.sort((a, b) {
      final byDate = b.expenseDate.compareTo(a.expenseDate);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Future<List<ExpenseModel>> getAll({String? category}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('expenses');
      final filtered = docs.where((m) => category == null || category == 'All' || m['category'] == category).toList();
      return _sortDescending(filtered);
    }
    final db = await _db;
    final maps = await db.query(
      'expenses',
      where: category != null && category != 'All' ? 'category = ?' : null,
      whereArgs: category != null && category != 'All' ? [category] : null,
      orderBy: 'expenseDate DESC, createdAt DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<List<ExpenseModel>> getForMonth(DateTime month, {String? category}) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('expenses');
      final filtered = docs.where((m) {
        final dateStr = m['expenseDate'] as String?;
        final date = dateStr == null ? null : DateTime.tryParse(dateStr);
        if (date == null || date.isBefore(start) || !date.isBefore(end)) return false;
        return category == null || category == 'All' || m['category'] == category;
      }).toList();
      return _sortDescending(filtered);
    }

    final db = await _db;
    final where = StringBuffer('expenseDate >= ? AND expenseDate < ?');
    final whereArgs = <Object?>[start.toIso8601String(), end.toIso8601String()];
    if (category != null && category != 'All') {
      where.write(' AND category = ?');
      whereArgs.add(category);
    }
    final maps = await db.query(
      'expenses',
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'expenseDate DESC, createdAt DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<double> getTotalForMonth(DateTime month) async {
    final expenses = await getForMonth(month);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<double> getTotalAllTime() async {
    final expenses = await getAll();
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<Map<String, double>> getCategoryTotalsForMonth(DateTime month) async {
    final expenses = await getForMonth(month);
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Future<void> insert(ExpenseModel expense) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('expenses', 'id', expense.toMap());
    } else {
      final db = await _db;
      await db.insert(
        'expenses',
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    AppStateService.instance.notifyExpensesChanged();
  }

  Future<void> update(ExpenseModel expense) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('expenses', 'id', expense.toMap());
    } else {
      final db = await _db;
      await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    }
    AppStateService.instance.notifyExpensesChanged();
  }

  Future<void> delete(String id) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteById('expenses', id);
    } else {
      final db = await _db;
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    }
    AppStateService.instance.notifyExpensesChanged();
  }
}
