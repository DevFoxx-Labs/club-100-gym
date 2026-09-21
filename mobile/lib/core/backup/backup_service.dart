import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class BackupService {
  static const int backupVersion = 1;
  static const String secretKey = 'Club100GymSecretKeyForBackupEncryption';

  Future<File> exportBackup() async {
    final db = await AppDatabase.instance.database;

    final gymData = await db.query('gym');
    final adminData = await db.query('admins');
    final plansData = await db.query('membership_plans');
    final membersData = await db.query('members');
    final membershipsData = await db.query('memberships');
    final paymentsData = await db.query('payments');
    final receiptsData = await db.query('receipts');
    final notificationsData = await db.query('notifications');
    final notificationSettingsData = await db.query('notification_settings');
    final appSettingsData = await db.query('app_settings');

    final backupContent = {
      'backupVersion': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': {
        'gym': gymData,
        'admins': adminData,
        'membership_plans': plansData,
        'members': membersData,
        'memberships': membershipsData,
        'payments': paymentsData,
        'receipts': receiptsData,
        'notifications': notificationsData,
        'notification_settings': notificationSettingsData,
        'app_settings': appSettingsData,
      }
    };

    final jsonString = jsonEncode(backupContent);
    final encryptedData = _encryptData(jsonString);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/gym_backup_$timestamp.gymbackup');

    await file.writeAsString(encryptedData);
    return file;
  }

  Future<bool> importBackup(File backupFile) async {
    try {
      final encryptedData = await backupFile.readAsString();
      final jsonString = _decryptData(encryptedData);
      final Map<String, dynamic> backupContent = jsonDecode(jsonString);

      if (backupContent['backupVersion'] == null || (backupContent['backupVersion'] as int) > backupVersion) {
        throw Exception('Incompatible backup version.');
      }

      final Map<String, dynamic> tables = backupContent['tables'];
      final db = await AppDatabase.instance.database;

      await db.transaction((txn) async {
        // Clear existing tables
        await txn.delete('memberships');
        await txn.delete('payments');
        await txn.delete('receipts');
        await txn.delete('notifications');
        await txn.delete('members');
        await txn.delete('membership_plans');
        await txn.delete('gym');
        await txn.delete('admins');
        await txn.delete('notification_settings');
        await txn.delete('app_settings');

        // Restore tables
        for (var row in (tables['gym'] as List? ?? [])) {
          await txn.insert('gym', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['admins'] as List? ?? [])) {
          await txn.insert('admins', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['membership_plans'] as List? ?? [])) {
          await txn.insert('membership_plans', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['members'] as List? ?? [])) {
          await txn.insert('members', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['memberships'] as List? ?? [])) {
          await txn.insert('memberships', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['payments'] as List? ?? [])) {
          await txn.insert('payments', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['receipts'] as List? ?? [])) {
          await txn.insert('receipts', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['notifications'] as List? ?? [])) {
          await txn.insert('notifications', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['notification_settings'] as List? ?? [])) {
          await txn.insert('notification_settings', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (var row in (tables['app_settings'] as List? ?? [])) {
          await txn.insert('app_settings', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  String _encryptData(String rawText) {
    final bytes = utf8.encode(rawText);
    final keyBytes = utf8.encode(secretKey);
    final encryptedBytes = List<int>.generate(bytes.length, (i) => bytes[i] ^ keyBytes[i % keyBytes.length]);
    return base64Encode(encryptedBytes);
  }

  String _decryptData(String encryptedText) {
    final bytes = base64Decode(encryptedText);
    final keyBytes = utf8.encode(secretKey);
    final decryptedBytes = List<int>.generate(bytes.length, (i) => bytes[i] ^ keyBytes[i % keyBytes.length]);
    return utf8.decode(decryptedBytes);
  }
}

