import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Key in the `app_meta` table that marks the first-run setup as done.
  static const String setupCompleteKey = 'setup_complete';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'notepad.db');
    return await openDatabase(
      path,
      version: 3, // v3: добавлена таблица app_meta
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        custom INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id REAL PRIMARY KEY,
        title TEXT,
        content TEXT NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        created_timestamp INTEGER NOT NULL,
        updated_timestamp INTEGER NOT NULL,
        expanded INTEGER NOT NULL,
        edit_mode INTEGER NOT NULL,
        type TEXT NOT NULL,
        metadata TEXT,
        preview_text TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY DEFAULT 1,
        sort_order TEXT NOT NULL,
        view_mode TEXT NOT NULL
      )
    ''');

    await _createAppMetaTable(db);
  }

  Future<void> _createAppMetaTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем поле preview_text, если его нет
      await db.execute('ALTER TABLE notes ADD COLUMN preview_text TEXT');
    }
    if (oldVersion < 3) {
      await _createAppMetaTable(db);
      // Existing installs that already have categories have finished setup.
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories'),
      );
      if ((count ?? 0) > 0) {
        await db.insert(
          'app_meta',
          {'key': setupCompleteKey, 'value': '1'},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
