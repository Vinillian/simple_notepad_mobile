import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/category.dart';
import 'package:simple_notepad_mobile/models/note.dart';
import 'package:simple_notepad_mobile/models/settings.dart';
import 'package:simple_notepad_mobile/utils/merge_helper.dart';

Category category(String id) =>
    Category(id: id, name: 'Category $id', color: '#4CAF50', custom: 1);

Note note(double id, {String content = 'text'}) => Note(
      id: id,
      title: 'Note $id',
      content: content,
      categoryId: 'general',
      date: '01.01.2026, 10:00',
      createdTimestamp: 1,
      updatedTimestamp: 1,
      expanded: 0,
      editMode: 0,
      type: 'note',
    );

void main() {
  group('MergeHelper.findNewCategories', () {
    test('returns only categories whose id is not in current', () {
      final result = MergeHelper.findNewCategories(
        current: [category('a'), category('b')],
        imported: [category('b'), category('c'), category('d')],
      );
      expect(result.map((c) => c.id), ['c', 'd']);
    });

    test('returns an empty list when everything already exists', () {
      final result = MergeHelper.findNewCategories(
        current: [category('a'), category('b')],
        imported: [category('a')],
      );
      expect(result, isEmpty);
    });

    test('returns all imported categories when current is empty', () {
      final result = MergeHelper.findNewCategories(
        current: [],
        imported: [category('a'), category('b')],
      );
      expect(result.map((c) => c.id), ['a', 'b']);
    });
  });

  group('MergeHelper.findNewNotes', () {
    test('returns only notes whose id is not in current', () {
      final result = MergeHelper.findNewNotes(
        current: [note(1), note(2)],
        imported: [note(2), note(3)],
      );
      expect(result.map((n) => n.id), [3.0]);
    });

    test('returns an empty list when nothing is new', () {
      final result = MergeHelper.findNewNotes(
        current: [note(1)],
        imported: [note(1)],
      );
      expect(result, isEmpty);
    });

    test('ignores edits to notes with the same id (known limitation)', () {
      // Edits are not propagated yet; this documents the current behavior.
      final result = MergeHelper.findNewNotes(
        current: [note(1, content: 'old')],
        imported: [note(1, content: 'changed')],
      );
      expect(result, isEmpty);
    });
  });

  group('MergeHelper.isSettingsDifferent', () {
    final base = Settings(sortOrder: 'new', viewMode: 'list');

    test('is false for identical settings', () {
      final same = Settings(sortOrder: 'new', viewMode: 'list');
      expect(MergeHelper.isSettingsDifferent(base, same), isFalse);
    });

    test('is true when the sort order differs', () {
      final other = Settings(sortOrder: 'old', viewMode: 'list');
      expect(MergeHelper.isSettingsDifferent(base, other), isTrue);
    });

    test('is true when the view mode differs', () {
      final other = Settings(sortOrder: 'new', viewMode: 'grid');
      expect(MergeHelper.isSettingsDifferent(base, other), isTrue);
    });
  });
}
