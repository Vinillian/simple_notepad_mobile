import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../services/local_category_service.dart';
import '../services/local_note_service.dart';
import '../services/category_service.dart';
import '../utils/merge_helper.dart';
import 'notes_provider.dart';

part 'categories_provider.g.dart';

@riverpod
class CategoryNotesCount extends _$CategoryNotesCount {
  @override
  Future<Map<String, int>> build() async {
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
  late final LocalCategoryService _localService = LocalCategoryService();
  late final CategoryService _remoteService = CategoryService();

  @override
  Future<List<Category>> build() async {
    return _fetchLocalCategories();
  }

  Future<List<Category>> _fetchLocalCategories() async {
    return await _localService.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocalCategories());
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

  Future<void> syncWithRemote() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localCategories = await _localService.getCategories();
      final remoteCategories = await _remoteService.getCategories();

      final toAddToRemote = MergeHelper.findNewCategories(
        current: remoteCategories,
        imported: localCategories,
      );
      for (final cat in toAddToRemote) {
        await _remoteService.createCategory(cat);
      }

      final toAddToLocal = MergeHelper.findNewCategories(
        current: localCategories,
        imported: remoteCategories,
      );
      if (toAddToLocal.isNotEmpty) {
        await _localService.insertAll(toAddToLocal);
      }

      ref.invalidate(categoryNotesCountProvider);
      return await _localService.getCategories();
    });
  }

  Future<void> _syncCategoryToRemote(Category category) async {
    try {
      final remoteCategories = await _remoteService.getCategories();
      if (!remoteCategories.any((c) => c.id == category.id)) {
        await _remoteService.createCategory(category);
      }
    } catch (e) {}
  }

  Future<void> _deleteCategoryFromRemote(String id) async {
    try {
      await _remoteService.deleteCategory(id);
    } catch (e) {}
  }
}
