import 'dart:convert';
import 'package:http/http.dart' as http;

class LinkMetadataService {
  static const String _baseUrl = 'https://api.microlink.io';

  /// Запрашивает метаданные для URL и возвращает Map.
  /// В случае ошибки возвращает минимальные данные.
  static Future<Map<String, dynamic>> fetchMetadata(String url) async {
    try {
      final encodedUrl = Uri.encodeComponent(url);
      final uri = Uri.parse(
          '$_baseUrl/?url=$encodedUrl&audio=false&video=false&iframe=false');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final metadata = <String, dynamic>{};
          metadata['title'] = data['title'] ?? '';
          metadata['description'] = data['description'] ?? '';
          metadata['image'] = data['image']?['url'] ?? '';
          metadata['favicon'] =
              data['logo']?['url'] ?? data['favicon']?['url'] ?? '';
          metadata['siteName'] = data['publisher'] ?? _getDomainFromUrl(url);
          // Обрезаем длинные поля
          if (metadata['title'] is String) {
            metadata['title'] = (metadata['title'] as String).trim();
            if (metadata['title'].length > 200) {
              metadata['title'] = metadata['title'].substring(0, 200);
            }
          }
          if (metadata['description'] is String) {
            metadata['description'] =
                (metadata['description'] as String).trim();
            if (metadata['description'].length > 300) {
              metadata['description'] =
                  metadata['description'].substring(0, 300);
            }
          }
          return metadata;
        }
      }
    } catch (e) {
      // ignore
    }
    // Возвращаем минимальные данные
    return {
      'title': '',
      'description': '',
      'image': '',
      'favicon': '',
      'siteName': _getDomainFromUrl(url),
    };
  }

  static String _getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}
