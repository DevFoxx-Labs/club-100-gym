import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/notification_model.dart';
import '../../core/services/app_state_service.dart';

class NotificationRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  static String _formatDateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<NotificationItemModel>> getAllNotifications({int limit = 100}) async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('notifications');
      final list = docs.map((m) => NotificationItemModel.fromMap(m)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((m) => NotificationItemModel.fromMap(m)).toList();
  }

  Future<void> insertNotification(NotificationItemModel notification) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('notifications', 'id', notification.toMap());
    } else {
      final db = await _db;
      await db.insert(
        'notifications',
        notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    AppStateService.instance.notifyNotificationsChanged();
  }

  /// Checks if a reminder key was dismissed by the user today to prevent resurfacing on resume.
  Future<bool> isDismissedToday(String key, {DateTime? date}) async {
    try {
      final dateKey = _formatDateKey(date ?? DateTime.now());
      if (await DataModeService.instance.isOnline) {
        final doc = await MongoCollectionStore.findById('dismissed_notifications', key);
        return doc != null && doc['dismissedDate'] == dateKey;
      }
      final db = await _db;
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
      final dateKey = _formatDateKey(date ?? DateTime.now());
      if (await DataModeService.instance.isOnline) {
        await MongoCollectionStore.upsert(
          'dismissed_notifications',
          'dismissKey',
          {'dismissKey': key, 'dismissedDate': dateKey},
        );
        return;
      }
      final db = await _db;
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
    final start = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final end = start.add(const Duration(days: 1));

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('notifications');
      for (final doc in docs) {
        if (doc['memberId'] != memberId || doc['type'] != type) continue;
        final scheduled = DateTime.tryParse(doc['scheduledAt'] as String? ?? '');
        if (scheduled != null && !scheduled.isBefore(start) && scheduled.isBefore(end)) {
          return NotificationItemModel.fromMap(doc);
        }
      }
      return null;
    }

    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'memberId = ? AND type = ? AND scheduledAt >= ? AND scheduledAt < ?',
      whereArgs: [memberId, type, start.toIso8601String(), end.toIso8601String()],
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
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('notifications');
      return docs.where((m) => (m['isRead'] ?? 0) == 0).length;
    }
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE isRead = 0');
    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
  }

  Future<void> markAsRead(String id) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('notifications', id, {'isRead': 1});
    } else {
      final db = await _db;
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> markAllAsRead() async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateWhere('notifications', (m) => true, {'isRead': 1});
    } else {
      final db = await _db;
      await db.update('notifications', {'isRead': 1});
    }
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> deleteNotification(String id) async {
    // Look up notification to record tombstone dismissal
    try {
      NotificationItemModel? notif;
      if (await DataModeService.instance.isOnline) {
        final doc = await MongoCollectionStore.findById('notifications', id);
        notif = doc == null ? null : NotificationItemModel.fromMap(doc);
      } else {
        final db = await _db;
        final rows = await db.query('notifications', where: 'id = ?', whereArgs: [id], limit: 1);
        notif = rows.isNotEmpty ? NotificationItemModel.fromMap(rows.first) : null;
      }
      if (notif != null) {
        if (notif.memberId != null) {
          await recordDismissal('${notif.memberId}:${notif.type}', date: notif.scheduledAt);
        } else {
          await recordDismissal(notif.id, date: notif.scheduledAt);
        }
      }
    } catch (_) {}

    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteById('notifications', id);
    } else {
      final db = await _db;
      await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
    }
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> clearAll() async {
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

    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.deleteAll('notifications');
    } else {
      final db = await _db;
      await db.delete('notifications');
    }
    AppStateService.instance.notifyNotificationsChanged();
  }
}
