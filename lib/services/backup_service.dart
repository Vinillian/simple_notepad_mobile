import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../models/settings.dart';

/// Модель, соответствующая единому формату JSON‑файла (совместимому с веб‑версией).
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

  /// Преобразует данные в унифицированный JSON (веб‑формат).
  Map<String, dynamic> toJson() => {
        'notes': notes.map((n) {
          final noteMap =
              n.toJson(); // содержит category_id, created_timestamp и т.д.
          // Переименовываем и преобразуем типы под веб‑формат
          return {
            'id': noteMap['id'],
            'title': noteMap['title'],
            'content': noteMap['content'],
            'category': noteMap['category_id'], // category вместо category_id
            'date': noteMap['date'],
            'createdTimestamp': noteMap['created_timestamp'], // camelCase
            'updatedTimestamp': noteMap['updated_timestamp'], // camelCase
            'expanded': noteMap['expanded'] == 1, // bool вместо int
            'editMode': noteMap['edit_mode'] == 1, // bool вместо int
            'type': noteMap['type'],
            'metadata': noteMap['metadata'],
          };
        }).toList(),
        'categories': categories.map((c) {
          final catMap = c.toJson(); // содержит custom как int
          return {
            'id': catMap['id'],
            'name': catMap['name'],
            'color': catMap['color'],
            'custom': catMap['custom'] == 1, // bool вместо int
          };
        }).toList(),
        'settings': {
          'sortOrder': settings.sortOrder,
          'viewMode': settings.viewMode,
        },
        'exportDate': exportDate.toIso8601String(),
        'version': version,
      };

  /// Создаёт BackupData из JSON, который может быть как в старом Android‑формате,
  /// так и в новом унифицированном (веб‑формате). Поля автоматически преобразуются.
  factory BackupData.fromJson(Map<String, dynamic> json) {
    // ---- Заметки ----
    final notesJson = json['notes'] as List? ?? [];
    final notes = notesJson.map((noteMap) {
      final map = Map<String, dynamic>.from(noteMap as Map);

      // 1. id (обязательно, приводим к int)
      map['id'] = map['id'] != null
          ? (map['id'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch;

      // 2. created_timestamp / updated_timestamp
      // Поддерживаем оба варианта: createdTimestamp и created_timestamp
      if (map.containsKey('createdTimestamp') &&
          !map.containsKey('created_timestamp')) {
        map['created_timestamp'] = map['createdTimestamp'];
      }
      if (map['created_timestamp'] != null) {
        map['created_timestamp'] = (map['created_timestamp'] as num).toInt();
      } else {
        map['created_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      if (map.containsKey('updatedTimestamp') &&
          !map.containsKey('updated_timestamp')) {
        map['updated_timestamp'] = map['updatedTimestamp'];
      }
      if (map['updated_timestamp'] != null) {
        map['updated_timestamp'] = (map['updated_timestamp'] as num).toInt();
      } else {
        map['updated_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      // 3. category -> category_id
      if (map.containsKey('category') && !map.containsKey('category_id')) {
        map['category_id'] = map['category'];
      }
      // Если после преобразования category_id всё ещё null или не строка – ставим 'default'
      if (map['category_id'] == null || map['category_id'] is! String) {
        map['category_id'] = 'default';
      }

      // 4. expanded (был bool или int)
      if (map['expanded'] is bool) {
        map['expanded'] = (map['expanded'] as bool) ? 1 : 0;
      } else if (map['expanded'] == null) {
        map['expanded'] = 0;
      } else {
        map['expanded'] = (map['expanded'] as num).toInt();
      }

      // 5. editMode -> edit_mode
      if (map.containsKey('editMode') && !map.containsKey('edit_mode')) {
        map['edit_mode'] = map['editMode'];
      }
      if (map['edit_mode'] is bool) {
        map['edit_mode'] = (map['edit_mode'] as bool) ? 1 : 0;
      } else if (map['edit_mode'] == null) {
        map['edit_mode'] = 0;
      } else {
        map['edit_mode'] = (map['edit_mode'] as num).toInt();
      }

      // 6. type – если нет, ставим 'note'
      if (map['type'] == null || map['type'] is! String) {
        map['type'] = 'note';
      }

      // 7. content – обязательно строка
      if (map['content'] == null || map['content'] is! String) {
        map['content'] = '';
      }

      // 8. date – строка, если нет – генерируем текущую
      if (map['date'] == null || map['date'] is! String) {
        final now = DateTime.now();
        map['date'] =
            '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }

      // 9. title – может быть null, оставляем как есть
      // 10. metadata – может быть null
      if (!map.containsKey('metadata')) {
        map['metadata'] = null;
      }

      return Note.fromJson(map);
    }).toList();

    // ---- Категории ----
    final categoriesJson = json['categories'] as List? ?? [];
    final categories = categoriesJson.map((catMap) {
      final map = Map<String, dynamic>.from(catMap as Map);

      // id – строка
      if (map['id'] == null || map['id'] is! String) {
        map['id'] = 'cat_${DateTime.now().millisecondsSinceEpoch}';
      }

      // name – строка
      if (map['name'] == null || map['name'] is! String) {
        map['name'] = 'Без названия';
      }

      // color – строка
      if (map['color'] == null || map['color'] is! String) {
        map['color'] = '#4CAF50';
      }

      // custom – приводим bool к int (0/1)
      if (map['custom'] is bool) {
        map['custom'] = (map['custom'] as bool) ? 1 : 0;
      } else if (map['custom'] == null) {
        map['custom'] = 0;
      } else {
        map['custom'] = (map['custom'] as num).toInt();
      }

      return Category.fromJson(map);
    }).toList();

    // ---- Настройки ----
    final settingsMap = json['settings'] as Map<String, dynamic>? ?? {};
    // В веб‑формате поля называются sortOrder и viewMode
    final sortOrder = settingsMap['sortOrder'] as String? ??
        settingsMap['sort_order'] as String? ??
        'new';
    final viewMode = settingsMap['viewMode'] as String? ??
        settingsMap['view_mode'] as String? ??
        'list';
    final settings = Settings(sortOrder: sortOrder, viewMode: viewMode);

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
  /// Экспортирует текущие данные в унифицированном формате.
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

  /// Импортирует данные из выбранного JSON‑файла.
  static Future<BackupData?> pickAndParseBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString(encoding: utf8);
    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    return BackupData.fromJson(jsonMap);
  }
}
