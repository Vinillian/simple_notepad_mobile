import 'package:flutter/foundation.dart' as foundation;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
import '../services/link_metadata_service.dart';
import '../services/local_app_state_service.dart';
import '../utils/merge_helper.dart';
import 'categories_provider.dart';

part 'notes_provider.g.dart';

@riverpod
class NotesNotifier extends _$NotesNotifier {
  late final LocalNoteService _localService = LocalNoteService();
  late final NoteService _remoteService = NoteService();
  late final LocalAppStateService _appState = LocalAppStateService();

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

    if (note.type == 'link') {
      _fetchAndUpdateMetadata(note.id, note.content);
    }
  }

  Future<void> updateNote(String id, Note note) async {
    await _localService.updateNote(note);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _updateNoteRemote(note);

    if (note.type == 'link' &&
        (note.metadata == null || note.metadata!.isEmpty)) {
      _fetchAndUpdateMetadata(note.id, note.content);
    }
  }

  Future<void> deleteNote(String id) async {
    await _localService.deleteNote(id);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _deleteNoteRemote(id);
  }

  /// Merges local and remote notes.
  ///
  /// Network errors are rethrown to the caller and do not touch [state], so a
  /// failed sync never replaces the local list with an error.
  Future<void> syncWithRemote() async {
    final currentCategory = category;
    final currentSort = sort;

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

    state = AsyncValue.data(await _localService.getNotes(
        category: currentCategory, sort: currentSort));
  }

  /// Sends a new note to the server in a single request, without downloading
  /// the whole list first. A failure, including an id the server already has,
  /// is only logged: the note is safe locally.
  Future<void> _syncNoteToRemote(Note note) async {
    try {
      await _remoteService.createNote(note);
    } catch (e) {
      foundation.debugPrint('_syncNoteToRemote error: $e');
    }
  }

  Future<void> _updateNoteRemote(Note note) async {
    try {
      await _remoteService.updateNote(note.id, note);
    } catch (e) {
      foundation.debugPrint('_updateNoteRemote error: $e');
    }
  }

  Future<void> _deleteNoteRemote(String id) async {
    try {
      await _remoteService.deleteNote(id);
    } catch (e) {
      foundation.debugPrint('_deleteNoteRemote error: $e');
    }
  }

  Future<void> _fetchAndUpdateMetadata(String noteId, String url) async {
    // The user can turn previews off: then the URL is not sent to microlink.io.
    if (!await _appState.isLinkPreviewEnabled()) return;

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