import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Stores small app-level flags in the `app_meta` table.
class LocalAppStateService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Whether the first-run setup (welcome screen) has been completed.
  Future<bool> isSetupComplete() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [DatabaseHelper.setupCompleteKey],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> markSetupComplete() async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_meta',
      {'key': DatabaseHelper.setupCompleteKey, 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
