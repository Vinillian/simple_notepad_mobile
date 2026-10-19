import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Where the custom server address is kept. Implemented by
/// [LocalAppStateService]; tests substitute an in-memory version.
abstract class ServerUrlStorage {
  /// The saved server address, or `null` if the default is used.
  Future<String?> getServerUrl();

  /// Saves [url]; `null` removes the saved value (back to the default).
  Future<void> setServerUrl(String? url);
}

/// Stores small app-level flags in the `app_meta` table.
class LocalAppStateService implements ServerUrlStorage {
  /// Key in the `app_meta` table for the custom server address.
  static const String serverUrlKey = 'server_url';

  /// Key in the `app_meta` table that is set while local changes may not have
  /// reached the server yet.
  static const String syncPendingKey = 'sync_pending';

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

  Future<void> _deleteValue(String key) async {
    final db = await _dbHelper.database;
    await db.delete('app_meta', where: 'key = ?', whereArgs: [key]);
  }

  /// Whether the first-run setup (welcome screen) has been completed.
  Future<bool> isSetupComplete() async {
    return await _getValue(DatabaseHelper.setupCompleteKey) == '1';
  }

  Future<void> markSetupComplete() {
    return _setValue(DatabaseHelper.setupCompleteKey, '1');
  }

  @override
  Future<String?> getServerUrl() async {
    final value = await _getValue(serverUrlKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> setServerUrl(String? url) {
    if (url == null || url.isEmpty) return _deleteValue(serverUrlKey);
    return _setValue(serverUrlKey, url);
  }

  /// Whether a change could not be sent to the server, or a sync failed, and
  /// no sync has succeeded since.
  Future<bool> isSyncPending() async {
    return await _getValue(syncPendingKey) == '1';
  }

  Future<void> setSyncPending(bool pending) {
    return pending ? _setValue(syncPendingKey, '1') : _deleteValue(syncPendingKey);
  }
}
