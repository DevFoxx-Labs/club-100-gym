import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../models/notification_model.dart';
import '../../core/services/app_state_service.dart';

class NotificationRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  static String _formatDateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

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
    AppStateService.instance.notifyNotificationsChanged();
  }

  /// Checks if a reminder key was dismissed by the user today to prevent resurfacing on resume.
  Future<bool> isDismissedToday(String key, {DateTime? date}) async {
    try {
      final db = await _db;
      final dateKey = _formatDateKey(date ?? DateTime.now());
      final res = await db.query(
        'dismissed_notifications',
        where: 'dismissKey = ? AND dismissedDate = ?',
        whereArgs: [key, dateKey],
        limit: 1,
      );
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Marks a reminder key as dismissed today.
  Future<void> recordDismissal(String key, {DateTime? date}) async {
    try {
      final db = await _db;
      final dateKey = _formatDateKey(date ?? DateTime.now());
      await db.insert(
        'dismissed_notifications',
        {
          'dismissKey': key,
          'dismissedDate': dateKey,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
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

  /// Records a reminder if it has not already been recorded for this member/type today,
  /// and was not dismissed by the user today.
  /// Returns the notification ID if created, or null if it already exists or was dismissed.
  Future<String?> recordIfNew({
    required String memberId,
    required String type,
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    // If the user already dismissed this reminder today, respect their action
    final dismissKey = '$memberId:$type';
    if (await isDismissedToday(dismissKey, date: scheduledAt)) {
      return null;
    }

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
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> markAllAsRead() async {
    final db = await _db;
    await db.update('notifications', {'isRead': 1});
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> deleteNotification(String id) async {
    final db = await _db;
    // Look up notification to record tombstone dismissal
    try {
      final rows = await db.query('notifications', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) {
        final notif = NotificationItemModel.fromMap(rows.first);
        if (notif.memberId != null) {
          await recordDismissal('${notif.memberId}:${notif.type}', date: notif.scheduledAt);
        } else {
          await recordDismissal(notif.id, date: notif.scheduledAt);
        }
      }
    } catch (_) {}

    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> clearAll() async {
    final db = await _db;
    try {
      // Record dismissal for all existing notifications so daily scan doesn't recreate them today
      final all = await getAllNotifications();
      for (final n in all) {
        if (n.memberId != null) {
          await recordDismissal('${n.memberId}:${n.type}', date: n.scheduledAt);
        } else {
          await recordDismissal(n.id, date: n.scheduledAt);
        }
      }
    } catch (_) {}

    await db.delete('notifications');
    AppStateService.instance.notifyNotificationsChanged();
  }
}
