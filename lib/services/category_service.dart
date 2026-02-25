import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Category>> getCategories() async {
    final data = await _apiClient.get('/categories');
    return (data as List).map((json) => Category.fromJson(json)).toList();
  }

  Future<void> createCategory(Category category) async {
    await _apiClient.post('/categories', category.toJson());
  }

  Future<void> deleteCategory(String id) async {
    await _apiClient.delete('/categories/$id');
  }
}