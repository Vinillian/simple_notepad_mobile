import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Stores small app-level flags in the `app_meta` table.
class LocalAppStateService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String?> _getValue(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _setValue(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Whether the first-run setup (welcome screen) has been completed.
  Future<bool> isSetupComplete() async {
    return await _getValue(DatabaseHelper.setupCompleteKey) == '1';
  }

  Future<void> markSetupComplete() {
    return _setValue(DatabaseHelper.setupCompleteKey, '1');
  }
}
