import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/sync_planner.dart';

Map<String, SyncAction> plan(List<SyncEntry> local, List<SyncEntry> remote) {
  return SyncPlanner.plan(local: local, remote: remote);
}

void main() {
  group('items on one side only', () {
    test('a local item is pushed to the server', () {
      expect(
        plan(const [SyncEntry('a', 1)], const []),
        {'a': SyncAction.pushToRemote},
      );
    });

    test('a remote item is pulled to the device', () {
      expect(
        plan(const [], const [SyncEntry('a', 1)]),
        {'a': SyncAction.pullToLocal},
      );
    });

    test('a local tombstone the server never had needs nothing', () {
      expect(
        plan(const [SyncEntry('a', 5, deleted: true)], const []),
        isEmpty,
      );
    });

    test('a remote tombstone the device never had needs nothing', () {
      expect(
        plan(const [], const [SyncEntry('a', 5, deleted: true)]),
        isEmpty,
      );
    });
  });

  group('items on both sides', () {
    test('equal copies need nothing', () {
      expect(
        plan(const [SyncEntry('a', 3)], const [SyncEntry('a', 3)]),
        isEmpty,
      );
    });

    test('a newer local edit is pushed', () {
      expect(
        plan(const [SyncEntry('a', 9)], const [SyncEntry('a', 3)]),
        {'a': SyncAction.pushToRemote},
      );
    });

    test('a newer remote edit is pulled', () {
      expect(
        plan(const [SyncEntry('a', 3)], const [SyncEntry('a', 9)]),
        {'a': SyncAction.pullToLocal},
      );
    });

    test('a newer local deletion is applied on the server', () {
      expect(
        plan(
          const [SyncEntry('a', 9, deleted: true)],
          const [SyncEntry('a', 3)],
        ),
        {'a': SyncAction.deleteRemote},
      );
    });

    test('a newer remote deletion is applied on the device', () {
      expect(
        plan(
          const [SyncEntry('a', 3)],
          const [SyncEntry('a', 9, deleted: true)],
        ),
        {'a': SyncAction.deleteLocal},
      );
    });

    test('an edit made after a deletion on the other side wins', () {
      expect(
        plan(
          const [SyncEntry('a', 3, deleted: true)],
          const [SyncEntry('a', 9)],
        ),
        {'a': SyncAction.pullToLocal},
      );
    });

    test('with equal timestamps a deletion wins over a live copy', () {
      expect(
        plan(
          const [SyncEntry('a', 5, deleted: true)],
          const [SyncEntry('a', 5)],
        ),
        {'a': SyncAction.deleteRemote},
      );
      expect(
        plan(
          const [SyncEntry('a', 5)],
          const [SyncEntry('a', 5, deleted: true)],
        ),
        {'a': SyncAction.deleteLocal},
      );
    });

    test('two tombstones need nothing', () {
      expect(
        plan(
          const [SyncEntry('a', 4, deleted: true)],
          const [SyncEntry('a', 8, deleted: true)],
        ),
        isEmpty,
      );
    });
  });

  test('several ids are planned independently', () {
    final result = plan(
      const [
        SyncEntry('keep', 1),
        SyncEntry('push', 8),
        SyncEntry('gone', 7, deleted: true),
        SyncEntry('only-local', 2),
      ],
      const [
        SyncEntry('keep', 1),
        SyncEntry('push', 2),
        SyncEntry('gone', 3),
        SyncEntry('only-remote', 4),
      ],
    );
    expect(result, {
      'push': SyncAction.pushToRemote,
      'gone': SyncAction.deleteRemote,
      'only-local': SyncAction.pushToRemote,
      'only-remote': SyncAction.pullToLocal,
    });
  });
}
