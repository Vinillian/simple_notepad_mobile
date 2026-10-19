import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/sync_error.dart';

void main() {
  group('describeSyncError', () {
    test('names a server failure with its code', () {
      final error = Exception('Network error: Exception: Server error: 500 - boom');
      expect(describeSyncError(error), 'ошибка на сервере (код 500)');
    });

    test('names a refused access', () {
      final error = Exception('Network error: Exception: Server error: 403 - no');
      expect(describeSyncError(error), 'сервер отклонил доступ (код 403)');
    });

    test('names a rejected request', () {
      final error = Exception('Network error: Exception: Server error: 404 - x');
      expect(describeSyncError(error), 'сервер отклонил запрос (код 404)');
    });

    test('recognises a timeout', () {
      final error = Exception(
        'Network error: TimeoutException after 0:00:10.000000: Future not completed',
      );
      expect(describeSyncError(error), 'сервер не отвечает (таймаут)');
    });

    test('recognises a missing network', () {
      final error = Exception(
        'Network error: SocketException: Failed host lookup: example.com',
      );
      expect(describeSyncError(error), 'нет подключения к сети');
    });

    test('recognises an unreachable server', () {
      final error = Exception(
        'Network error: SocketException: Connection refused, errno = 111',
      );
      expect(describeSyncError(error), 'сервер недоступен');
    });

    test('falls back to an unknown error', () {
      expect(describeSyncError(StateError('boom')), 'неизвестная ошибка');
    });
  });
}
