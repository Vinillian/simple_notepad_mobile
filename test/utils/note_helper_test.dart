import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/note.dart';
import 'package:simple_notepad_mobile/utils/note_helper.dart';

Note existingLink({String content = 'https://example.com/a'}) => Note(
      id: '111',
      title: 'My link',
      content: content,
      categoryId: 'general',
      date: '01.01.2026, 10:00',
      createdTimestamp: 1000,
      updatedTimestamp: 2000,
      expanded: 1,
      editMode: 1,
      type: 'link',
      metadata: const <String, dynamic>{'title': 'Page', 'image': 'img'},
      previewText: 'preview',
    );

void main() {
  final now = DateTime(2026, 10, 4, 14, 5);

  group('buildNoteForSave', () {
    test('creates a new note with defaults', () {
      final note = buildNoteForSave(
        title: '',
        content: 'hello',
        categoryId: 'general',
        type: 'note',
        now: now,
        newId: 'new-id',
      );

      expect(note.id, 'new-id');
      expect(note.title, isNull);
      expect(note.date, '04.10.2026, 14:05');
      expect(note.createdTimestamp, now.millisecondsSinceEpoch);
      expect(note.updatedTimestamp, now.millisecondsSinceEpoch);
      expect(note.expanded, 0);
      expect(note.editMode, 0);
      expect(note.metadata, isNull);
      expect(note.previewText, isNull);
    });

    test('generates an id for a new note when none is given', () {
      final note = buildNoteForSave(
        title: '',
        content: 'hello',
        categoryId: 'general',
        type: 'note',
        now: now,
      );

      expect(note.id, isNotEmpty);
    });

    test('keeps state and metadata when only the title changes', () {
      final original = existingLink();
      final note = buildNoteForSave(
        original: original,
        title: 'Renamed',
        content: original.content,
        categoryId: 'general',
        type: 'link',
        now: now,
      );

      expect(note.title, 'Renamed');
      expect(note.id, original.id);
      expect(note.date, original.date);
      expect(note.createdTimestamp, original.createdTimestamp);
      expect(note.updatedTimestamp, now.millisecondsSinceEpoch);
      expect(note.expanded, 1);
      expect(note.editMode, 1);
      expect(note.metadata, original.metadata);
      expect(note.previewText, 'preview');
    });

    test('ignores surrounding whitespace when comparing the content', () {
      final original = existingLink();
      final note = buildNoteForSave(
        original: original,
        title: 'My link',
        content: '  ${original.content}\n',
        categoryId: 'general',
        type: 'link',
        now: now,
      );

      expect(note.metadata, original.metadata);
    });

    test('drops metadata and preview text when the URL changes', () {
      final note = buildNoteForSave(
        original: existingLink(),
        title: 'My link',
        content: 'https://example.com/b',
        categoryId: 'general',
        type: 'link',
        now: now,
      );

      expect(note.metadata, isNull);
      expect(note.previewText, isNull);
      expect(note.expanded, 1);
      expect(note.editMode, 1);
    });

    test('uses the selected category', () {
      final note = buildNoteForSave(
        original: existingLink(),
        title: 'My link',
        content: 'https://example.com/a',
        categoryId: 'work',
        type: 'link',
        now: now,
      );

      expect(note.categoryId, 'work');
    });
  });

  group('linkCardTitle', () {
    const url = 'https://www.example.com/page';

    test('prefers the note title', () {
      expect(
        linkCardTitle(
          title: 'Mine',
          metadata: const <String, dynamic>{'title': 'Fetched'},
          url: url,
        ),
        'Mine',
      );
    });

    test('falls back to the fetched title when the note title is blank', () {
      expect(
        linkCardTitle(
          title: '  ',
          metadata: const <String, dynamic>{'title': ' Fetched '},
          url: url,
        ),
        'Fetched',
      );
    });

    test('falls back to the domain when there is no title at all', () {
      expect(
        linkCardTitle(
          metadata: const <String, dynamic>{'title': ''},
          url: url,
        ),
        'example.com',
      );
      expect(linkCardTitle(url: url), 'example.com');
    });

    test('uses a generic label when nothing else is available', () {
      expect(linkCardTitle(url: ''), 'Открыть ссылку');
    });
  });
}
