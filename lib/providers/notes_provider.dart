import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
import '../utils/merge_helper.dart';

part 'notes_provider.g.dart';

@riverpod
class NotesNotifier extends _$NotesNotifier {
  late final LocalNoteService _localService;
  late final NoteService _remoteService;

  @override
  Future<List<Note>> build({String? category, String sort = 'new'}) async {
    _localService = LocalNoteService();
    _remoteService = NoteService();
    return _fetchLocalNotes(category, sort);
  }

  Future<List<Note>> _fetchLocalNotes(String? category, String sort) async {
    return await _localService.getNotes(category: category, sort: sort);
  }

  Future<void> refresh({String? category, String sort = 'new'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocalNotes(category, sort));
  }

  Future<void> addNote(Note note) async {
    await _localService.createNote(note);
    await refresh(category: category, sort: sort);
    _syncNoteToRemote(note);
  }

  Future<void> updateNote(int id, Note note) async {
    await _localService.updateNote(note);
    await refresh(category: category, sort: sort);
    _updateNoteRemote(note);
  }

  Future<void> deleteNote(int id) async {
    await _localService.deleteNote(id);
    await refresh(category: category, sort: sort);
    _deleteNoteRemote(id);
  }

  // Синхронизация с сервером
  Future<void> syncWithRemote() async {
    final currentCategory = category; // убраны лишние this.
    final currentSort = sort; // убраны лишние this.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localNotes = await _localService.getNotes();
      final remoteNotes = await _remoteService.getNotes();

      // Заметки, которые есть локально, но нет на сервере
      final toAddToRemote = MergeHelper.findNewNotes(
        current: remoteNotes,
        imported: localNotes,
      );
      for (final note in toAddToRemote) {
        await _remoteService.createNote(note);
      }

      // Заметки, которые есть на сервере, но нет локально
      final toAddToLocal = MergeHelper.findNewNotes(
        current: localNotes,
        imported: remoteNotes,
      );
      if (toAddToLocal.isNotEmpty) {
        await _localService.insertAll(toAddToLocal);
      }

      // Возвращаем обновлённые локальные заметки с учётом фильтра
      return await _localService.getNotes(
          category: currentCategory, sort: currentSort);
    });
  }

  Future<void> _syncNoteToRemote(Note note) async {
    try {
      final remoteNotes = await _remoteService.getNotes();
      if (!remoteNotes.any((n) => n.id == note.id)) {
        await _remoteService.createNote(note);
      }
    } catch (e) {
      // Ошибка сети - игнорируем, синхронизируем позже
    }
  }

  Future<void> _updateNoteRemote(Note note) async {
    try {
      await _remoteService.updateNote(note.id, note);
    } catch (e) {
      // Ошибка сети - игнорируем
    }
  }

  Future<void> _deleteNoteRemote(int id) async {
    try {
      await _remoteService.deleteNote(id);
    } catch (e) {
      // Ошибка сети - игнорируем
    }
  }
}
