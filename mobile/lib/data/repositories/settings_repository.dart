import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/gym_info_model.dart';
import '../models/admin_model.dart';

class SettingsRepository {
  Future<GymInfoModel> getGymInfo() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('gym', limit: 1);
    if (maps.isNotEmpty) {
      return GymInfoModel.fromMap(maps.first);
    }
    return GymInfoModel(
      id: 'default',
      name: 'Club 100 The Gym',
      ownerName: 'Admin',
      phone: '070843 06574',
      address: '1st Floor TP Nagar, Transport Nagar, Prayagraj, UP 211011',
      city: 'Prayagraj',
      currency: 'INR (₹)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveGymInfo(GymInfoModel info) async {
    final db = await AppDatabase.instance.database;
    await db.insert('gym', info.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AdminModel> getAdminInfo() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('admins', limit: 1);
    if (maps.isNotEmpty) {
      return AdminModel.fromMap(maps.first);
    }
    return AdminModel(
      id: 'default',
      name: 'Gym Administrator',
      phone: '070843 06574',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveAdminInfo(AdminModel admin) async {
    final db = await AppDatabase.instance.database;
    await db.insert('admins', admin.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('notification_settings', limit: 1);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return {
        'fee7d': (map['feeReminder7Days'] ?? 1) == 1,
        'fee3d': (map['feeReminder3Days'] ?? 1) == 1,
        'fee1d': (map['feeReminder1Day'] ?? 1) == 1,
        'feeDue': (map['feeReminderDueToday'] ?? 1) == 1,
        'feeOverdue': (map['feeReminderOverdue'] ?? 1) == 1,
      };
    }
    return {'fee7d': true, 'fee3d': true, 'fee1d': true, 'feeDue': true, 'feeOverdue': true};
  }

  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final db = await AppDatabase.instance.database;
    await db.insert('notification_settings', {
      'id': 'default',
      'feeReminder7Days': (settings['fee7d'] ?? true) ? 1 : 0,
      'feeReminder3Days': (settings['fee3d'] ?? true) ? 1 : 0,
      'feeReminder1Day': (settings['fee1d'] ?? true) ? 1 : 0,
      'feeReminderDueToday': (settings['feeDue'] ?? true) ? 1 : 0,
      'feeReminderOverdue': (settings['feeOverdue'] ?? true) ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

