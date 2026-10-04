import 'package:flutter/material.dart';
import '../services/local_app_state_service.dart';

/// App settings that are stored on this device only.
class SettingsScreen extends StatefulWidget {
  /// [appState] can be replaced in tests.
  const SettingsScreen({super.key, this.appState});

  final LocalAppStateService? appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final LocalAppStateService _appState =
      widget.appState ?? LocalAppStateService();
  bool? _linkPreviews;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _appState.isLinkPreviewEnabled();
    if (!mounted) return;
    setState(() => _linkPreviews = enabled);
  }

  Future<void> _setLinkPreviews(bool value) async {
    setState(() => _linkPreviews = value);
    await _appState.setLinkPreviewEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _linkPreviews;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: enabled == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Превью ссылок'),
                  subtitle: const Text(
                    'Заголовок, описание и картинка загружаются через сервис '
                    'api.microlink.io, ему передаётся адрес каждой ссылки. '
                    'Если выключить, адреса никуда не отправляются.',
                  ),
                  value: enabled,
                  onChanged: _setLinkPreviews,
                ),
              ],
            ),
    );
  }
}
