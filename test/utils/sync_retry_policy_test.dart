import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/sync_retry_policy.dart';

void main() {
  group('SyncRetryPolicy', () {
    test('the wait grows with every attempt', () {
      for (var i = 1; i < SyncRetryPolicy.delays.length; i++) {
        expect(
          SyncRetryPolicy.delays[i] > SyncRetryPolicy.delays[i - 1],
          isTrue,
        );
      }
    });

    test('gives a wait for every listed attempt', () {
      expect(SyncRetryPolicy.delayFor(0), const Duration(seconds: 10));
      expect(
        SyncRetryPolicy.delayFor(SyncRetryPolicy.delays.length - 1),
        SyncRetryPolicy.delays.last,
      );
    });

    test('stops when the retries are used up', () {
      expect(SyncRetryPolicy.delayFor(SyncRetryPolicy.delays.length), isNull);
      expect(SyncRetryPolicy.delayFor(-1), isNull);
    });
  });
}
