import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_elite_fitness/core/sync/sync_schema.dart';
import 'package:the_elite_fitness/core/sync/sync_tables.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SyncSchema', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // Create all tables defined in SyncTables
      for (final t in SyncTables.all) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${t.local} (
            "${t.key}" TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT
          )
        ''');
      }

      await SyncSchema.ensure(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Trigger captures INSERT as upsert in sync_outbox', () async {
      await db.insert('members', {
        'id': 'm1',
        'name': 'Alice',
        'phone': '9998887770',
      });

      final outbox = await db.query('sync_outbox');
      expect(outbox.length, 1);
      expect(outbox.first['tableName'], 'members');
      expect(outbox.first['rowKey'], 'm1');
      expect(outbox.first['op'], 'upsert');
    });

    test('Trigger captures UPDATE as upsert in sync_outbox', () async {
      await db.insert('members', {
        'id': 'm1',
        'name': 'Alice',
        'phone': '9998887770',
      });

      await db.update(
        'members',
        {'name': 'Alice Updated'},
        where: 'id = ?',
        whereArgs: ['m1'],
      );

      final outbox = await db.query('sync_outbox');
      expect(outbox.length, 2);
      expect(outbox.last['tableName'], 'members');
      expect(outbox.last['rowKey'], 'm1');
      expect(outbox.last['op'], 'upsert');
    });

    test('Trigger captures DELETE as delete in sync_outbox', () async {
      await db.insert('members', {
        'id': 'm1',
        'name': 'Alice',
        'phone': '9998887770',
      });

      await db.delete(
        'members',
        where: 'id = ?',
        whereArgs: ['m1'],
      );

      final outbox = await db.query('sync_outbox');
      expect(outbox.length, 2);
      expect(outbox.last['tableName'], 'members');
      expect(outbox.last['rowKey'], 'm1');
      expect(outbox.last['op'], 'delete');
    });

    test('SyncSchema.muted prevents outbox generation during remote pull', () async {
      await db.transaction((txn) async {
        await SyncSchema.muted(txn, () async {
          await txn.insert('members', {
            'id': 'm_remote',
            'name': 'Remote User',
            'phone': '1112223330',
          });
        });
      });

      final outbox = await db.query('sync_outbox');
      expect(outbox.isEmpty, isTrue);

      final members = await db.query('members');
      expect(members.length, 1);
      expect(members.first['id'], 'm_remote');
    });

    test('SyncSchema.wipeLocalData clears tables and outbox without creating delete records', () async {
      await db.insert('members', {
        'id': 'm1',
        'name': 'Alice',
        'phone': '9998887770',
      });

      final outboxBefore = await db.query('sync_outbox');
      expect(outboxBefore.length, 1);

      await SyncSchema.wipeLocalData(db);

      final membersAfter = await db.query('members');
      expect(membersAfter.isEmpty, isTrue);

      final outboxAfter = await db.query('sync_outbox');
      expect(outboxAfter.isEmpty, isTrue);
    });
  });
}
