import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'local_app_state_service.dart';

class ApiClient {
  /// Maximum time to wait for the server; without it the OS-level connect
  /// timeout (about two minutes) would block the UI.
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client = http.Client();
  final ServerUrlStorage _storage;

  ApiClient({ServerUrlStorage? storage})
      : _storage = storage ?? LocalAppStateService();

  /// Server address saved in the settings, or the build-time default.
  /// Read on every request, so a change applies without restarting the app.
  Future<Uri> _uri(String endpoint) async {
    String? saved;
    try {
      saved = await _storage.getServerUrl();
    } catch (_) {
      saved = null;
    }
    return Uri.parse('${saved ?? ApiConstants.baseUrl}$endpoint');
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final url = await _uri(endpoint);
      final response = await _client.get(url).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = await _uri(endpoint);
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = await _uri(endpoint);
      final response = await _client
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final url = await _uri(endpoint);
      final response = await _client.delete(url).timeout(_timeout);
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('Server error: ${response.statusCode} - ${response.body}');
    }
  }
}