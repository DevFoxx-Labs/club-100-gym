import 'sync_tables.dart';

/// Converts rows between the local SQLite shape (camelCase columns, gym row
/// id = 'default') and the Supabase shape (snake_case columns, every row
/// tagged with gym_id, gym row keyed by its cloud UUID).
class CloudMapper {
  static const _cloudOnlyColumns = {'gym_id', 'owner_id', 'is_deleted', 'server_updated_at'};
  static const localGymRowId = 'default';

  static Map<String, dynamic> toCloud(
    SyncTable table,
    Map<String, Object?> localRow, {
    required String gymId,
    required String ownerId,
  }) {
    final map = <String, dynamic>{};
    localRow.forEach((k, v) => map[camelToSnake(k)] = v);
    if (table.isGym) {
      map['id'] = gymId;
      map['owner_id'] = ownerId;
    } else {
      map['gym_id'] = gymId;
    }
    map['is_deleted'] = false;
    return map;
  }

  /// [localColumns] is the set of columns that actually exist in the local
  /// table (from PRAGMA table_info); unknown cloud columns are dropped so a
  /// newer cloud schema can never break inserts on an older app version.
  static Map<String, Object?> toLocal(
    SyncTable table,
    Map<String, dynamic> cloudRow,
    Set<String> localColumns,
  ) {
    final map = <String, Object?>{};
    cloudRow.forEach((k, v) {
      if (_cloudOnlyColumns.contains(k)) return;
      final localKey = snakeToCamel(k);
      if (localColumns.contains(localKey)) map[localKey] = v;
    });
    if (table.isGym) map['id'] = localGymRowId;
    return map;
  }

  static String camelToSnake(String camel) =>
      camel.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');

  static String snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length <= 1) return snake;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }
}

