import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/category.dart';
import 'package:simple_notepad_mobile/models/note.dart';
import 'package:simple_notepad_mobile/models/settings.dart';
import 'package:simple_notepad_mobile/services/backup_service.dart';

/// Parses [json] the same way the app does: after a JSON encode/decode
/// round trip, as if it had been read from a backup file.
BackupData parse(Map<String, dynamic> json) =>
    BackupData.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);

Map<String, dynamic> backupWith({
  List<dynamic> notes = const [],
  List<dynamic> categories = const [],
  Map<String, dynamic> settings = const {},
}) =>
    {'notes': notes, 'categories': categories, 'settings': settings};

void main() {
  group('BackupData.fromJson: notes', () {
    test('converts legacy camelCase keys and booleans', () {
      final backup = parse(backupWith(notes: [
        {
          'id': 1700000000000,
          'title': 'Old note',
          'content': 'Hello',
          'category': 'ideas',
          'date': '01.02.2026, 10:00',
          'createdTimestamp': 1700000000000,
          'updatedTimestamp': 1700000001000,
          'expanded': true,
          'editMode': false,
          'type': 'note',
        },
      ]));

      final note = backup.notes.single;
      expect(note.id, '1700000000000');
      expect(note.title, 'Old note');
      expect(note.categoryId, 'ideas');
      expect(note.createdTimestamp, 1700000000000);
      expect(note.updatedTimestamp, 1700000001000);
      expect(note.expanded, 1);
      expect(note.editMode, 0);
    });

    test('keeps a fractional numeric id exactly, as text', () {
      final backup = parse(backupWith(notes: [
        {'id': 1700000000000.5, 'content': 'x'},
        {'id': 1700000000000.0, 'content': 'y'},
      ]));

      expect(backup.notes.map((n) => n.id), ['1700000000000.5', '1700000000000']);
    });

    test('keeps a string id as it is', () {
      final backup = parse(backupWith(notes: [
        {'id': '3f2b8c1e-9a47-4d6b-8e21-5c0a7d4f9b12', 'content': 'x'},
      ]));

      expect(backup.notes.single.id, '3f2b8c1e-9a47-4d6b-8e21-5c0a7d4f9b12');
    });

    test('keeps snake_case keys as they are', () {
      final backup = parse(backupWith(notes: [
        {
          'id': 5,
          'content': 'x',
          'category_id': 'work',
          'created_timestamp': 10,
          'updated_timestamp': 20,
          'expanded': 1,
          'edit_mode': 1,
        },
      ]));

      final note = backup.notes.single;
      expect(note.categoryId, 'work');
      expect(note.createdTimestamp, 10);
      expect(note.updatedTimestamp, 20);
      expect(note.expanded, 1);
      expect(note.editMode, 1);
    });

    test('fills in defaults for missing fields', () {
      final backup = parse(backupWith(notes: [
        {'title': 'Bare'},
      ]));

      final note = backup.notes.single;
      expect(note.title, 'Bare');
      expect(note.content, '');
      expect(note.categoryId, 'default');
      expect(note.type, 'note');
      expect(note.expanded, 0);
      expect(note.editMode, 0);
      expect(note.id, isNotEmpty);
      expect(note.date, isNotEmpty);
    });

    test('skips malformed entries and keeps the valid ones', () {
      final backup = parse(backupWith(notes: [
        {'id': true, 'content': 'bad id'},
        {'id': 2, 'content': 'good'},
        'not a map',
      ]));

      expect(backup.notes, hasLength(1));
      expect(backup.notes.single.id, '2');
    });

    test('decodes metadata stored as a JSON string', () {
      final backup = parse(backupWith(notes: [
        {'id': 1, 'content': 'link', 'metadata': '{"title":"Site"}'},
      ]));

      expect(backup.notes.single.metadata, {'title': 'Site'});
    });

    test('ignores metadata that is not valid JSON', () {
      final backup = parse(backupWith(notes: [
        {'id': 1, 'content': 'link', 'metadata': 'not json'},
      ]));

      expect(backup.notes.single.metadata, isNull);
    });
  });

  group('BackupData.fromJson: categories', () {
    test('fills in defaults for missing fields', () {
      final backup = parse(backupWith(categories: [<String, dynamic>{}]));

      final category = backup.categories.single;
      expect(category.id, startsWith('cat_'));
      expect(category.name, 'Без названия');
      expect(category.color, '#4CAF50');
      expect(category.custom, 0);
    });

    test('normalizes colors and falls back to green for malformed ones', () {
      final backup = parse(backupWith(categories: [
        {'id': 'a', 'name': 'A', 'color': 'red', 'custom': 1},
        {'id': 'b', 'name': 'B', 'color': '#abc', 'custom': 1},
        {'id': 'c', 'name': 'C', 'color': '4caf50', 'custom': 1},
      ]));

      expect(backup.categories.map((c) => c.color),
          ['#4CAF50', '#AABBCC', '#4CAF50']);
    });

    test('converts a boolean custom flag to an int', () {
      final backup = parse(backupWith(categories: [
        {'id': 'a', 'name': 'A', 'color': '#FF0000', 'custom': true},
        {'id': 'b', 'name': 'B', 'color': '#FF0000', 'custom': false},
      ]));

      expect(backup.categories.map((c) => c.custom), [1, 0]);
    });

    test('skips malformed entries and keeps the valid ones', () {
      final backup = parse(backupWith(categories: [
        'oops',
        {'id': 'ok', 'name': 'Ok', 'color': '#fff', 'custom': 0},
      ]));

      expect(backup.categories.map((c) => c.id), ['ok']);
    });
  });

  group('BackupData.fromJson: settings and metadata', () {
    test('reads camelCase settings', () {
      final backup = parse(backupWith(
        settings: {'sortOrder': 'old', 'viewMode': 'grid'},
      ));

      expect(backup.settings.sortOrder, 'old');
      expect(backup.settings.viewMode, 'grid');
    });

    test('reads snake_case settings', () {
      final backup = parse(backupWith(
        settings: {'sort_order': 'old', 'view_mode': 'grid'},
      ));

      expect(backup.settings.sortOrder, 'old');
      expect(backup.settings.viewMode, 'grid');
    });

    test('uses defaults when settings are missing', () {
      final backup = parse(backupWith());

      expect(backup.settings.sortOrder, 'new');
      expect(backup.settings.viewMode, 'list');
    });

    test('reads exportDate and version, with a default version', () {
      final withValues = parse({
        ...backupWith(),
        'exportDate': '2026-09-30T15:02:50.292459',
        'version': '2.0',
      });
      expect(withValues.exportDate, DateTime.parse('2026-09-30T15:02:50.292459'));
      expect(withValues.version, '2.0');

      final withoutVersion = parse(backupWith());
      expect(withoutVersion.version, '1.0');
    });

    test('tolerates an empty backup', () {
      final backup = parse(<String, dynamic>{});

      expect(backup.notes, isEmpty);
      expect(backup.categories, isEmpty);
    });
  });

  group('BackupData round trip', () {
    test('toJson followed by fromJson restores the data', () {
      final original = BackupData(
        notes: [
          Note(
            id: '1700000000000',
            title: 'Link',
            content: 'https://example.com',
            categoryId: 'ideas',
            date: '01.02.2026, 10:00',
            createdTimestamp: 1700000000000,
            updatedTimestamp: 1700000001000,
            expanded: 1,
            editMode: 0,
            type: 'link',
            metadata: {'title': 'Example'},
          ),
        ],
        categories: [
          Category(id: 'ideas', name: 'Ideas', color: '#FF9800', custom: 1),
        ],
        settings: Settings(sortOrder: 'old', viewMode: 'grid'),
        exportDate: DateTime(2026, 1, 2, 3, 4, 5),
        version: '1.0',
      );

      final restored = parse(original.toJson());

      expect(restored.notes.single.toJson(), original.notes.single.toJson());
      expect(restored.categories.single.toJson(),
          original.categories.single.toJson());
      expect(restored.settings.toJson(), original.settings.toJson());
      expect(restored.exportDate, original.exportDate);
      expect(restored.version, original.version);
    });
  });
}
