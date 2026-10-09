import 'package:flutter/foundation.dart' as foundation;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
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
  }

  Future<void> updateNote(String id, Note note) async {
    await _localService.updateNote(note);
    await refresh(category: category, sort: sort);
    ref.invalidate(categoryNotesCountProvider);
    _updateNoteRemote(note);
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
}
