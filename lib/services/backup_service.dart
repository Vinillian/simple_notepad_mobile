import 'dart:convert';
import 'dart:io';
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
        'notes': notes.map((n) {
          final noteMap = n.toJson();
          return {
            'id': noteMap['id'],
            'title': noteMap['title'],
            'content': noteMap['content'],
            'category': noteMap['category_id'],
            'date': noteMap['date'],
            'createdTimestamp': noteMap['created_timestamp'],
            'updatedTimestamp': noteMap['updated_timestamp'],
            'expanded': noteMap['expanded'] == 1,
            'editMode': noteMap['edit_mode'] == 1,
            'type': noteMap['type'],
            'metadata': noteMap['metadata'],
          };
        }).toList(),
        'categories': categories.map((c) {
          final catMap = c.toJson();
          return {
            'id': catMap['id'],
            'name': catMap['name'],
            'color': catMap['color'],
            'custom': catMap['custom'] == 1,
          };
        }).toList(),
        'settings': {
          'sortOrder': settings.sortOrder,
          'viewMode': settings.viewMode,
        },
        'exportDate': exportDate.toIso8601String(),
        'version': version,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    print('=== НАЧАЛО ПАРСИНГА JSON ===');
    print('Ключи в корне JSON: ${json.keys.join(', ')}');

    final notesJson = json['notes'] as List? ?? [];
    print('Найдено заметок в JSON: ${notesJson.length}');

    final notes = <Note>[];
    int successCount = 0;
    int errorCount = 0;

    for (var i = 0; i < notesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(notesJson[i] as Map);
        print('\n--- Обработка заметки #$i ---');
        print('  ID: ${map['id']}');
        print('  Title: ${map['title']}');
        print('  Category: ${map['category'] ?? map['category_id']}');
        print('  Content length: ${map['content']?.length ?? 0}');

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
        print('  ✓ УСПЕШНО');
      } catch (e, stackTrace) {
        errorCount++;
        print('  ✗ ОШИБКА: $e');
        print('  StackTrace: $stackTrace');
      }
    }

    print('\n=== ИТОГ ПО ЗАМЕТКАМ ===');
    print('Всего в JSON: ${notesJson.length}');
    print('Успешно обработано: $successCount');
    print('Ошибок: $errorCount');

    final categoriesJson = json['categories'] as List? ?? [];
    print('\n=== КАТЕГОРИИ ===');
    print('Найдено категорий в JSON: ${categoriesJson.length}');

    final categories = <Category>[];
    int catSuccess = 0;
    int catError = 0;

    for (var i = 0; i < categoriesJson.length; i++) {
      try {
        final map = Map<String, dynamic>.from(categoriesJson[i] as Map);
        print('  Категория #$i: ${map['name']} (${map['id']})');

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
        print('  Ошибка категории #$i: $e');
      }
    }

    print('Категорий успешно: $catSuccess, ошибок: $catError');

    final settingsMap = json['settings'] as Map<String, dynamic>? ?? {};
    print('\n=== НАСТРОЙКИ ===');
    print(
        'sortOrder: ${settingsMap['sortOrder'] ?? settingsMap['sort_order']}');
    print('viewMode: ${settingsMap['viewMode'] ?? settingsMap['view_mode']}');

    final sortOrder = settingsMap['sortOrder'] as String? ??
        settingsMap['sort_order'] as String? ??
        'new';
    final viewMode = settingsMap['viewMode'] as String? ??
        settingsMap['view_mode'] as String? ??
        'list';
    final settings = Settings(sortOrder: sortOrder, viewMode: viewMode);

    print('\n=== ФИНАЛЬНЫЙ РЕЗУЛЬТАТ ===');
    print('Заметок: ${notes.length}');
    print('Категорий: ${categories.length}');
    print('Настройки: sort=$sortOrder, view=$viewMode');
    print('=== КОНЕЦ ПАРСИНГА ===\n');

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

    print('\n=== ВЫБРАН ФАЙЛ ===');
    print('Путь: ${result.files.single.path}');
    print('Имя: ${result.files.single.name}');
    print('Размер: ${result.files.single.size} байт');

    final file = File(result.files.single.path!);
    final content = await file.readAsString(encoding: utf8);
    print('Содержимое прочитано, длина: ${content.length} символов');

    try {
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      print('JSON успешно декодирован');
      return BackupData.fromJson(jsonMap);
    } catch (e, stackTrace) {
      print('!!! ОШИБКА ДЕКОДИРОВАНИЯ JSON !!!');
      print('Ошибка: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
