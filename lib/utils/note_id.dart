import 'dart:math';

/// Converts an id value from JSON, a backup or an old database row to the
/// string form used for note ids.
///
/// Notes created before ids became strings have numeric ids (milliseconds
/// timestamps, some with a fractional part). Their exact numeric value is kept
/// as text, so the same note gets the same id on every device.
///
/// Throws a [FormatException] for empty strings, non-finite numbers and
/// values of any other type.
String noteIdFromValue(Object? value) {
  if (value is String) {
    final id = value.trim();
    if (id.isEmpty) throw const FormatException('Empty note id');
    return id;
  }
  if (value is num) {
    if (!value.isFinite) throw FormatException('Invalid note id: $value');
    // Whole numbers are written without a trailing ".0".
    if (value == value.truncateToDouble() &&
        value.abs() < 9007199254740992) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  throw FormatException('Unsupported note id: $value');
}

/// Generates a random (version 4) UUID for a new note.
///
/// Pass [random] only in tests to get a repeatable result.
String generateNoteId([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
