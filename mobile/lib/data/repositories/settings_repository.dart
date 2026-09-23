import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/gym_info_model.dart';
import '../models/admin_model.dart';

class SettingsRepository {
  static const _accentColorKey = 'accentColorHex';

  /// Returns the admin's saved favorite highlight color, or null if never customized.
  Future<Color?> getAccentColor() async {
    Map<String, dynamic>? map;
    if (await DataModeService.instance.isOnline) {
      map = await MongoCollectionStore.findById('app_settings', _accentColorKey);
    } else {
      final db = await AppDatabase.instance.database;
      final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [_accentColorKey], limit: 1);
      map = maps.isNotEmpty ? maps.first : null;
    }
    final hex = map?['value'] as String?;
    if (hex == null || hex.isEmpty) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  Future<void> saveAccentColor(Color color) async {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    final data = {'key': _accentColorKey, 'value': hex};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('app_settings', 'key', data);
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('app_settings', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  GymInfoModel _defaultGymInfo() => GymInfoModel(
        id: 'default',
        name: 'Elite Fitness Gym',
        ownerName: 'Admin',
        phone: '',
        address: '',
        city: '',
        currency: 'INR (₹)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Future<GymInfoModel> getGymInfo() async {
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('gym', 'default');
      return doc != null ? GymInfoModel.fromMap(doc) : _defaultGymInfo();
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('gym', limit: 1);
    if (maps.isNotEmpty) {
      return GymInfoModel.fromMap(maps.first);
    }
    return _defaultGymInfo();
  }

  Future<void> saveGymInfo(GymInfoModel info) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('gym', 'id', info.toMap());
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('gym', info.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  AdminModel _defaultAdminInfo() => AdminModel(
        id: 'default',
        name: 'Gym Administrator',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Future<AdminModel> getAdminInfo() async {
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('admins', 'default');
      return doc != null ? AdminModel.fromMap(doc) : _defaultAdminInfo();
    }
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('admins', limit: 1);
    if (maps.isNotEmpty) {
      return AdminModel.fromMap(maps.first);
    }
    return _defaultAdminInfo();
  }

  Future<void> saveAdminInfo(AdminModel admin) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('admins', 'id', admin.toMap());
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('admins', admin.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static const _listDisplayStyleKey = 'listDisplayStyle';

  /// Returns 'card' (full card, the original design) or 'tile' (compact row,
  /// matching the Dashboard's Recent Activity tiles). Defaults to 'card'.
  Future<String> getListDisplayStyle() async {
    Map<String, dynamic>? map;
    if (await DataModeService.instance.isOnline) {
      map = await MongoCollectionStore.findById('app_settings', _listDisplayStyleKey);
    } else {
      final db = await AppDatabase.instance.database;
      final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [_listDisplayStyleKey], limit: 1);
      map = maps.isNotEmpty ? maps.first : null;
    }
    final value = map?['value'] as String?;
    return value == 'tile' ? 'tile' : 'card';
  }

  Future<void> saveListDisplayStyle(String style) async {
    final data = {'key': _listDisplayStyleKey, 'value': style};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('app_settings', 'key', data);
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('app_settings', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    Map<String, dynamic>? map;
    if (await DataModeService.instance.isOnline) {
      map = await MongoCollectionStore.findById('notification_settings', 'default');
    } else {
      final db = await AppDatabase.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('notification_settings', limit: 1);
      map = maps.isNotEmpty ? maps.first : null;
    }
    if (map != null) {
      return {
        'fee7d': (map['feeReminder7Days'] ?? 1) == 1,
        'fee3d': (map['feeReminder3Days'] ?? 1) == 1,
        'fee1d': (map['feeReminder1Day'] ?? 1) == 1,
        'feeDue': (map['feeReminderDueToday'] ?? 1) == 1,
        'feeOverdue': (map['feeReminderOverdue'] ?? 1) == 1,
        'expiry7d': (map['membershipReminder7Days'] ?? 1) == 1,
        'expiry3d': (map['membershipReminder3Days'] ?? 1) == 1,
        'expiry1d': (map['membershipReminder1Day'] ?? 1) == 1,
      };
    }
    return {
      'fee7d': true,
      'fee3d': true,
      'fee1d': true,
      'feeDue': true,
      'feeOverdue': true,
      'expiry7d': true,
      'expiry3d': true,
      'expiry1d': true,
    };
  }

  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final data = {
      'id': 'default',
      'feeReminder7Days': (settings['fee7d'] ?? true) ? 1 : 0,
      'feeReminder3Days': (settings['fee3d'] ?? true) ? 1 : 0,
      'feeReminder1Day': (settings['fee1d'] ?? true) ? 1 : 0,
      'feeReminderDueToday': (settings['feeDue'] ?? true) ? 1 : 0,
      'feeReminderOverdue': (settings['feeOverdue'] ?? true) ? 1 : 0,
      'membershipReminder7Days': (settings['expiry7d'] ?? true) ? 1 : 0,
      'membershipReminder3Days': (settings['expiry3d'] ?? true) ? 1 : 0,
      'membershipReminder1Day': (settings['expiry1d'] ?? true) ? 1 : 0,
    };
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('notification_settings', 'id', data);
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert('notification_settings', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
