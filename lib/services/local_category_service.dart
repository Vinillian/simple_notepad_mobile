import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../utils/sync_planner.dart';
import 'database_helper.dart';
import 'local_note_service.dart';

class LocalCategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    // rowid is the order in which the categories were created. Rows are
    // updated in place, never deleted and inserted again, so a category
    // keeps its place in the list when it is renamed or recoloured.
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'deleted = 0',
      orderBy: 'rowid',
    );
    return List.generate(maps.length, (i) {
      return Category.fromJson(maps[i]);
    });
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );
    return maps.isEmpty ? null : Category.fromJson(maps.first);
  }

  /// Saves the category (a deleted one with the same id is brought back) and
  /// returns its change time: [updatedAt], or now.
  Future<int> createCategory(Category category, {int? updatedAt}) async {
    final db = await _dbHelper.database;
    final time = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'categories',
      {...category.toJson(), 'updated_timestamp': time, 'deleted': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return time;
  }

  /// Saves the new name and colour of a category and returns its change time.
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    final time = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'categories',
      {...category.toJson(), 'updated_timestamp': time},
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return time;
  }

  /// Marks the category as deleted instead of removing the row, so that the
  /// deletion can be synced. The category disappears from every list.
  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {
        'deleted': 1,
        'updated_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Sets the change time of a category without touching anything else.
  Future<void> setUpdatedTimestamp(String id, int time) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'updated_timestamp': time},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Id, change time and deletion flag of every category, tombstones included.
  Future<List<SyncEntry>> getSyncEntries() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'categories',
      columns: ['id', 'updated_timestamp', 'deleted'],
    );
    return [
      for (final row in rows)
        SyncEntry(
          row['id'] as String,
          (row['updated_timestamp'] as num).toInt(),
          deleted: (row['deleted'] as num).toInt() == 1,
        ),
    ];
  }

  /// Whether the category still has notes that are not deleted.
  Future<bool> hasLiveNotes(String id) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notes WHERE category_id = ? AND deleted = 0',
        [id],
      ),
    );
    return (count ?? 0) > 0;
  }

  /// Removes tombstones older than [LocalNoteService.tombstoneRetention].
  /// Returns how many.
  Future<int> purgeTombstones({DateTime? now}) async {
    final db = await _dbHelper.database;
    final limit = (now ?? DateTime.now())
        .subtract(LocalNoteService.tombstoneRetention)
        .millisecondsSinceEpoch;
    return db.delete(
      'categories',
      where: 'deleted = 1 AND updated_timestamp < ?',
      whereArgs: [limit],
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('categories');
  }

  /// Saves categories that come from the server. [updatedAt] holds the change
  /// time to keep for each id; a category without one gets the current time.
  ///
  /// A category that is already here is updated in place (a deleted one is
  /// brought back), so it keeps its place in the list; only a new id adds a
  /// row.
  Future<void> insertAll(
    List<Category> categories, {
    Map<String, int>? updatedAt,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (final cat in categories) {
        final values = {
          ...cat.toJson(),
          'updated_timestamp': updatedAt?[cat.id] ?? now,
          'deleted': 0,
        };
        final updated = await txn.update(
          'categories',
          values,
          where: 'id = ?',
          whereArgs: [cat.id],
        );
        if (updated == 0) await txn.insert('categories', values);
      }
    });
  }
}
