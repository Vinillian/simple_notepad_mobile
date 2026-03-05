import 'package:sqflite/sqflite.dart';
import '../models/note.dart';
import 'database_helper.dart';

class LocalNoteService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Note>> getNotes({String? category, String sort = 'new'}) async {
    final db = await _dbHelper.database;
    String orderBy =
        sort == 'new' ? 'updated_timestamp DESC' : 'updated_timestamp ASC';
    String? where;
    List<dynamic>? whereArgs;
    if (category != null && category != 'all') {
      where = 'category_id = ?';
      whereArgs = [category];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<Note?> getNoteById(double id) async {
    // double
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
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

  Future<void> deleteNote(double id) async {
    // double
    final db = await _dbHelper.database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
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
