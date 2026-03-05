import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../services/local_category_service.dart';
import '../services/local_note_service.dart'; // Добавлен импорт
import '../services/category_service.dart';
import '../utils/merge_helper.dart';
import 'notes_provider.dart'; // Добавлен импорт

part 'categories_provider.g.dart';

// Провайдер для получения количества заметок в каждой категории
@riverpod
class CategoryNotesCount extends _$CategoryNotesCount {
  @override
  Future<Map<String, int>> build() async {
    // Подписываемся на изменения в заметках
    ref.watch(notesNotifierProvider(category: null, sort: 'new'));

    final localNoteService = LocalNoteService();
    final notes = await localNoteService.getNotes();

    final Map<String, int> countMap = {};
    for (var note in notes) {
      countMap[note.categoryId] = (countMap[note.categoryId] ?? 0) + 1;
    }
    return countMap;
  }
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  late final LocalCategoryService _localService;
  late final CategoryService _remoteService;

  @override
  Future<List<Category>> build() async {
    _localService = LocalCategoryService();
    _remoteService = CategoryService();
    return _fetchLocalCategories();
  }

  Future<List<Category>> _fetchLocalCategories() async {
    return await _localService.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocalCategories());
    // Обновляем счетчик заметок
    ref.invalidate(categoryNotesCountProvider);
  }

  Future<void> addCategory(Category category) async {
    await _localService.createCategory(category);
    await refresh();
    _syncCategoryToRemote(category);
  }

  Future<void> deleteCategory(String id) async {
    await _localService.deleteCategory(id);
    await refresh();
    _deleteCategoryFromRemote(id);
  }

  // Синхронизация с сервером: добавить недостающие на сервере категории
  Future<void> syncWithRemote() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localCategories = await _localService.getCategories();
      final remoteCategories = await _remoteService.getCategories();

      // Категории, которые есть локально, но нет на сервере
      final toAddToRemote = MergeHelper.findNewCategories(
        current: remoteCategories,
        imported: localCategories,
      );
      for (final cat in toAddToRemote) {
        await _remoteService.createCategory(cat);
      }

      // Категории, которые есть на сервере, но нет локально
      final toAddToLocal = MergeHelper.findNewCategories(
        current: localCategories,
        imported: remoteCategories,
      );
      if (toAddToLocal.isNotEmpty) {
        await _localService.insertAll(toAddToLocal);
      }

      // Обновляем счетчик заметок
      ref.invalidate(categoryNotesCountProvider);

      // Возвращаем обновлённые локальные категории
      return await _localService.getCategories();
    });
  }

  Future<void> _syncCategoryToRemote(Category category) async {
    try {
      final remoteCategories = await _remoteService.getCategories();
      if (!remoteCategories.any((c) => c.id == category.id)) {
        await _remoteService.createCategory(category);
      }
    } catch (e) {
      // Игнорируем ошибки сети, синхронизация будет позже
    }
  }

  Future<void> _deleteCategoryFromRemote(String id) async {
    try {
      await _remoteService.deleteCategory(id);
    } catch (e) {
      // игнорируем
    }
  }
}
