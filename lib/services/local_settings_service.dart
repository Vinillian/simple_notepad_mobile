// import 'package:sqflite/sqflite.dart'; // убран неиспользуемый импорт
import 'database_helper.dart';
import '../models/settings.dart';

class LocalSettingsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Settings> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('settings', limit: 1);
    if (maps.isEmpty) {
      // Если нет настроек, создаём по умолчанию
      final defaultSettings = Settings(sortOrder: 'new', viewMode: 'list');
      await db.insert('settings', defaultSettings.toJson());
      return defaultSettings;
    }
    return Settings.fromJson(maps.first);
  }

  Future<void> updateSettings(Settings settings) async {
    final db = await _dbHelper.database;
    await db.update(
      'settings',
      settings.toJson(),
      where: 'id = 1',
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('settings');
  }
}
