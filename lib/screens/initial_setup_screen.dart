import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_screen.dart'; // исправлен импорт
import '../providers/categories_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/local_category_service.dart'; // добавлен
import '../services/local_note_service.dart'; // добавлен
import '../services/local_settings_service.dart'; // добавлен

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добро пожаловать'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.note_alt, size: 100, color: Colors.green),
            const SizedBox(height: 32),
            const Text(
              'Похоже, у вас ещё нет данных. '
              'Вы можете создать новую базу, импортировать из файла '
              'или загрузить данные с сервера, если доступно соединение.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _createNewDatabase,
                icon: const Icon(Icons.create),
                label: const Text('Начать с пустой базы'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _importFromBackup,
                icon: const Icon(Icons.upload_file),
                label: const Text('Импортировать из файла'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _syncFromServer,
                icon: const Icon(Icons.sync),
                label: const Text('Загрузить с сервера'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _createNewDatabase() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _importFromBackup() async {
    setState(() => _isLoading = true);
    try {
      final backup = await BackupService.pickAndParseBackup();
      if (backup == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Создаём экземпляры локальных сервисов
      final localCategoryService = LocalCategoryService();
      final localNoteService = LocalNoteService();
      final localSettingsService = LocalSettingsService();

      await localCategoryService.deleteAll();
      await localNoteService.deleteAll();
      await localSettingsService.deleteAll();

      for (var cat in backup.categories) {
        await localCategoryService.createCategory(cat);
      }
      for (var note in backup.notes) {
        await localNoteService.createNote(note);
      }
      await localSettingsService.updateSettings(backup.settings);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncFromServer() async {
    setState(() => _isLoading = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // connectivityResult теперь List<ConnectivityResult>
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет подключения к интернету')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Синхронизируем все провайдеры (они загрузят с сервера в локальную БД)
      await ref.read(categoriesNotifierProvider.notifier).syncWithRemote();
      await ref
          .read(notesNotifierProvider(category: null, sort: 'new').notifier)
          .syncWithRemote();
      await ref.read(settingsNotifierProvider.notifier).syncWithRemote();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
