import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<NotificationItemModel>> getAllNotifications({int limit = 100}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((m) => NotificationItemModel.fromMap(m)).toList();
  }

  Future<void> insertNotification(NotificationItemModel notification) async {
    final db = await _db;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markAsRead(String id) async {
    final db = await _db;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await _db;
    await db.update('notifications', {'isRead': 1});
  }

  Future<void> deleteNotification(String id) async {
    final db = await _db;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('notifications');
  }
}

