import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../utils/merge_helper.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Резервное копирование'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _exportData(context, ref),
              icon: const Icon(Icons.upload),
              label: const Text('Экспортировать данные'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _importData(context, ref),
              icon: const Icon(Icons.download),
              label: const Text('Импортировать данные'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final notesAsync = await ref
          .read(notesNotifierProvider(category: null, sort: 'new').future);
      final categoriesAsync = await ref.read(categoriesNotifierProvider.future);
      final settingsAsync = await ref.read(settingsNotifierProvider.future);

      final filePath = await BackupService.exportBackup(
        notes: notesAsync,
        categories: categoriesAsync,
        settings: settingsAsync,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бэкап сохранён: $filePath'),
          action: SnackBarAction(
            label: 'Поделиться',
            onPressed: () {
              Share.shareXFiles([XFile(filePath)], text: 'Мои заметки');
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final backup = await BackupService.pickAndParseBackup();
      if (backup == null) return;

      // Получаем текущие данные
      final currentCategories =
          await ref.read(categoriesNotifierProvider.future);
      final currentNotes = await ref
          .read(notesNotifierProvider(category: null, sort: 'new').future);
      final currentSettings = await ref.read(settingsNotifierProvider.future);

      // Находим новые категории
      final newCategories = MergeHelper.findNewCategories(
        current: currentCategories,
        imported: backup.categories,
      );

      // Находим новые заметки
      final newNotes = MergeHelper.findNewNotes(
        current: currentNotes,
        imported: backup.notes,
      );

      final settingsDiff =
          MergeHelper.isSettingsDifferent(currentSettings, backup.settings);

      if (newCategories.isEmpty && newNotes.isEmpty && !settingsDiff) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет новых данных для импорта')),
        );
        return;
      }

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Импорт данных'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (newCategories.isNotEmpty) ...[
                  Text('Новые категории (${newCategories.length}):'),
                  ...newCategories.map((c) => Text('• ${c.name}')),
                  const SizedBox(height: 8),
                ],
                if (newNotes.isNotEmpty) ...[
                  Text('Новые заметки (${newNotes.length}):'),
                  ...newNotes
                      .map((n) => Text('• ${n.title ?? 'Без заголовка'}')),
                  const SizedBox(height: 8),
                ],
                if (settingsDiff)
                  const Text('• Настройки отличаются (будут заменены)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Импортировать'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Добавляем новые категории
      for (final cat in newCategories) {
        await ref.read(categoriesNotifierProvider.notifier).addCategory(cat);
      }

      // Добавляем новые заметки
      for (final note in newNotes) {
        await ref
            .read(notesNotifierProvider(category: note.categoryId).notifier)
            .addNote(note);
      }

      if (settingsDiff) {
        await ref
            .read(settingsNotifierProvider.notifier)
            .updateSettings(backup.settings);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Импорт завершён. Добавлено: ${newCategories.length} категорий, ${newNotes.length} заметок.'),
        ),
      );

      // Обновляем все провайдеры
      ref.invalidate(notesNotifierProvider);
      ref.invalidate(categoriesNotifierProvider);
      ref.invalidate(settingsNotifierProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }
}
