import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/member_model.dart';
import '../models/membership_model.dart';
import '../models/membership_change_log_model.dart';
import '../models/trainer_change_log_model.dart';

class MemberRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<MemberModel>> getMembers({bool includeArchived = false}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: includeArchived ? 'deletedAt IS NULL' : 'isArchived = 0 AND deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MemberModel.fromMap(map)).toList();
  }

  Future<List<MemberModel>> getArchivedMembers() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: 'isArchived = 1 AND deletedAt IS NULL',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => MemberModel.fromMap(map)).toList();
  }

  Future<MemberModel?> getMemberById(String id) async {
    final db = await _db;
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
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('members', member.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('memberships', membership.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> updateMember(MemberModel member) async {
    final db = await _db;
    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> archiveMember(String memberId, bool archive) async {
    final db = await _db;
    await db.update(
      'members',
      {'isArchived': archive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Future<void> restoreMember(String memberId) async {
    await archiveMember(memberId, false);
  }

  Future<bool> canHardDelete(String memberId) async {
    final db = await _db;
    final payments = await db.query(
      'payments',
      where: 'memberId = ?',
      whereArgs: [memberId],
      limit: 1,
    );
    return payments.isEmpty;
  }

  Future<bool> hardDeleteMember(String memberId) async {
    final db = await _db;
    final canDelete = await canHardDelete(memberId);
    if (!canDelete) return false;

    await db.transaction((txn) async {
      await txn.delete('membership_change_logs', where: 'memberId = ?', whereArgs: [memberId]);
      await txn.delete('trainer_change_logs', where: 'memberId = ?', whereArgs: [memberId]);
      await txn.delete('memberships', where: 'memberId = ?', whereArgs: [memberId]);
      await txn.delete('members', where: 'id = ?', whereArgs: [memberId]);
    });
    return true;
  }

  Future<void> deleteMember(String memberId) async {
    final db = await _db;
    await db.delete('members', where: 'id = ?', whereArgs: [memberId]);
    await db.delete('memberships', where: 'memberId = ?', whereArgs: [memberId]);
    await db.delete('payments', where: 'memberId = ?', whereArgs: [memberId]);
  }

  Future<MembershipModel?> getLatestMembership(String memberId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'memberships',
      where: 'memberId = ? AND status != ?',
      whereArgs: [memberId, 'Superseded'],
      orderBy: 'endDate DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MembershipModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateMembership(MembershipModel membership) async {
    final db = await _db;
    await db.update(
      'memberships',
      membership.toMap(),
      where: 'id = ?',
      whereArgs: [membership.id],
    );
  }

  // Mid-term plan change
  Future<void> changePlan({
    required String memberId,
    required String currentMembershipId,
    required MembershipModel newMembership,
    required MembershipChangeLogModel log,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Mark current membership as Superseded
      await txn.update(
        'memberships',
        {'status': 'Superseded', 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [currentMembershipId],
      );
      // Insert new membership
      await txn.insert('memberships', newMembership.toMap());
      // Record audit log
      await txn.insert('membership_change_logs', log.toMap());
    });
  }

  // Trainer change
  Future<void> changeTrainer({
    required String membershipId,
    String? memberId,
    required String? newTrainerId,
    required double newPersonalTrainingFee,
    double? newFeeAmount,
    required TrainerChangeLogModel log,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updateData = <String, dynamic>{
        'trainerId': newTrainerId,
        'personalTrainingFee': newPersonalTrainingFee,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (newFeeAmount != null) {
        updateData['feeAmount'] = newFeeAmount;
      }
      await txn.update(
        'memberships',
        updateData,
        where: 'id = ?',
        whereArgs: [membershipId],
      );
      await txn.insert('trainer_change_logs', log.toMap());
    });
  }

  Future<List<MembershipChangeLogModel>> getMembershipChangeLogs(String memberId) async {
    final db = await _db;
    final result = await db.query(
      'membership_change_logs',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'changedAt DESC',
    );
    return result.map((map) => MembershipChangeLogModel.fromMap(map)).toList();
  }
}
