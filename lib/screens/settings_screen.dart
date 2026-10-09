import 'package:flutter/material.dart';
import '../services/local_app_state_service.dart';
import '../utils/constants.dart';
import '../utils/server_url.dart';

/// App settings that are stored on this device only.
class SettingsScreen extends StatefulWidget {
  /// Where the server address is kept. Defaults to the local database.
  final ServerUrlStorage? storage;

  const SettingsScreen({super.key, this.storage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ServerUrlStorage _storage;
  final TextEditingController _controller = TextEditingController();
  String? _error;
  String? _warning;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? LocalAppStateService();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    String? saved;
    try {
      saved = await _storage.getServerUrl();
    } catch (_) {
      saved = null;
    }
    if (!mounted) return;
    setState(() {
      _controller.text = saved ?? '';
      _warning = _warningFor(saved);
      _loading = false;
    });
  }

  String? _warningFor(String? url) {
    if (url == null || isCleartextAllowed(url)) return null;
    return 'Android блокирует http для этого адреса. Используйте https '
        'или добавьте хост в network_security_config.xml.';
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      await _reset();
      return;
    }
    final url = normalizeServerUrl(text);
    if (url == null) {
      setState(() {
        _error = 'Введите адрес вида http://host:3000/api или https://host/api';
        _warning = null;
      });
      return;
    }
    await _storage.setServerUrl(url);
    if (!mounted) return;
    setState(() {
      _controller.text = url;
      _error = null;
      _warning = _warningFor(url);
    });
    _showMessage('Адрес сервера сохранён');
  }

  Future<void> _reset() async {
    await _storage.setServerUrl(null);
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _error = null;
      _warning = null;
    });
    _showMessage('Используется адрес по умолчанию');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Сервер синхронизации',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  enabled: !_loading,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Адрес сервера',
                    hintText: ApiConstants.baseUrl,
                    helperText: 'Пусто: адрес по умолчанию (${ApiConstants.baseUrl})',
                    helperMaxLines: 2,
                    errorText: _error,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                if (_warning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _warning!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: const Text('Сохранить'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _loading ? null : _reset,
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Приватность'),
            subtitle: Text(
              'Заметки и адреса ссылок хранятся на этом устройстве. '
              'Приложение не обращается к сторонним сервисам. Данные '
              'отправляются только на ваш сервер синхронизации, если он '
              'настроен.',
            ),
          ),
        ],
      ),
    );
  }
}
