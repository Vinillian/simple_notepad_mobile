import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

part 'notes_provider.g.dart';

@riverpod
class NotesNotifier extends _$NotesNotifier {
  late final NoteService _noteService;

  @override
  Future<List<Note>> build({String? category, String sort = 'new'}) async {
    _noteService = NoteService();
    return _fetchNotes(category, sort);
  }

  Future<List<Note>> _fetchNotes(String? category, String sort) async {
    return await _noteService.getNotes(category: category, sort: sort);
  }

  Future<void> refresh({String? category, String sort = 'new'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotes(category, sort));
  }

  Future<void> addNote(Note note) async {
    await _noteService.createNote(note);
    await refresh(category: category, sort: sort);
  }

  Future<void> updateNote(int id, Note note) async {
    await _noteService.updateNote(id, note);
    await refresh(category: category, sort: sort);
  }

  Future<void> deleteNote(int id) async {
    await _noteService.deleteNote(id);
    await refresh(category: category, sort: sort);
  }
}