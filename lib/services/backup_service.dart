import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/settings.dart';

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
      foundation.debugPrint('=== НАЧАЛО ПАРСИНГА JSON ===');
      foundation.debugPrint('Ключи в корне JSON: ${json.keys.join(', ')}');
    }

    final notesJson = json['notes'] as List? ?? [];
    if (foundation.kDebugMode) {
      foundation.debugPrint('Найдено заметок в JSON: ${notesJson.length}');
    }

    final notes = <Note>[];
    int successCount = 0;
    int errorCount = 0;

    for (var i = 0; i < notesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(notesJson[i] as Map);
        if (foundation.kDebugMode) {
          foundation.debugPrint('\n--- Обработка заметки #$i ---');
          foundation.debugPrint('  ID: ${map['id']}');
          foundation.debugPrint('  Title: ${map['title']}');
          foundation.debugPrint('  Category: ${map['category'] ?? map['category_id']}');
          foundation.debugPrint('  Content length: ${map['content']?.length ?? 0}');
        }

        // id -> double
        map['id'] = map['id'] != null
            ? (map['id'] as num).toDouble()
            : DateTime.now().millisecondsSinceEpoch.toDouble();

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
        if (foundation.kDebugMode) foundation.debugPrint('  ✓ УСПЕШНО');
      } catch (e, stackTrace) {
        errorCount++;
        if (foundation.kDebugMode) {
          foundation.debugPrint('  ✗ ОШИБКА: $e');
          foundation.debugPrint('  StackTrace: $stackTrace');
        }
      }
    }

    if (foundation.kDebugMode) {
      foundation.debugPrint('\n=== ИТОГ ПО ЗАМЕТКАМ ===');
      foundation.debugPrint('Всего в JSON: ${notesJson.length}');
      foundation.debugPrint('Успешно обработано: $successCount');
      foundation.debugPrint('Ошибок: $errorCount');
    }

    final categoriesJson = json['categories'] as List? ?? [];
    if (foundation.kDebugMode) {
      foundation.debugPrint('\n=== КАТЕГОРИИ ===');
      foundation.debugPrint('Найдено категорий в JSON: ${categoriesJson.length}');
    }

    final categories = <Category>[];
    int catSuccess = 0;
    int catError = 0;

    for (var i = 0; i < categoriesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(categoriesJson[i] as Map);
        if (foundation.kDebugMode) {
          foundation.debugPrint('  Категория #$i: ${map['name']} (${map['id']})');
        }

        if (map['id'] == null) {
          map['id'] = 'cat_${DateTime.now().millisecondsSinceEpoch}_$i';
        }
        if (map['name'] == null) {
          map['name'] = 'Без названия';
        }
        if (map['color'] == null) {
          map['color'] = '#4CAF50';
        }
        if (map['custom'] is bool) {
          map['custom'] = (map['custom'] as bool) ? 1 : 0;
        } else if (map['custom'] == null) {
          map['custom'] = 0;
        }

        categories.add(Category.fromJson(map));
        catSuccess++;
      } catch (e) {
        catError++;
        if (foundation.kDebugMode) foundation.debugPrint('  Ошибка категории #$i: $e');
      }
    }

    if (foundation.kDebugMode) {
      foundation.debugPrint('Категорий успешно: $catSuccess, ошибок: $catError');
    }

    final settingsMap = json['settings'] as Map<String, dynamic>? ?? {};
    if (foundation.kDebugMode) {
      foundation.debugPrint('\n=== НАСТРОЙКИ ===');
      foundation.debugPrint(
          'sortOrder: ${settingsMap['sortOrder'] ?? settingsMap['sort_order']}');
      foundation.debugPrint('viewMode: ${settingsMap['viewMode'] ?? settingsMap['view_mode']}');
    }

    final sortOrder = settingsMap['sortOrder'] as String? ??
        settingsMap['sort_order'] as String? ??
        'new';
    final viewMode = settingsMap['viewMode'] as String? ??
        settingsMap['view_mode'] as String? ??
        'list';
    final settings = Settings(sortOrder: sortOrder, viewMode: viewMode);

    if (foundation.kDebugMode) {
      foundation.debugPrint('\n=== ФИНАЛЬНЫЙ РЕЗУЛЬТАТ ===');
      foundation.debugPrint('Заметок: ${notes.length}');
      foundation.debugPrint('Категорий: ${categories.length}');
      foundation.debugPrint('Настройки: sort=$sortOrder, view=$viewMode');
      foundation.debugPrint('=== КОНЕЦ ПАРСИНГА ===\n');
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
  static Future<String> exportBackup({
    required List<Note> notes,
    required List<Category> categories,
    required Settings settings,
  }) async {
    final backup = BackupData(
      notes: notes,
      categories: categories,
      settings: settings,
    );

    final jsonString = jsonEncode(backup.toJson());

    final directory = await getTemporaryDirectory();
    final fileName =
        'notebook_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(jsonString, encoding: utf8);
    return file.path;
  }

  static Future<BackupData?> pickAndParseBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return null;

    if (foundation.kDebugMode) {
      foundation.debugPrint('\n=== ВЫБРАН ФАЙЛ ===');
      foundation.debugPrint('Путь: ${result.files.single.path}');
      foundation.debugPrint('Имя: ${result.files.single.name}');
      foundation.debugPrint('Размер: ${result.files.single.size} байт');
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString(encoding: utf8);
    if (foundation.kDebugMode) {
      foundation.debugPrint('Содержимое прочитано, длина: ${content.length} символов');
    }

    try {
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      if (foundation.kDebugMode) foundation.debugPrint('JSON успешно декодирован');
      return BackupData.fromJson(jsonMap);
    } catch (e, stackTrace) {
      if (foundation.kDebugMode) {
        foundation.debugPrint('!!! ОШИБКА ДЕКОДИРОВАНИЯ JSON !!!');
        foundation.debugPrint('Ошибка: $e');
        foundation.debugPrint('StackTrace: $stackTrace');
      }
      rethrow;
    }
  }
}