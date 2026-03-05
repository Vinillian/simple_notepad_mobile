import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/category.dart'; // убран неиспользуемый импорт
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/loading_indicator.dart';
import 'note_edit_screen.dart';
import 'categories_screen.dart';
import 'backup_screen.dart';
import 'initial_setup_screen.dart';
import '../services/local_category_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedCategory;
  String sortOrder = 'new';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkIfEmpty();
  }

  Future<void> _checkIfEmpty() async {
    final localCategoryService = LocalCategoryService();
    final categories = await localCategoryService.getCategories();
    if (categories.isEmpty && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      notesNotifierProvider(category: selectedCategory, sort: sortOrder),
    );
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    // final settingsAsync = ref.watch(settingsNotifierProvider); // убрана неиспользуемая переменная

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        actions: [
          IconButton(
            icon: Icon(_isSyncing ? Icons.sync_disabled : Icons.sync),
            onPressed: _isSyncing ? null : _syncData,
            tooltip: 'Синхронизировать с сервером',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
            tooltip: 'Управление категориями',
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
            tooltip: 'Резервное копирование',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                sortOrder = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new', child: Text('Сначала новые')),
              const PopupMenuItem(value: 'old', child: Text('Сначала старые')),
            ],
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCategory ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Все категории'),
                    ),
                    ...categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(int.parse(cat.color.substring(1),
                                        radix: 16) +
                                    0xFF000000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value == '' ? null : value;
                    });
                  },
                ),
              ),
              Expanded(
                child: notesAsync.when(
                  data: (notes) {
                    if (notes.isEmpty) {
                      return const Center(child: Text('Нет заметок'));
                    }
                    return ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (ctx, i) => NoteCard(
                        note: notes[i],
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditScreen(note: notes[i]),
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(notesNotifierProvider);
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Удаление'),
                              content: const Text('Удалить заметку?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(notesNotifierProvider(
                                        category: selectedCategory,
                                        sort: sortOrder)
                                    .notifier)
                                .deleteNote(notes[i].id);
                          }
                        },
                      ),
                    );
                  },
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки заметок:\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(notesNotifierProvider);
                            ref.invalidate(categoriesNotifierProvider);
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LoadingIndicator(),
                ),
              ),
            ],
          );
        },
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки категорий:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(categoriesNotifierProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditScreen()),
          );
          if (result == true) {
            ref.invalidate(notesNotifierProvider);
          }
        },
      ),
    );
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(categoriesNotifierProvider.notifier).syncWithRemote();
      await ref
          .read(
              notesNotifierProvider(category: selectedCategory, sort: sortOrder)
                  .notifier)
          .syncWithRemote();
      await ref.read(settingsNotifierProvider.notifier).syncWithRemote();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Синхронизация завершена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }
}
