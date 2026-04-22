import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) {
    buffer.write(hex.replaceFirst('#', ''));
  } else {
    return Colors.grey;
  }
  return Color(int.parse(buffer.toString(), radix: 16) + 0xFF000000);
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

/// Извлекает чистый текст из Markdown, ограничивая длину до [maxLength].
String plainTextFromMarkdown(String markdown, {int maxLength = 150}) {
  try {
    final ast = md.Document().parse(markdown);
    final buffer = StringBuffer();
    for (final node in ast) {
      buffer.write(node.textContent);
    }
    var text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > maxLength) {
      text = '${text.substring(0, maxLength)}…';
    }
    return text;
  } catch (e) {
    // В случае ошибки парсинга возвращаем сырой текст с ограничением
    var text = markdown.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > maxLength) {
      text = '${text.substring(0, maxLength)}…';
    }
    return text;
  }
}
