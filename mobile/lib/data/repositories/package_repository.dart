import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/package_model.dart';

class PackageRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<PackageModel>> getAllPackages({bool includeInactive = false}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('membership_packages');
      final filtered = docs.where((m) {
        if (m['deletedAt'] != null) return false;
        if (includeInactive) return true;
        return (m['isActive'] ?? 0) == 1;
      }).map((m) => PackageModel.fromMap(m)).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }
    final db = await _db;
    final where = includeInactive
        ? 'deletedAt IS NULL'
        : 'isActive = 1 AND deletedAt IS NULL';
    final result = await db.query(
      'membership_packages',
      where: where,
      orderBy: 'name ASC',
    );
    return result.map((map) => PackageModel.fromMap(map)).toList();
  }

  Future<PackageModel?> getPackageById(String id) async {
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('membership_packages', id);
      if (doc == null || doc['deletedAt'] != null) return null;
      return PackageModel.fromMap(doc);
    }
    final db = await _db;
    final result = await db.query(
      'membership_packages',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return PackageModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> insertPackage(PackageModel package) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('membership_packages', 'id', package.toMap());
      return;
    }
    final db = await _db;
    await db.insert('membership_packages', package.toMap());
  }

  Future<void> updatePackage(PackageModel package) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('membership_packages', 'id', package.toMap());
      return;
    }
    final db = await _db;
    await db.update(
      'membership_packages',
      package.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  Future<void> deletePackage(String id) async {
    final now = DateTime.now().toIso8601String();
    final fields = {'deletedAt': now, 'isActive': 0, 'updatedAt': now};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('membership_packages', id, fields);
      return;
    }
    final db = await _db;
    await db.update(
      'membership_packages',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
