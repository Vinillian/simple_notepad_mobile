import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/settings.dart';
import '../services/local_settings_service.dart';
import '../services/settings_service.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final LocalSettingsService _localService;
  late final SettingsService _remoteService;

  @override
  Future<Settings> build() async {
    _localService = LocalSettingsService();
    _remoteService = SettingsService();
    return _fetchLocalSettings();
  }

  Future<Settings> _fetchLocalSettings() async {
    return await _localService.getSettings();
  }

  Future<void> updateSettings(Settings settings) async {
    await _localService.updateSettings(settings);
    state = await AsyncValue.guard(() => _fetchLocalSettings());
    _syncSettingsToRemote(settings);
  }

  Future<void> syncWithRemote() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localSettings = await _localService.getSettings();
      try {
        final remoteSettings = await _remoteService.getSettings();
        if (localSettings.sortOrder != remoteSettings.sortOrder ||
            localSettings.viewMode != remoteSettings.viewMode) {
          await _localService.updateSettings(remoteSettings);
          return remoteSettings;
        }
        return localSettings;
      } catch (e) {
        // Нет сети - оставляем локальные
        return localSettings;
      }
    });
  }

  Future<void> _syncSettingsToRemote(Settings settings) async {
    try {
      await _remoteService.updateSettings(settings);
    } catch (e) {
      // Ошибка сети - игнорируем
    }
  }
}
