import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/services/local_app_state_service.dart';

void main() {
  group('previewFlagFromValue', () {
    test('is on when nothing is stored', () {
      expect(LocalAppStateService.previewFlagFromValue(null), isTrue);
    });

    test('is on for 1', () {
      expect(LocalAppStateService.previewFlagFromValue('1'), isTrue);
    });

    test('is off only for 0', () {
      expect(LocalAppStateService.previewFlagFromValue('0'), isFalse);
    });
  });
}
