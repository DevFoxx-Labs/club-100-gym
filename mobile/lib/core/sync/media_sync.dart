import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import 'cloud_mapper.dart';
import 'supabase_service.dart';
import 'sync_tables.dart';

class MediaSync {
  static const String scheme = 'sb://gym-media/';
  static const String bucket = 'gym-media';

  /// Mapping from local table name to the local column name that stores media file path.
  static const Map<String, String> mediaColumns = {
    'gym': 'logoPath',
    'members': 'photoPath',
    'trainers': 'photoPath',
    'announcements': 'imagePath',
  };

  /// Uploads local file to Supabase Storage if present, returning a cloud row
  /// where the media column contains 'sb://gym-media/<path>'.
  static Future<Map<String, dynamic>> uploadIfLocal(
    SyncTable table,
    Map<String, dynamic> cloudRow,
    String gymId,
  ) async {
    final col = mediaColumns[table.local];
    if (col == null) return cloudRow;

    final cloudCol = CloudMapper.camelToSnake(col);
    final localPath = cloudRow[cloudCol];
    if (localPath == null || localPath is! String || localPath.isEmpty) {
      return cloudRow;
    }

    // Already a remote URI
    if (localPath.startsWith(scheme)) {
      return cloudRow;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      return cloudRow;
    }

    final rowId = cloudRow[table.isGym ? 'id' : table.key]?.toString() ?? 'item';
    final ext = p.extension(localPath).isEmpty ? '.jpg' : p.extension(localPath);
    final storagePath = '$gymId/${table.local}/$rowId$ext';

    try {
      final client = SupabaseService.instance.client;
      if (client == null) return cloudRow;

      final db = await AppDatabase.instance.database;
      final metaKey = 'media:${table.local}:$rowId';
      final cachedRows = await db.query(
        'sync_meta',
        where: 'key = ? AND value = ?',
        whereArgs: [metaKey, localPath],
        limit: 1,
      );

      if (cachedRows.isEmpty) {
        await client.storage.from(bucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
        await db.insert(
          'sync_meta',
          {'key': metaKey, 'value': localPath},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final copy = Map<String, dynamic>.from(cloudRow);
      copy[cloudCol] = '$scheme$storagePath';
      return copy;
    } catch (e, stackTrace) {
      debugPrint('[MediaSync] Upload error for $localPath: $e\n$stackTrace');
      return cloudRow;
    }
  }

  /// If a downloaded cloud row contains 'sb://gym-media/<path>', downloads the bytes
  /// to local storage and updates the cloud row with the absolute file path before conversion.
  static Future<Map<String, dynamic>> downloadIfRemote(
    SyncTable table,
    Map<String, dynamic> cloudRow,
  ) async {
    final col = mediaColumns[table.local];
    if (col == null) return cloudRow;

    final cloudCol = CloudMapper.camelToSnake(col);
    final val = cloudRow[cloudCol];
    if (val == null || val is! String || !val.startsWith(scheme)) {
      return cloudRow;
    }

    final storagePath = val.substring(scheme.length);
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return cloudRow;

      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(docsDir.path, 'profile_photos'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName = p.basename(storagePath);
      final localTargetFile = File(p.join(targetDir.path, fileName));

      if (!await localTargetFile.exists()) {
        final bytes = await client.storage.from(bucket).download(storagePath);
        await localTargetFile.writeAsBytes(bytes);
      }

      final copy = Map<String, dynamic>.from(cloudRow);
      copy[cloudCol] = localTargetFile.path;
      return copy;
    } catch (e, stackTrace) {
      debugPrint('[MediaSync] Download failed for $storagePath: $e\n$stackTrace');
      final copy = Map<String, dynamic>.from(cloudRow);
      copy[cloudCol] = null;
      return copy;
    }
  }
}

