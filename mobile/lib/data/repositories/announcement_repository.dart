import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/announcement_model.dart';
import '../../core/services/app_state_service.dart';

class AnnouncementRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<AnnouncementModel>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return maps.map((m) => AnnouncementModel.fromMap(m)).toList();
  }

  Future<void> insert(AnnouncementModel announcement) async {
    final db = await _db;
    await db.insert(
      'announcements',
      announcement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> update(AnnouncementModel announcement) async {
    final db = await _db;
    await db.update(
      'announcements',
      announcement.toMap(),
      where: 'id = ?',
      whereArgs: [announcement.id],
    );
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> setPinned(String id, bool isPinned) async {
    final db = await _db;
    await db.update(
      'announcements',
      {'isPinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    AppStateService.instance.notifyNotificationsChanged();
  }

  Future<void> setImportant(String id, bool isImportant) async {
    final db = await _db;
    await db.update(
      'announcements',
      {'isImportant': isImportant ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    AppStateService.instance.notifyNotificationsChanged();
  }

  /// Promotes any scheduled announcements whose scheduled time has passed to 'sent'.
  /// Returns the list of announcements that were just promoted so the caller can
  /// surface a local notification for them.
  Future<List<AnnouncementModel>> promoteDueScheduled() async {
    final db = await _db;
    final now = DateTime.now();
    final maps = await db.query(
      'announcements',
      where: 'status = ? AND scheduledAt IS NOT NULL AND scheduledAt <= ?',
      whereArgs: ['scheduled', now.toIso8601String()],
    );

    final due = maps.map((m) => AnnouncementModel.fromMap(m)).toList();
    for (final item in due) {
      await db.update(
        'announcements',
        {'status': 'sent', 'sentAt': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
    if (due.isNotEmpty) {
      AppStateService.instance.notifyNotificationsChanged();
    }
    return due;
  }
}
