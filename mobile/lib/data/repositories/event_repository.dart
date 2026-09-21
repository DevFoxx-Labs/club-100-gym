import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/event_model.dart';

class EventRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<EventModel>> getAllEvents() async {
    final db = await _db;
    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL',
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<List<EventModel>> getEventsForMonth(int year, int month) async {
    final db = await _db;
    final startStr = DateTime(year, month, 1).toIso8601String();
    final endStr = (month < 12
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1))
        .toIso8601String();

    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL AND startTime >= ? AND startTime < ?',
      whereArgs: [startStr, endStr],
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final db = await _db;
    final startStr = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
    final endStr = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL AND startTime >= ? AND startTime <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<EventModel?> getEventById(String id) async {
    final db = await _db;
    final result = await db.query(
      'events',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return EventModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> insertEvent(EventModel event) async {
    final db = await _db;
    await db.insert('events', event.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    final db = await _db;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'events',
      {
        'deletedAt': now,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

