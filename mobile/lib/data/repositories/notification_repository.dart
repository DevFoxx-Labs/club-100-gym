import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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

  /// Prevents duplicate recording of the same reminder for the same member/type on the same day.
  Future<NotificationItemModel?> findExisting({
    required String memberId,
    required String type,
    required DateTime scheduledAt,
  }) async {
    final db = await _db;
    final start = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day).toIso8601String();
    final end = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day)
        .add(const Duration(days: 1))
        .toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'memberId = ? AND type = ? AND scheduledAt >= ? AND scheduledAt < ?',
      whereArgs: [memberId, type, start, end],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return NotificationItemModel.fromMap(maps.first);
    }
    return null;
  }

  /// Records a reminder if it has not already been recorded for this member/type today.
  /// Returns the notification ID if created, or null if it already exists.
  Future<String?> recordIfNew({
    required String memberId,
    required String type,
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    final existing = await findExisting(
      memberId: memberId,
      type: type,
      scheduledAt: scheduledAt,
    );
    if (existing != null) return null;

    final id = const Uuid().v4();
    final now = DateTime.now();
    await insertNotification(
      NotificationItemModel(
        id: id,
        memberId: memberId,
        type: type,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        triggeredAt: now,
        isRead: false,
        createdAt: now,
      ),
    );
    return id;
  }

  Future<int> getUnreadCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE isRead = 0');
    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
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
