import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/announcement_model.dart';
import '../../core/services/app_state_service.dart';

class AnnouncementRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<AnnouncementModel>> getAll() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM announcements'),
    ) ?? 0;

    if (count == 0) {
      await _seedDefaultAnnouncements(db);
    }

    final maps = await db.query(
      'announcements',
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    final list = maps.map((m) => AnnouncementModel.fromMap(m)).toList();
    _exportSharedBroadcasts(list);
    return list;
  }

  Future<void> _seedDefaultAnnouncements(Database db) async {
    final now = DateTime.now();
    final seeds = [
      AnnouncementModel(
        id: 'seed-zumba-1',
        title: 'Zumba Class Tomorrow',
        message:
            "Don't miss our special Zumba Dance Fitness class tomorrow at 6:00 AM in the Aerobics Studio. Let's move, sweat and stay healthy together! 💃",
        category: 'class',
        audienceType: 'all',
        audienceLabel: 'All Members',
        isPinned: true,
        isImportant: true,
        status: 'sent',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 23)),
        createdAt: now.subtract(const Duration(hours: 2, minutes: 23)),
      ),
      AnnouncementModel(
        id: 'seed-equip-2',
        title: 'New Equipment Arrived',
        message:
            "We've added new strength training equipment to the weights section. Come check it out!",
        category: 'equipment',
        audienceType: 'all',
        audienceLabel: 'All Members',
        isPinned: false,
        status: 'sent',
        sentAt: now.subtract(const Duration(days: 2, hours: 4)),
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      AnnouncementModel(
        id: 'seed-holiday-3',
        title: 'Holiday Hours',
        message:
            'The gym will be open from 6:00 AM – 2:00 PM this Sunday due to the public holiday. Plan your workouts accordingly.',
        category: 'hours',
        audienceType: 'all',
        audienceLabel: 'All Members',
        isPinned: false,
        status: 'sent',
        sentAt: now.subtract(const Duration(days: 4, hours: 9)),
        createdAt: now.subtract(const Duration(days: 4, hours: 9)),
      ),
      AnnouncementModel(
        id: 'seed-apprec-4',
        title: 'Member Appreciation Week',
        message:
            'Thank you for being part of The Elite Fitness Gym! Enjoy special offers and events all week long. 💚',
        category: 'event',
        audienceType: 'all',
        audienceLabel: 'All Members',
        isPinned: false,
        status: 'sent',
        sentAt: now.subtract(const Duration(days: 7, hours: 7)),
        createdAt: now.subtract(const Duration(days: 7, hours: 7)),
      ),
      AnnouncementModel(
        id: 'seed-maint-5',
        title: 'Maintenance Update',
        message:
            'The sauna will be under maintenance on 12 Sep 2026. We apologize for the inconvenience.',
        category: 'maintenance',
        audienceType: 'all',
        audienceLabel: 'All Members',
        isPinned: false,
        isImportant: true,
        status: 'sent',
        sentAt: now.subtract(const Duration(days: 12, hours: 14)),
        createdAt: now.subtract(const Duration(days: 12, hours: 14)),
      ),
    ];

    for (final seed in seeds) {
      await db.insert(
        'announcements',
        seed.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> insert(AnnouncementModel announcement) async {
    final db = await _db;
    await db.insert(
      'announcements',
      announcement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppStateService.instance.notifyNotificationsChanged();
    _exportLatest();
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
    _exportLatest();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
    AppStateService.instance.notifyNotificationsChanged();
    _exportLatest();
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
    _exportLatest();
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
    _exportLatest();
  }

  /// Promotes any scheduled announcements whose scheduled time has passed to 'sent'.
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
      _exportLatest();
    }
    return due;
  }

  Future<void> _exportLatest() async {
    try {
      final list = await getAll();
      _exportSharedBroadcasts(list);
    } catch (_) {}
  }

  void _exportSharedBroadcasts(List<AnnouncementModel> list) {
    Future.microtask(() async {
      try {
        final jsonStr = jsonEncode(list.map((a) => a.toMap()).toList());
        // 1. App documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDocDir.path}/elite_fitness_broadcasts.json');
        await localFile.writeAsString(jsonStr);

        // 2. Try shared public storage path if accessible
        try {
          final sharedFile = File('/sdcard/Download/elite_fitness_broadcasts.json');
          await sharedFile.writeAsString(jsonStr);
        } catch (_) {}
      } catch (e) {
        debugPrint('Shared broadcast export note: $e');
      }
    });
  }
}
