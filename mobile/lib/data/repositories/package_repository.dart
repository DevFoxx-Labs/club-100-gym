import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/package_model.dart';

class PackageRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<PackageModel>> getAllPackages({bool includeInactive = false}) async {
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
    final db = await _db;
    await db.insert('membership_packages', package.toMap());
  }

  Future<void> updatePackage(PackageModel package) async {
    final db = await _db;
    await db.update(
      'membership_packages',
      package.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  Future<void> deletePackage(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'membership_packages',
      {
        'deletedAt': now,
        'isActive': 0,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

