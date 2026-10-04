import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad_mobile/utils/note_id.dart';

void main() {
  group('noteIdFromValue', () {
    test('writes whole numbers without a fractional part', () {
      expect(noteIdFromValue(1700000000000), '1700000000000');
      expect(noteIdFromValue(1700000000000.0), '1700000000000');
    });

    test('keeps a fractional part exactly', () {
      expect(noteIdFromValue(1700000000000.5), '1700000000000.5');
      expect(noteIdFromValue(1700000000000.25), '1700000000000.25');
    });

    test('gives different ids to numbers that differ only in the fraction',
        () {
      expect(noteIdFromValue(1700000000000.25),
          isNot(noteIdFromValue(1700000000000.5)));
    });

    test('trims strings and keeps them otherwise unchanged', () {
      expect(noteIdFromValue('  abc-1  '), 'abc-1');
      expect(noteIdFromValue('1700000000000.5'), '1700000000000.5');
    });

    test('is stable when applied twice', () {
      final once = noteIdFromValue(1700000000000.5);
      expect(noteIdFromValue(once), once);
    });

    test('rejects empty strings, non-finite numbers and other types', () {
      expect(() => noteIdFromValue(''), throwsFormatException);
      expect(() => noteIdFromValue('   '), throwsFormatException);
      expect(() => noteIdFromValue(double.nan), throwsFormatException);
      expect(() => noteIdFromValue(double.infinity), throwsFormatException);
      expect(() => noteIdFromValue(null), throwsFormatException);
      expect(() => noteIdFromValue(true), throwsFormatException);
    });
  });

  group('generateNoteId', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('produces a version 4 UUID', () {
      expect(generateNoteId(), matches(uuidV4));
      expect(generateNoteId(Random(1)), matches(uuidV4));
    });

    test('is repeatable for a seeded generator', () {
      expect(generateNoteId(Random(42)), generateNoteId(Random(42)));
    });

    test('does not repeat', () {
      final ids = List.generate(200, (_) => generateNoteId());
      expect(ids.toSet(), hasLength(200));
    });
  });
}
