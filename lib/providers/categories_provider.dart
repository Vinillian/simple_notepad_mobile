import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../services/local_category_service.dart';
import '../services/category_service.dart'; // для удалённой синхронизации
import '../utils/merge_helper.dart';

part 'categories_provider.g.dart';

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
  }

  Future<void> addCategory(Category category) async {
    await _localService.createCategory(category);
    await refresh();
    // Опционально: попытаться отправить на сервер в фоне
    _syncCategoryToRemote(category);
  }

  Future<void> deleteCategory(String id) async {
    await _localService.deleteCategory(id);
    await refresh();
    // Опционально: удалить с сервера
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

      // Возвращаем обновлённые локальные категории
      return await _localService.getCategories();
    });
  }

  Future<void> _syncCategoryToRemote(Category category) async {
    try {
      // Проверяем, есть ли уже такая на сервере
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
