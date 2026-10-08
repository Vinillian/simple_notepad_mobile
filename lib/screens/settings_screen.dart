import 'package:flutter/material.dart';

/// App settings that are stored on this device only.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: const [
          ListTile(
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
