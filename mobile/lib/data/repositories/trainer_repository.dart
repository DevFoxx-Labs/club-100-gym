import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/trainer_model.dart';
import '../models/trainer_payout_model.dart';
import '../models/trainer_change_log_model.dart';

class TrainerRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<TrainerModel>> getAllTrainers({bool includeInactive = false}) async {
    final db = await _db;
    final where = includeInactive
        ? 'deletedAt IS NULL'
        : 'isActive = 1 AND deletedAt IS NULL';
    final result = await db.query(
      'trainers',
      where: where,
      orderBy: 'name ASC',
    );
    return result.map((map) => TrainerModel.fromMap(map)).toList();
  }

  Future<TrainerModel?> getTrainerById(String id) async {
    final db = await _db;
    final result = await db.query(
      'trainers',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return TrainerModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> insertTrainer(TrainerModel trainer) async {
    final db = await _db;
    await db.insert('trainers', trainer.toMap());
  }

  Future<void> updateTrainer(TrainerModel trainer) async {
    final db = await _db;
    await db.update(
      'trainers',
      trainer.toMap(),
      where: 'id = ?',
      whereArgs: [trainer.id],
    );
  }

  Future<void> updateTrainerPhoto(String trainerId, String? photoPath) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'trainers',
      {
        'photoPath': photoPath,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [trainerId],
    );
  }

  Future<void> deleteTrainer(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'trainers',
      {
        'deletedAt': now,
        'isActive': 0,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payouts
  Future<void> recordPayout(TrainerPayoutModel payout) async {
    final db = await _db;
    await db.insert('trainer_payouts', payout.toMap());
  }

  Future<List<TrainerPayoutModel>> getPayoutsForTrainer(String trainerId) async {
    final db = await _db;
    final result = await db.query(
      'trainer_payouts',
      where: 'trainerId = ? AND deletedAt IS NULL',
      whereArgs: [trainerId],
      orderBy: 'payoutDate DESC',
    );
    return result.map((map) => TrainerPayoutModel.fromMap(map)).toList();
  }

  Future<double> getTotalPaidOut(String trainerId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM trainer_payouts WHERE trainerId = ? AND deletedAt IS NULL',
      [trainerId],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<void> deletePayout(String payoutId) async {
    final db = await _db;
    await db.delete(
      'trainer_payouts',
      where: 'id = ?',
      whereArgs: [payoutId],
    );
  }

  // Trainer Change Logs
  Future<void> recordTrainerChangeLog(TrainerChangeLogModel log) async {
    final db = await _db;
    await db.insert('trainer_change_logs', log.toMap());
  }

  Future<List<TrainerChangeLogModel>> getTrainerChangeLogsForMember(String memberId) async {
    final db = await _db;
    final result = await db.query(
      'trainer_change_logs',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'changedAt DESC',
    );
    return result.map((map) => TrainerChangeLogModel.fromMap(map)).toList();
  }

  // Query members assigned to a trainer
  Future<List<Map<String, dynamic>>> getMembersAssignedToTrainer(String trainerId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT m.id as memberId, m.name as memberName, m.phone as memberPhone, m.photoPath,
             ms.id as membershipId, ms.planName, ms.personalTrainingFee, ms.startDate, ms.endDate
      FROM memberships ms
      JOIN members m ON m.id = ms.memberId
      WHERE ms.trainerId = ? AND ms.status = 'Active' AND m.isArchived = 0
      ORDER BY m.name ASC
    ''', [trainerId]);
    return result;
  }
}

