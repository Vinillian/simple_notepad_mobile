import '../models/category.dart';
import '../models/remote_categories_snapshot.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Category>> getCategories() async {
    final data = await _apiClient.get('/categories');
    return (data as List).map((json) => Category.fromJson(json)).toList();
  }

  /// Every category on the server, deleted ones included, for the sync.
  Future<RemoteCategoriesSnapshot> getSnapshot() async {
    final data = await _apiClient.get('/categories?include_deleted=1');
    return RemoteCategoriesSnapshot.fromJson(data as List);
  }

  /// Creates the category. [updatedAt] is the change time kept on the device,
  /// so that both sides agree on it; the server uses its own clock without it.
  Future<void> createCategory(Category category, {int? updatedAt}) async {
    await _apiClient.post('/categories', {
      ...category.toJson(),
      if (updatedAt != null) 'updated_timestamp': updatedAt,
    });
  }

  /// Updates the category, and brings it back if the server has it deleted.
  Future<void> updateCategory(Category category, {required int updatedAt}) async {
    await _apiClient.put('/categories/${Uri.encodeComponent(category.id)}', {
      ...category.toJson(),
      'updated_timestamp': updatedAt,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _apiClient.delete('/categories/${Uri.encodeComponent(id)}');
  }
}
