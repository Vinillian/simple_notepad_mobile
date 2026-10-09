import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/server_url.dart';

void main() {
  group('normalizeServerUrl', () {
    test('accepts http and https addresses', () {
      expect(normalizeServerUrl('http://192.168.1.135:3000/api'),
          'http://192.168.1.135:3000/api');
      expect(normalizeServerUrl('https://notes.example.com/api'),
          'https://notes.example.com/api');
    });

    test('trims spaces and trailing slashes', () {
      expect(normalizeServerUrl('  https://example.com/api//  '),
          'https://example.com/api');
    });

    test('rejects empty input and input with spaces inside', () {
      expect(normalizeServerUrl(''), isNull);
      expect(normalizeServerUrl('   '), isNull);
      expect(normalizeServerUrl('http://exa mple.com'), isNull);
    });

    test('rejects other schemes and addresses without a host', () {
      expect(normalizeServerUrl('ftp://example.com'), isNull);
      expect(normalizeServerUrl('example.com/api'), isNull);
      expect(normalizeServerUrl('http://'), isNull);
    });

    test('rejects addresses with a query or a fragment', () {
      expect(normalizeServerUrl('https://example.com/api?x=1'), isNull);
      expect(normalizeServerUrl('https://example.com/api#top'), isNull);
    });
  });

  group('isCleartextAllowed', () {
    test('https is always allowed', () {
      expect(isCleartextAllowed('https://example.com/api'), isTrue);
    });

    test('http only for the hosts from the network security config', () {
      expect(isCleartextAllowed('http://10.0.2.2:3000/api'), isTrue);
      expect(isCleartextAllowed('http://localhost:3000/api'), isTrue);
      expect(isCleartextAllowed('http://192.168.1.135:3000/api'), isFalse);
    });
  });
}
