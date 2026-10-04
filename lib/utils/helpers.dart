import 'package:flutter/material.dart';

/// Normalizes a color string to the `#RRGGBB` form (upper case).
///
/// Accepts `RGB` and `RRGGBB` with or without the leading `#`.
/// Returns `null` if [value] is not a valid hex color.
String? normalizeHexColor(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return '#${hex.toUpperCase()}';
}

/// Converts a hex color string to a [Color]; returns [fallback] if the
/// string is malformed instead of throwing.
Color hexToColor(String hex, {Color fallback = Colors.grey}) {
  final normalized = normalizeHexColor(hex);
  if (normalized == null) return fallback;
  return Color(int.parse(normalized.substring(1), radix: 16) + 0xFF000000);
}

bool isValidUrl(String text) {
  final uri = Uri.tryParse(text);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

String? extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.replaceFirst('www.', '');
  } catch (_) {
    return null;
  }
}

String formatTimestamp(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
