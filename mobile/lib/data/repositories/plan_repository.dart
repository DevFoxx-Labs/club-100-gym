import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/plan_model.dart';

class PlanRepository {
  Future<List<PlanModel>> getPlans({bool activeOnly = true}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('membership_plans');
      final filtered = docs
          .where((m) => !activeOnly || (m['isActive'] ?? 0) == 1)
          .map((m) => PlanModel.fromMap(m))
          .toList();
      filtered.sort((a, b) => a.durationDays.compareTo(b.durationDays));
      return filtered;
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'membership_plans',
      where: activeOnly ? 'isActive = 1' : null,
      orderBy: 'durationDays ASC',
    );
    return maps.map((map) => PlanModel.fromMap(map)).toList();
  }

  Future<void> addPlan(PlanModel plan) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('membership_plans', 'id', plan.toMap());
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('membership_plans', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePlan(PlanModel plan) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('membership_plans', 'id', plan.toMap());
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.update(
      'membership_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<PlanModel?> getPlanById(String id) async {
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('membership_plans', id);
      return doc == null ? null : PlanModel.fromMap(doc);
    }
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'membership_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PlanModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PlanModel>> getPlansByPackageId(String packageId, {bool activeOnly = true}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('membership_plans');
      final filtered = docs
          .where((m) => m['packageId'] == packageId && (!activeOnly || (m['isActive'] ?? 0) == 1))
          .map((m) => PlanModel.fromMap(m))
          .toList();
      filtered.sort((a, b) => a.durationDays.compareTo(b.durationDays));
      return filtered;
    }
    final db = await AppDatabase.instance.database;
    final where = activeOnly
        ? 'packageId = ? AND isActive = 1'
        : 'packageId = ?';
    final List<Map<String, dynamic>> maps = await db.query(
      'membership_plans',
      where: where,
      whereArgs: [packageId],
      orderBy: 'durationDays ASC',
    );
    return maps.map((map) => PlanModel.fromMap(map)).toList();
  }

  Future<void> deletePlan(String planId) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteById('membership_plans', planId);
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.delete('membership_plans', where: 'id = ?', whereArgs: [planId]);
  }
}
