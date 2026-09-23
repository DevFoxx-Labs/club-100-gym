import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/trainer_model.dart';
import '../models/trainer_payout_model.dart';
import '../models/trainer_change_log_model.dart';

class TrainerRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<TrainerModel>> getAllTrainers({bool includeInactive = false}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('trainers');
      final filtered = docs.where((m) {
        if (m['deletedAt'] != null) return false;
        if (includeInactive) return true;
        return (m['isActive'] ?? 0) == 1;
      }).map((m) => TrainerModel.fromMap(m)).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('trainers', id);
      if (doc == null || doc['deletedAt'] != null) return null;
      return TrainerModel.fromMap(doc);
    }
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
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('trainers', 'id', trainer.toMap());
      return;
    }
    final db = await _db;
    await db.insert('trainers', trainer.toMap());
  }

  Future<void> updateTrainer(TrainerModel trainer) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('trainers', 'id', trainer.toMap());
      return;
    }
    final db = await _db;
    await db.update(
      'trainers',
      trainer.toMap(),
      where: 'id = ?',
      whereArgs: [trainer.id],
    );
  }

  Future<void> updateTrainerPhoto(String trainerId, String? photoPath) async {
    final now = DateTime.now().toIso8601String();
    final fields = {'photoPath': photoPath, 'updatedAt': now};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('trainers', trainerId, fields);
      return;
    }
    final db = await _db;
    await db.update(
      'trainers',
      fields,
      where: 'id = ?',
      whereArgs: [trainerId],
    );
  }

  Future<void> deleteTrainer(String id) async {
    final now = DateTime.now().toIso8601String();
    final fields = {'deletedAt': now, 'isActive': 0, 'updatedAt': now};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('trainers', id, fields);
      return;
    }
    final db = await _db;
    await db.update(
      'trainers',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payouts
  Future<void> recordPayout(TrainerPayoutModel payout) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('trainer_payouts', 'id', payout.toMap());
      return;
    }
    final db = await _db;
    await db.insert('trainer_payouts', payout.toMap());
  }

  Future<List<TrainerPayoutModel>> getPayoutsForTrainer(String trainerId) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('trainer_payouts');
      final filtered = docs
          .where((m) => m['trainerId'] == trainerId && m['deletedAt'] == null)
          .map((m) => TrainerPayoutModel.fromMap(m))
          .toList();
      filtered.sort((a, b) => b.payoutDate.compareTo(a.payoutDate));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('trainer_payouts');
      var total = 0.0;
      for (final doc in docs) {
        if (doc['trainerId'] == trainerId && doc['deletedAt'] == null) {
          total += (doc['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    }
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
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteById('trainer_payouts', payoutId);
      return;
    }
    final db = await _db;
    await db.delete(
      'trainer_payouts',
      where: 'id = ?',
      whereArgs: [payoutId],
    );
  }

  // Trainer Change Logs
  Future<void> recordTrainerChangeLog(TrainerChangeLogModel log) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('trainer_change_logs', 'id', log.toMap());
      return;
    }
    final db = await _db;
    await db.insert('trainer_change_logs', log.toMap());
  }

  Future<List<TrainerChangeLogModel>> getTrainerChangeLogsForMember(String memberId) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('trainer_change_logs');
      final filtered = docs.where((m) => m['memberId'] == memberId).map((m) => TrainerChangeLogModel.fromMap(m)).toList();
      filtered.sort((a, b) => b.changedAt.compareTo(a.changedAt));
      return filtered;
    }
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
    if (await DataModeService.instance.isOnline) {
      final memberships = await MongoCollectionStore.all('memberships');
      final members = await MongoCollectionStore.all('members');
      final membersById = {for (final m in members) m['id']: m};

      final rows = <Map<String, dynamic>>[];
      for (final ms in memberships) {
        if (ms['trainerId'] != trainerId || ms['status'] != 'Active') continue;
        final member = membersById[ms['memberId']];
        if (member == null || (member['isArchived'] ?? 0) != 0) continue;
        rows.add({
          'memberId': member['id'],
          'memberName': member['name'],
          'memberPhone': member['phone'],
          'photoPath': member['photoPath'],
          'membershipId': ms['id'],
          'planName': ms['planName'],
          'personalTrainingFee': ms['personalTrainingFee'],
          'startDate': ms['startDate'],
          'endDate': ms['endDate'],
        });
      }
      rows.sort((a, b) => (a['memberName'] as String? ?? '').compareTo(b['memberName'] as String? ?? ''));
      return rows;
    }

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
