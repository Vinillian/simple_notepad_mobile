import '../models/settings.dart';
import 'api_client.dart';

class SettingsService {
  final ApiClient _apiClient = ApiClient();

  Future<Settings> getSettings() async {
    final data = await _apiClient.get('/settings');
    return Settings.fromJson(data);
  }

  Future<void> updateSettings(Settings settings) async {
    await _apiClient.put('/settings', settings.toJson());
  }
}