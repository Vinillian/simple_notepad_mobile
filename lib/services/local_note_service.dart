import 'package:sqflite/sqflite.dart';
import '../models/note.dart';
import '../utils/sync_planner.dart';
import 'database_helper.dart';

class LocalNoteService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// How long a deletion is kept (as a tombstone) so that it can still be
  /// sent to the other side of the sync.
  static const Duration tombstoneRetention = Duration(days: 30);

  Future<List<Note>> getNotes({String? category, String sort = 'new'}) async {
    final db = await _dbHelper.database;
    String orderBy =
        sort == 'new' ? 'updated_timestamp DESC' : 'updated_timestamp ASC';
    var where = 'deleted = 0';
    final whereArgs = <Object?>[];
    if (category != null && category != 'all') {
      where += ' AND category_id = ?';
      whereArgs.add(category);
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<Note?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    }
    return null;
  }

  Future<void> createNote(Note note) async {
    final db = await _dbHelper.database;
    await db.insert(
      'notes',
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await _dbHelper.database;
    await db.update(
      'notes',
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Marks the note as deleted instead of removing the row, so that the
  /// deletion can be synced. The note disappears from every list.
  Future<void> deleteNote(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notes',
      {
        'deleted': 1,
        'updated_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Id, change time and deletion flag of every note, tombstones included.
  Future<List<SyncEntry>> getSyncEntries() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notes',
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

  /// Removes tombstones older than [tombstoneRetention]. Returns how many.
  Future<int> purgeTombstones({DateTime? now}) async {
    final db = await _dbHelper.database;
    final limit = (now ?? DateTime.now())
        .subtract(tombstoneRetention)
        .millisecondsSinceEpoch;
    return db.delete(
      'notes',
      where: 'deleted = 1 AND updated_timestamp < ?',
      whereArgs: [limit],
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('notes');
  }

  Future<void> insertAll(List<Note> notes) async {
    final db = await _dbHelper.database;
    Batch batch = db.batch();
    for (var note in notes) {
      batch.insert(
        'notes',
        note.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }
}
