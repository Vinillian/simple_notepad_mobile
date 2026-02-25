import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart'; // ← необходимо для создания объекта Category
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/loading_indicator.dart';
import 'note_edit_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedCategory;
  String sortOrder = 'new';

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      notesNotifierProvider(category: selectedCategory, sort: sortOrder),
    );
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        actions: [
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
      body: Column(
        children: [
          // Фильтр по категориям
          categoriesAsync.when(
            data: (categories) {
              final allCategories = [
                // custom: false → заменяем на 0 (ложь)
                Category(id: 'all', name: 'Все', color: '#7f8c8d', custom: 0),
                ...categories,
              ];
              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allCategories.length,
                  itemBuilder: (ctx, i) {
                    final cat = allCategories[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        category: cat,
                        isSelected: selectedCategory == cat.id,
                        onTap: () {
                          setState(() {
                            selectedCategory = cat.id == 'all' ? null : cat.id;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
            error: (e, s) =>
                Center(child: Text('Ошибка загрузки категорий: $e')),
            loading: () => const SizedBox(height: 50),
          ),
          // Список заметок
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
                                    category: selectedCategory, sort: sortOrder)
                                .notifier)
                            .deleteNote(notes[i].id);
                      }
                    },
                  ),
                );
              },
              error: (e, s) => Center(child: Text('Ошибка: $e')),
              loading: () => const LoadingIndicator(),
            ),
          ),
        ],
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
}
