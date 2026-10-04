import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/helpers.dart';

void main() {
  group('normalizeHexColor', () {
    test('upper-cases a valid #RRGGBB color', () {
      expect(normalizeHexColor('#4caf50'), '#4CAF50');
    });

    test('adds a missing leading #', () {
      expect(normalizeHexColor('4CAF50'), '#4CAF50');
    });

    test('expands short #RGB colors', () {
      expect(normalizeHexColor('#abc'), '#AABBCC');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeHexColor(' #FFF '), '#FFFFFF');
    });

    test('returns null for malformed values', () {
      for (final value in ['', '#', 'red', '#12345', '#GGGGGG', '#1234567']) {
        expect(normalizeHexColor(value), isNull, reason: 'value: "$value"');
      }
      expect(normalizeHexColor(null), isNull);
    });
  });

  group('hexToColor', () {
    test('converts #RRGGBB to an opaque color', () {
      expect(hexToColor('#FF0000'), const Color(0xFFFF0000));
    });

    test('accepts values without #', () {
      expect(hexToColor('ff0000'), const Color(0xFFFF0000));
    });

    test('accepts short #RGB values', () {
      expect(hexToColor('#abc'), const Color(0xFFAABBCC));
    });

    test('returns gray for malformed values instead of throwing', () {
      expect(hexToColor('not-a-color'), Colors.grey);
      expect(hexToColor(''), Colors.grey);
    });

    test('uses the custom fallback when provided', () {
      expect(hexToColor('xyz', fallback: Colors.red), Colors.red);
    });
  });

  group('isValidUrl', () {
    test('accepts http and https URLs', () {
      expect(isValidUrl('https://example.com'), isTrue);
      expect(isValidUrl('http://example.com/path?q=1'), isTrue);
    });

    test('rejects other schemes and plain text', () {
      expect(isValidUrl('ftp://example.com'), isFalse);
      expect(isValidUrl('example.com'), isFalse);
      expect(isValidUrl('just some text'), isFalse);
    });
  });

  group('extractDomain', () {
    test('removes the www prefix', () {
      expect(extractDomain('https://www.example.com/page'), 'example.com');
    });

    test('keeps other subdomains', () {
      expect(extractDomain('https://blog.example.com'), 'blog.example.com');
    });
  });

  group('truncate', () {
    test('returns short text unchanged', () {
      expect(truncate('hello', 10), 'hello');
      expect(truncate('hello', 5), 'hello');
    });

    test('cuts long text and appends an ellipsis', () {
      expect(truncate('hello world', 5), 'hello...');
    });
  });

  group('formatTimestamp', () {
    test('formats as dd.MM.yyyy, HH:mm in local time', () {
      final timestamp = DateTime(2026, 10, 4, 9, 5).millisecondsSinceEpoch;
      expect(formatTimestamp(timestamp), '04.10.2026, 09:05');
    });
  });
}
