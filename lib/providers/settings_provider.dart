import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final SettingsService _settingsService;

  @override
  Future<Settings> build() async {
    _settingsService = SettingsService();
    return _fetchSettings();
  }

  Future<Settings> _fetchSettings() async {
    return await _settingsService.getSettings();
  }

  Future<void> updateSettings(Settings settings) async {
    await _settingsService.updateSettings(settings);
    state = await AsyncValue.guard(() => _fetchSettings());
  }
}