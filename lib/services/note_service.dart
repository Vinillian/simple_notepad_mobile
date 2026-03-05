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

  Future<Note> getNoteById(double id) async {
    // double
    final data = await _apiClient.get('/notes/$id');
    return Note.fromJson(data);
  }

  Future<void> createNote(Note note) async {
    await _apiClient.post('/notes', note.toJson());
  }

  Future<void> updateNote(double id, Note note) async {
    // double
    await _apiClient.put('/notes/$id', note.toJson());
  }

  Future<void> deleteNote(double id) async {
    // double
    await _apiClient.delete('/notes/$id');
  }
}
