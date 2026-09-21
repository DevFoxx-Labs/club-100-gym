import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/plan_model.dart';

class PlanRepository {
  Future<List<PlanModel>> getPlans({bool activeOnly = true}) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'membership_plans',
      where: activeOnly ? 'isActive = 1' : null,
      orderBy: 'durationDays ASC',
    );
    return maps.map((map) => PlanModel.fromMap(map)).toList();
  }

  Future<void> addPlan(PlanModel plan) async {
    final db = await AppDatabase.instance.database;
    await db.insert('membership_plans', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePlan(PlanModel plan) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'membership_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deletePlan(String planId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('membership_plans', where: 'id = ?', whereArgs: [planId]);
  }
}

