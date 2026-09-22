import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/expense_model.dart';
import '../../core/services/app_state_service.dart';

class ExpenseRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<ExpenseModel>> getAll({String? category}) async {
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
    final db = await _db;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
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
    final db = await _db;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppStateService.instance.notifyExpensesChanged();
  }

  Future<void> update(ExpenseModel expense) async {
    final db = await _db;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    AppStateService.instance.notifyExpensesChanged();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    AppStateService.instance.notifyExpensesChanged();
  }
}
