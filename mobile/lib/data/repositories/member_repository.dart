import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/member_model.dart';
import '../models/membership_model.dart';

class MemberRepository {
  Future<List<MemberModel>> getMembers({bool includeArchived = false}) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: includeArchived ? null : 'isArchived = 0 AND deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MemberModel.fromMap(map)).toList();
  }

  Future<MemberModel?> getMemberById(String id) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MemberModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addMember(MemberModel member, MembershipModel membership) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert('members', member.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('memberships', membership.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> updateMember(MemberModel member) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> archiveMember(String memberId, bool archive) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'members',
      {'isArchived': archive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Future<void> deleteMember(String memberId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('members', where: 'id = ?', whereArgs: [memberId]);
    await db.delete('memberships', where: 'memberId = ?', whereArgs: [memberId]);
    await db.delete('payments', where: 'memberId = ?', whereArgs: [memberId]);
  }

  Future<MembershipModel?> getLatestMembership(String memberId) async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memberships',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'endDate DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MembershipModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateMembership(MembershipModel membership) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'memberships',
      membership.toMap(),
      where: 'id = ?',
      whereArgs: [membership.id],
    );
  }
}

