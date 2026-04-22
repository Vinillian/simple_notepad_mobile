import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
import '../services/link_metadata_service.dart';
import '../utils/merge_helper.dart';
import '../utils/helpers.dart'; // для plainTextFromMarkdown
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
    // Генерируем previewText для Markdown-заметок
    final noteWithPreview = _addPreviewText(note);
    await _localService.createNote(noteWithPreview);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _syncNoteToRemote(noteWithPreview);

    if (noteWithPreview.type == 'link') {
      _fetchAndUpdateMetadata(noteWithPreview.id, noteWithPreview.content);
    }
  }

  Future<void> updateNote(double id, Note note) async {
    final noteWithPreview = _addPreviewText(note);
    await _localService.updateNote(noteWithPreview);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _updateNoteRemote(noteWithPreview);

    if (noteWithPreview.type == 'link' &&
        (noteWithPreview.metadata == null ||
            noteWithPreview.metadata!.isEmpty)) {
      _fetchAndUpdateMetadata(noteWithPreview.id, noteWithPreview.content);
    }
  }

  Note _addPreviewText(Note note) {
    if (note.type == 'note') {
      final preview = plainTextFromMarkdown(note.content);
      return Note(
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
        metadata: note.metadata,
        previewText: preview,
      );
    }
    return note;
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
        // Убедимся, что у пришедших заметок есть previewText
        final notesWithPreview = toAddToLocal.map((n) {
          if (n.type == 'note' && n.previewText == null) {
            return Note(
              id: n.id,
              title: n.title,
              content: n.content,
              categoryId: n.categoryId,
              date: n.date,
              createdTimestamp: n.createdTimestamp,
              updatedTimestamp: n.updatedTimestamp,
              expanded: n.expanded,
              editMode: n.editMode,
              type: n.type,
              metadata: n.metadata,
              previewText: plainTextFromMarkdown(n.content),
            );
          }
          return n;
        }).toList();
        await _localService.insertAll(notesWithPreview);
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

  Future<void> _fetchAndUpdateMetadata(double noteId, String url) async {
    final metadata = await LinkMetadataService.fetchMetadata(url);
    if (metadata.isNotEmpty) {
      final note = await _localService.getNoteById(noteId);
      if (note != null) {
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
          previewText: note.previewText,
        );
        await _localService.updateNote(updatedNote);
        await refresh(category: category, sort: sort);
        ref.invalidate(categoryNotesCountProvider);
        _updateNoteRemote(updatedNote);
      }
    }
  }
}
