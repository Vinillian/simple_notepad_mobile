import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/models/remote_categories_snapshot.dart';

Map<String, dynamic> _json(String id, {Object? updated, Object? deleted}) => {
      'id': id,
      'name': 'Name $id',
      'color': '#112233',
      'custom': 1,
      if (updated != null) 'updated_timestamp': updated,
      if (deleted != null) 'deleted': deleted,
    };

void main() {
  group('RemoteCategoriesSnapshot.fromJson', () {
    test('marks categories with deleted = 1 as tombstones', () {
      final s = RemoteCategoriesSnapshot.fromJson([
        _json('a', updated: 10, deleted: 0),
        _json('b', updated: 20, deleted: 1),
      ]);
      expect(s.entries.map((e) => e.id), ['a', 'b']);
      expect(s.entries[0].deleted, isFalse);
      expect(s.entries[1].deleted, isTrue);
      expect(s.entries[1].updatedAt, 20);
    });

    test('keeps the content of live categories only', () {
      final s = RemoteCategoriesSnapshot.fromJson([
        _json('a', updated: 10, deleted: 0),
        _json('b', updated: 20, deleted: 1),
      ]);
      expect(s.liveCategories.keys, ['a']);
      expect(s.liveCategories['a']!.name, 'Name a');
    });

    test('knownIds includes tombstones', () {
      final s = RemoteCategoriesSnapshot.fromJson([
        _json('a', updated: 10, deleted: 0),
        _json('b', updated: 20, deleted: 1),
      ]);
      expect(s.knownIds, {'a', 'b'});
    });

    test('updatedAtById gives the change time of every category', () {
      final s = RemoteCategoriesSnapshot.fromJson([
        _json('a', updated: 10, deleted: 0),
        _json('b', updated: 20, deleted: 1),
      ]);
      expect(s.updatedAtById, {'a': 10, 'b': 20});
    });

    test('treats missing time and deleted fields as 0 and not deleted', () {
      final s = RemoteCategoriesSnapshot.fromJson([_json('a')]);
      expect(s.entries.single.updatedAt, 0);
      expect(s.entries.single.deleted, isFalse);
      expect(s.liveCategories.containsKey('a'), isTrue);
    });
  });
}
