import '../models/note.dart';
import 'api_client.dart';

class NoteService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Note>> getNotes({String? category, String sort = 'new'}) async {
    String endpoint = '/notes';
    if (category != null && category != 'all') {
      endpoint += '?category=$category&sort=$sort';
    } else {
      endpoint += '?sort=$sort';
    }
    final data = await _apiClient.get(endpoint);
    return (data as List).map((json) => Note.fromJson(json)).toList();
  }

  Future<Note> getNoteById(String id) async {
    final data = await _apiClient.get('/notes/${Uri.encodeComponent(id)}');
    return Note.fromJson(data);
  }

  Future<void> createNote(Note note) async {
    await _apiClient.post('/notes', note.toJson());
  }

  Future<void> updateNote(String id, Note note) async {
    await _apiClient.put('/notes/${Uri.encodeComponent(id)}', note.toJson());
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.delete('/notes/${Uri.encodeComponent(id)}');
  }
}
