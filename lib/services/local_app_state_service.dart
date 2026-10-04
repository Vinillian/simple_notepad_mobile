import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Stores small app-level flags in the `app_meta` table.
class LocalAppStateService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Key in `app_meta`: whether link previews may be fetched from a
  /// third-party service. A missing value means enabled.
  static const String linkPreviewsKey = 'link_previews_enabled';

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

  /// Previews are on unless the user turned them off.
  static bool previewFlagFromValue(String? value) => value != '0';

  /// Whether link previews may be fetched through api.microlink.io.
  Future<bool> isLinkPreviewEnabled() async {
    return previewFlagFromValue(await _getValue(linkPreviewsKey));
  }

  Future<void> setLinkPreviewEnabled(bool enabled) {
    return _setValue(linkPreviewsKey, enabled ? '1' : '0');
  }
}
