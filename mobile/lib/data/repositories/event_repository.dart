import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_collection_store.dart';
import '../models/event_model.dart';

class EventRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  List<EventModel> _sortedByStart(List<Map<String, dynamic>> docs) {
    final list = docs.map((m) => EventModel.fromMap(m)).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  Future<List<EventModel>> getAllEvents() async {
    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('events');
      return _sortedByStart(docs.where((m) => m['deletedAt'] == null).toList());
    }
    final db = await _db;
    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL',
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<List<EventModel>> getEventsForMonth(int year, int month) async {
    final startStr = DateTime(year, month, 1).toIso8601String();
    final endStr = (month < 12
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1))
        .toIso8601String();

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('events');
      return _sortedByStart(docs.where((m) {
        if (m['deletedAt'] != null) return false;
        final start = m['startTime'] as String?;
        return start != null && start.compareTo(startStr) >= 0 && start.compareTo(endStr) < 0;
      }).toList());
    }

    final db = await _db;
    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL AND startTime >= ? AND startTime < ?',
      whereArgs: [startStr, endStr],
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    final startStr = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
    final endStr = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('events');
      return _sortedByStart(docs.where((m) {
        if (m['deletedAt'] != null) return false;
        final start = m['startTime'] as String?;
        return start != null && start.compareTo(startStr) >= 0 && start.compareTo(endStr) <= 0;
      }).toList());
    }

    final db = await _db;
    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL AND startTime >= ? AND startTime <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<List<EventModel>> getEventsToday() async {
    final now = DateTime.now();
    return getEventsForDate(now);
  }

  Future<List<EventModel>> getUpcomingEvents({int daysAhead = 30}) async {
    final now = DateTime.now();
    final startStr = DateTime(now.year, now.month, now.day, 0, 0, 0).toIso8601String();
    final endStr = now.add(Duration(days: daysAhead)).toIso8601String();

    if (await DataModeService.instance.isOnline) {
      final docs = await MongoCollectionStore.all('events');
      return _sortedByStart(docs.where((m) {
        if (m['deletedAt'] != null) return false;
        final start = m['startTime'] as String?;
        return start != null && start.compareTo(startStr) >= 0 && start.compareTo(endStr) <= 0;
      }).toList());
    }

    final db = await _db;
    final result = await db.query(
      'events',
      where: 'deletedAt IS NULL AND startTime >= ? AND startTime <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'startTime ASC',
    );
    return result.map((map) => EventModel.fromMap(map)).toList();
  }

  Future<EventModel?> getEventById(String id) async {
    if (await DataModeService.instance.isOnline) {
      final doc = await MongoCollectionStore.findById('events', id);
      if (doc == null || doc['deletedAt'] != null) return null;
      return EventModel.fromMap(doc);
    }
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
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('events', 'id', event.toMap());
      return;
    }
    final db = await _db;
    await db.insert('events', event.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.upsert('events', 'id', event.toMap());
      return;
    }
    final db = await _db;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(String id) async {
    final now = DateTime.now().toIso8601String();
    final fields = {'deletedAt': now, 'updatedAt': now};
    if (await DataModeService.instance.isOnline) {
      await MongoCollectionStore.updateFields('events', id, fields);
      return;
    }
    final db = await _db;
    await db.update(
      'events',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
