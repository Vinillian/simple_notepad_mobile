import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as foundation;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/settings.dart';
import '../utils/helpers.dart';
import '../utils/note_id.dart';

/// Detailed backup parsing log. Off by default so that `flutter test` and
/// normal runs stay quiet; turn it on with
/// `--dart-define=BACKUP_VERBOSE=true`.
const bool _verboseBackupLog = bool.fromEnvironment('BACKUP_VERBOSE');

void _log(String message) {
  if (_verboseBackupLog) foundation.debugPrint(message);
}

class BackupData {
  final List<Note> notes;
  final List<Category> categories;
  final Settings settings;
  final DateTime exportDate;
  final String version;

  BackupData({
    required this.notes,
    required this.categories,
    required this.settings,
    DateTime? exportDate,
    this.version = '1.0',
  }) : exportDate = exportDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'notes': notes.map((n) => n.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'settings': settings.toJson(),
    'exportDate': exportDate.toIso8601String(),
    'version': version,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    if (foundation.kDebugMode) {
      _log('=== НАЧАЛО ПАРСИНГА JSON ===');
      _log('Ключи в корне JSON: ${json.keys.join(', ')}');
    }

    final notesJson = json['notes'] as List? ?? [];
    if (foundation.kDebugMode) {
      _log('Найдено заметок в JSON: ${notesJson.length}');
    }

    final notes = <Note>[];
    int successCount = 0;
    int errorCount = 0;

    for (var i = 0; i < notesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(notesJson[i] as Map);
        if (foundation.kDebugMode) {
          _log('\n--- Обработка заметки #$i ---');
          _log('  ID: ${map['id']}');
          _log('  Title: ${map['title']}');
          _log('  Category: ${map['category'] ?? map['category_id']}');
          _log('  Content length: ${map['content']?.length ?? 0}');
        }

        // id -> string (a numeric id keeps its exact value as text)
        map['id'] =
            map['id'] != null ? noteIdFromValue(map['id']) : generateNoteId();

        // created_timestamp
        if (map.containsKey('createdTimestamp')) {
          map['created_timestamp'] = (map['createdTimestamp'] as num).toInt();
        } else if (map.containsKey('created_timestamp')) {
          map['created_timestamp'] = (map['created_timestamp'] as num).toInt();
        } else {
          map['created_timestamp'] = DateTime.now().millisecondsSinceEpoch;
        }

        // updated_timestamp
        if (map.containsKey('updatedTimestamp')) {
          map['updated_timestamp'] = (map['updatedTimestamp'] as num).toInt();
        } else if (map.containsKey('updated_timestamp')) {
          map['updated_timestamp'] = (map['updated_timestamp'] as num).toInt();
        } else {
          map['updated_timestamp'] = DateTime.now().millisecondsSinceEpoch;
        }

        // category -> category_id
        if (map.containsKey('category')) {
          map['category_id'] = map['category'];
        }
        if (map['category_id'] == null) {
          map['category_id'] = 'default';
        }

        // expanded
        if (map['expanded'] is bool) {
          map['expanded'] = (map['expanded'] as bool) ? 1 : 0;
        } else if (map['expanded'] == null) {
          map['expanded'] = 0;
        }

        // editMode -> edit_mode
        if (map.containsKey('editMode')) {
          map['edit_mode'] = map['editMode'] is bool
              ? ((map['editMode'] as bool) ? 1 : 0)
              : (map['editMode'] as num?)?.toInt() ?? 0;
        }
        if (map['edit_mode'] == null) {
          map['edit_mode'] = 0;
        }

        // type
        if (map['type'] == null) {
          map['type'] = 'note';
        }

        // content
        if (map['content'] == null) {
          map['content'] = '';
        }

        // date
        if (map['date'] == null) {
          final now = DateTime.now();
          map['date'] =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        }

        notes.add(Note.fromJson(map));
        successCount++;
        if (foundation.kDebugMode) _log('  ✓ УСПЕШНО');
      } catch (e, stackTrace) {
        errorCount++;
        if (foundation.kDebugMode) {
          _log('  ✗ ОШИБКА: $e');
          _log('  StackTrace: $stackTrace');
        }
      }
    }

    if (foundation.kDebugMode) {
      _log('\n=== ИТОГ ПО ЗАМЕТКАМ ===');
      _log('Всего в JSON: ${notesJson.length}');
      _log('Успешно обработано: $successCount');
      _log('Ошибок: $errorCount');
    }

    final categoriesJson = json['categories'] as List? ?? [];
    if (foundation.kDebugMode) {
      _log('\n=== КАТЕГОРИИ ===');
      _log('Найдено категорий в JSON: ${categoriesJson.length}');
    }

    final categories = <Category>[];
    int catSuccess = 0;
    int catError = 0;

