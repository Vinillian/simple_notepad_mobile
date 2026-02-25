import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../services/category_service.dart';

part 'categories_provider.g.dart';

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  late final CategoryService _categoryService;

  @override
  Future<List<Category>> build() async {
    _categoryService = CategoryService();
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    return await _categoryService.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> addCategory(Category category) async {
    await _categoryService.createCategory(category);
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryService.deleteCategory(id);
    await refresh();
  }
}