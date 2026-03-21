import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
import '../services/link_metadata_service.dart'; // новый импорт
import '../utils/merge_helper.dart';
import 'categories_provider.dart';

part 'notes_provider.g.dart';

@riverpod
class NotesNotifier extends _$NotesNotifier {
  late final LocalNoteService _localService = LocalNoteService();
  late final NoteService _remoteService = NoteService();

  @override
  Future<List<Note>> build({String? category, String sort = 'new'}) async {
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
    ref.invalidate(categoryNotesCountProvider);
    _syncNoteToRemote(note);

    // Если заметка является ссылкой, асинхронно загружаем метаданные
    if (note.type == 'link') {
      _fetchAndUpdateMetadata(note.id, note.content);
    }
  }

  Future<void> updateNote(double id, Note note) async {
    await _localService.updateNote(note);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _updateNoteRemote(note);

    // Если это ссылка и метаданные не заданы, можно обновить (по желанию)
    if (note.type == 'link' &&
        (note.metadata == null || note.metadata!.isEmpty)) {
      _fetchAndUpdateMetadata(note.id, note.content);
    }
  }

  Future<void> deleteNote(double id) async {
    await _localService.deleteNote(id);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _deleteNoteRemote(id);
  }

  Future<void> syncWithRemote() async {
    final currentCategory = category;
    final currentSort = sort;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localNotes = await _localService.getNotes();
      final remoteNotes = await _remoteService.getNotes();

      final toAddToRemote = MergeHelper.findNewNotes(
        current: remoteNotes,
        imported: localNotes,
      );
      for (final note in toAddToRemote) {
        await _remoteService.createNote(note);
      }

      final toAddToLocal = MergeHelper.findNewNotes(
        current: localNotes,
        imported: remoteNotes,
      );
      if (toAddToLocal.isNotEmpty) {
        await _localService.insertAll(toAddToLocal);
      }

      ref.invalidate(categoryNotesCountProvider);

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
      // Ошибка сети — игнорируем
    }
  }

  Future<void> _updateNoteRemote(Note note) async {
    try {
      await _remoteService.updateNote(note.id, note);
    } catch (e) {}
  }

  Future<void> _deleteNoteRemote(double id) async {
    try {
      await _remoteService.deleteNote(id);
    } catch (e) {}
  }

  // Новый метод для асинхронной загрузки метаданных
  Future<void> _fetchAndUpdateMetadata(double noteId, String url) async {
    final metadata = await LinkMetadataService.fetchMetadata(url);
    if (metadata.isNotEmpty) {
      // Получаем текущую заметку из локальной БД, чтобы не потерять другие поля
      final note = await _localService.getNoteById(noteId);
      if (note != null) {
        // Обновляем метаданные
        final updatedNote = Note(
          id: note.id,
          title: note.title,
          content: note.content,
          categoryId: note.categoryId,
          date: note.date,
          createdTimestamp: note.createdTimestamp,
          updatedTimestamp: note.updatedTimestamp,
          expanded: note.expanded,
          editMode: note.editMode,
          type: note.type,
          metadata: metadata,
        );
        await _localService.updateNote(updatedNote);
        // Обновляем UI
        await refresh(category: category, sort: sort);
        ref.invalidate(categoryNotesCountProvider);
        // Также синхронизируем с сервером, если нужно
        _updateNoteRemote(updatedNote);
      }
    }
  }
}
