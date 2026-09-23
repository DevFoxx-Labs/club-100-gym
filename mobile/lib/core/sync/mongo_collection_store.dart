import 'mongo_connection_service.dart';

/// Generic MongoDB-backed CRUD helper used by every repository's Online-mode
/// code path.
///
/// A single gym's dataset is small (hundreds to low-thousands of rows), so
/// reads simply pull the relevant collection into memory and filter/sort in
/// Dart — mirroring exactly the same logic the SQLite `where`/`ORDER BY`
/// clauses already perform for the Offline path, instead of re-deriving new
/// MongoDB query-language semantics per call site (which would double the
/// surface area for subtle behavioral drift between the two modes).
///
/// Every document's Mongo `_id` is set to the row's own primary key value
/// (matching [SyncMigrationService]'s convention), and every write is an
/// upsert keyed on that id — so writes are always idempotent and can never
/// create duplicates, matching sqflite's `ConflictAlgorithm.replace` used
/// throughout the offline repositories.
class MongoCollectionStore {
  /// All documents in [collection], with Mongo's internal `_id` stripped so
  /// the map matches the exact shape SQLite rows already produce for the
  /// models' `fromMap`.
  static Future<List<Map<String, dynamic>>> all(String collection) async {
    final db = await MongoConnectionService.instance.getActiveDb();
    final docs = await db.collection(collection).find().toList();
    return docs.map(_strip).toList();
  }

  static Map<String, dynamic> _strip(Map<String, dynamic> doc) {
    final map = Map<String, dynamic>.from(doc);
    map.remove('_id');
    return map;
  }

  static Future<Map<String, dynamic>?> findById(String collection, dynamic id) async {
    if (id == null) return null;
    final db = await MongoConnectionService.instance.getActiveDb();
    final doc = await db.collection(collection).findOne({'_id': id});
    return doc == null ? null : _strip(doc);
  }

  static Future<void> upsert(String collection, String idField, Map<String, dynamic> data) async {
    final db = await MongoConnectionService.instance.getActiveDb();
    final id = data[idField];
    final doc = Map<String, dynamic>.from(data);
    doc['_id'] = id;
    await db.collection(collection).replaceOne({'_id': id}, doc, upsert: true);
  }

  static Future<void> updateFields(String collection, dynamic id, Map<String, dynamic> fields) async {
    final db = await MongoConnectionService.instance.getActiveDb();
    await db.collection(collection).updateOne({'_id': id}, {r'$set': fields});
  }

  /// Applies a partial field update to every document matching [predicate]
  /// (evaluated in memory), mirroring a SQL `UPDATE ... WHERE`.
  static Future<int> updateWhere(
    String collection,
    bool Function(Map<String, dynamic> doc) predicate,
    Map<String, dynamic> fields, {
    String idField = 'id',
  }) async {
    final docs = await all(collection);
    var count = 0;
    for (final doc in docs) {
      if (predicate(doc)) {
        await updateFields(collection, doc[idField], fields);
        count++;
      }
    }
    return count;
  }

  static Future<void> deleteById(String collection, dynamic id) async {
    final db = await MongoConnectionService.instance.getActiveDb();
    await db.collection(collection).deleteOne({'_id': id});
  }

  static Future<int> deleteWhere(
    String collection,
    bool Function(Map<String, dynamic> doc) predicate, {
    String idField = 'id',
  }) async {
    final docs = await all(collection);
    var count = 0;
    for (final doc in docs) {
      if (predicate(doc)) {
        await deleteById(collection, doc[idField]);
        count++;
      }
    }
    return count;
  }

  static Future<void> deleteAll(String collection) async {
    final db = await MongoConnectionService.instance.getActiveDb();
    await db.collection(collection).deleteMany({});
  }
}