    for (var i = 0; i < categoriesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(categoriesJson[i] as Map);
        if (foundation.kDebugMode) {
          _log('  Категория #$i: ${map['name']} (${map['id']})');
        }

        if (map['id'] == null) {
          map['id'] = 'cat_${DateTime.now().millisecondsSinceEpoch}_$i';
        }
        if (map['name'] == null) {
          map['name'] = 'Без названия';
        }
        // Fall back to the default green if the color is missing or malformed.
        map['color'] = normalizeHexColor(map['color']?.toString()) ?? '#4CAF50';
        if (map['custom'] is bool) {
          map['custom'] = (map['custom'] as bool) ? 1 : 0;
        } else if (map['custom'] == null) {
          map['custom'] = 0;
        }

        categories.add(Category.fromJson(map));
        catSuccess++;
      } catch (e) {
        catError++;
        if (foundation.kDebugMode) _log('  Ошибка категории #$i: $e');
      }
    }

    if (foundation.kDebugMode) {
      _log('Категорий успешно: $catSuccess, ошибок: $catError');
    }

    final settingsMap = json['settings'] as Map<String, dynamic>? ?? {};
    if (foundation.kDebugMode) {
      _log('\n=== НАСТРОЙКИ ===');
      _log(
          'sortOrder: ${settingsMap['sortOrder'] ?? settingsMap['sort_order']}');
      _log('viewMode: ${settingsMap['viewMode'] ?? settingsMap['view_mode']}');
    }

    final sortOrder = settingsMap['sortOrder'] as String? ??
        settingsMap['sort_order'] as String? ??
        'new';
    final viewMode = settingsMap['viewMode'] as String? ??
        settingsMap['view_mode'] as String? ??
        'list';
    final settings = Settings(sortOrder: sortOrder, viewMode: viewMode);

    if (foundation.kDebugMode) {
      _log('\n=== ФИНАЛЬНЫЙ РЕЗУЛЬТАТ ===');
      _log('Заметок: ${notes.length}');
      _log('Категорий: ${categories.length}');
      _log('Настройки: sort=$sortOrder, view=$viewMode');
      _log('=== КОНЕЦ ПАРСИНГА ===\n');
    }

    return BackupData(
      notes: notes,
      categories: categories,
      settings: settings,
      exportDate: DateTime.parse(
          json['exportDate'] as String? ?? DateTime.now().toIso8601String()),
      version: json['version'] as String? ?? '1.0',
    );
  }
}

class BackupService {
  /// File name for a new backup, e.g. `notebook_backup_2026-10-09T19-05-03.json`.
  static String backupFileName([DateTime? now]) {
    final stamp = (now ?? DateTime.now())
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    return 'notebook_backup_$stamp.json';
  }

  /// The backup contents as a JSON string.
  static String encodeBackup({
    required List<Note> notes,
    required List<Category> categories,
    required Settings settings,
  }) {
    final backup = BackupData(
      notes: notes,
      categories: categories,
      settings: settings,
    );
    return jsonEncode(backup.toJson());
  }

  /// Writes a backup to the temporary directory and returns its path.
  /// Used for sharing; the file is not meant to be kept there.
  static Future<String> exportBackup({
    required List<Note> notes,
    required List<Category> categories,
    required Settings settings,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${backupFileName()}');
    await file.writeAsString(
      encodeBackup(notes: notes, categories: categories, settings: settings),
      encoding: utf8,
    );
    return file.path;
  }

  /// Opens the system "save as" dialog so the user picks the folder (and may
  /// change the name). Returns the saved path, or `null` if cancelled.
  static Future<String?> saveBackupToChosenLocation({
    required List<Note> notes,
    required List<Category> categories,
    required Settings settings,
  }) {
    final bytes = Uint8List.fromList(
      utf8.encode(
        encodeBackup(notes: notes, categories: categories, settings: settings),
      ),
    );
    return FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить резервную копию',
      fileName: backupFileName(),
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  static Future<BackupData?> pickAndParseBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return null;

    if (foundation.kDebugMode) {
      _log('\n=== ВЫБРАН ФАЙЛ ===');
      _log('Путь: ${result.files.single.path}');
      _log('Имя: ${result.files.single.name}');
      _log('Размер: ${result.files.single.size} байт');
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString(encoding: utf8);
    if (foundation.kDebugMode) {
      _log('Содержимое прочитано, длина: ${content.length} символов');
    }

    try {
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      if (foundation.kDebugMode) _log('JSON успешно декодирован');
      return BackupData.fromJson(jsonMap);
    } catch (e, stackTrace) {
      if (foundation.kDebugMode) {
        _log('!!! ОШИБКА ДЕКОДИРОВАНИЯ JSON !!!');
        _log('Ошибка: $e');
        _log('StackTrace: $stackTrace');
      }
      rethrow;
    }
  }
}