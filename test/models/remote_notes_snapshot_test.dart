import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/remote_notes_snapshot.dart';

Map<String, dynamic> _json(Object id, int updated, {Object? deleted}) => {
      'id': id,
      'title': 'T',
      'content': 'C',
      'category_id': 'cat',
      'date': '2026-10-12',
      'created_timestamp': 1,
      'updated_timestamp': updated,
      'expanded': 0,
      'edit_mode': 0,
      'type': 'text',
      'metadata': null,
      if (deleted != null) 'deleted': deleted,
    };

void main() {
  group('RemoteNotesSnapshot.fromJson', () {
    test('marks notes with deleted = 1 as tombstones', () {
      final s = RemoteNotesSnapshot.fromJson([
        _json('a', 10, deleted: 0),
        _json('b', 20, deleted: 1),
      ]);
      expect(s.entries.map((e) => e.id), ['a', 'b']);
      expect(s.entries[0].deleted, isFalse);
      expect(s.entries[1].deleted, isTrue);
      expect(s.entries[1].updatedAt, 20);
    });

    test('keeps the content of live notes only', () {
      final s = RemoteNotesSnapshot.fromJson([
        _json('a', 10, deleted: 0),
        _json('b', 20, deleted: 1),
      ]);
      expect(s.liveNotes.keys, ['a']);
      expect(s.liveNotes['a']!.content, 'C');
    });

    test('knownIds includes tombstones', () {
      final s = RemoteNotesSnapshot.fromJson([
        _json('a', 10, deleted: 0),
        _json('b', 20, deleted: 1),
      ]);
      expect(s.knownIds, {'a', 'b'});
    });

    test('treats a missing deleted field as not deleted', () {
      final s = RemoteNotesSnapshot.fromJson([_json('a', 10)]);
      expect(s.entries.single.deleted, isFalse);
      expect(s.liveNotes.containsKey('a'), isTrue);
    });

    test('accepts a boolean deleted flag and numeric ids', () {
      final s = RemoteNotesSnapshot.fromJson([
        _json(1700000000000, 5, deleted: true),
      ]);
      expect(s.entries.single.id, '1700000000000');
      expect(s.entries.single.deleted, isTrue);
    });
  });
}
