import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/core/sync/cloud_mapper.dart';
import 'package:the_elite_fitness/core/sync/sync_tables.dart';

void main() {
  group('CloudMapper', () {
    test('camelToSnake converts identifiers correctly', () {
      expect(CloudMapper.camelToSnake('customPlanPrice'), 'custom_plan_price');
      expect(CloudMapper.camelToSnake('memberId'), 'member_id');
      expect(CloudMapper.camelToSnake('id'), 'id');
      expect(CloudMapper.camelToSnake('createdAt'), 'created_at');
    });

    test('snakeToCamel converts identifiers correctly', () {
      expect(CloudMapper.snakeToCamel('custom_plan_price'), 'customPlanPrice');
      expect(CloudMapper.snakeToCamel('member_id'), 'memberId');
      expect(CloudMapper.snakeToCamel('id'), 'id');
      expect(CloudMapper.snakeToCamel('created_at'), 'createdAt');
    });

    test('toCloud converts member row and injects gym_id', () {
      final memberTable = SyncTables.all.firstWhere((t) => t.local == 'members');
      final local = {
        'id': 'm123',
        'name': 'John Doe',
        'phone': '9876543210',
        'joinedDate': '2026-01-01',
      };

      final cloud = CloudMapper.toCloud(
        memberTable,
        local,
        gymId: 'gym-uuid-1',
        ownerId: 'owner-uuid-1',
      );

      expect(cloud['id'], 'm123');
      expect(cloud['name'], 'John Doe');
      expect(cloud['phone'], '9876543210');
      expect(cloud['joined_date'], '2026-01-01');
      expect(cloud['gym_id'], 'gym-uuid-1');
      expect(cloud['is_deleted'], false);
    });

    test('toCloud converts gym row and replaces id with gym UUID', () {
      final gymTable = SyncTables.all.firstWhere((t) => t.local == 'gym');
      final local = {
        'id': 'default',
        'name': 'Elite Fitness Gym',
        'phone': '9876543210',
      };

      final cloud = CloudMapper.toCloud(
        gymTable,
        local,
        gymId: 'gym-uuid-999',
        ownerId: 'owner-uuid-888',
      );

      expect(cloud['id'], 'gym-uuid-999');
      expect(cloud['owner_id'], 'owner-uuid-888');
      expect(cloud['name'], 'Elite Fitness Gym');
      expect(cloud['is_deleted'], false);
      expect(cloud.containsKey('gym_id'), false);
    });

    test('toLocal converts snake_case and filters out unknown columns', () {
      final memberTable = SyncTables.all.firstWhere((t) => t.local == 'members');
      final cloud = {
        'id': 'm123',
        'gym_id': 'gym-uuid-1',
        'name': 'John Doe',
        'joined_date': '2026-01-01',
        'is_deleted': false,
        'server_updated_at': '2026-09-29T10:00:00Z',
        'future_unknown_column': 'some_val',
      };

      final localCols = {'id', 'name', 'joinedDate'};
      final local = CloudMapper.toLocal(memberTable, cloud, localCols);

      expect(local['id'], 'm123');
      expect(local['name'], 'John Doe');
      expect(local['joinedDate'], '2026-01-01');
      expect(local.containsKey('gym_id'), false);
      expect(local.containsKey('is_deleted'), false);
      expect(local.containsKey('future_unknown_column'), false);
      expect(local.containsKey('futureUnknownColumn'), false);
    });

    test('toLocal rewrites gym table id back to default', () {
      final gymTable = SyncTables.all.firstWhere((t) => t.local == 'gym');
      final cloud = {
        'id': 'gym-uuid-999',
        'owner_id': 'owner-uuid-888',
        'name': 'Elite Fitness Gym',
        'phone': '9876543210',
      };

      final localCols = {'id', 'name', 'phone'};
      final local = CloudMapper.toLocal(gymTable, cloud, localCols);

      expect(local['id'], 'default');
      expect(local['name'], 'Elite Fitness Gym');
      expect(local['phone'], '9876543210');
    });
  });
}

