import 'package:flutter/foundation.dart' as foundation;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';
import '../services/local_note_service.dart';
import '../services/note_service.dart';
import '../utils/sync_planner.dart';
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

  /// Recomputes the note counts of the categories.
  ///
  /// [categoryNotesCountProvider] watches the notifier with no category and
  /// the default sort. That notifier must not invalidate it: Riverpod treats
  /// it as a circular dependency (a debug-mode error). It does not need to,
  /// because every change of its state already rebuilds the counts.
  void _invalidateCategoryCounts() {
    if (category == null && sort == 'new') return;
    ref.invalidate(categoryNotesCountProvider);
  }

  Future<void> refresh({String? category, String sort = 'new'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocalNotes(category, sort));
  }

  Future<void> addNote(Note note) async {
    await _localService.createNote(note);
    await refresh(category: category, sort: sort);
    _invalidateCategoryCounts();
    _syncNoteToRemote(note);
  }

  Future<void> updateNote(String id, Note note) async {
    await _localService.updateNote(note);
    await refresh(category: category, sort: sort);
    _invalidateCategoryCounts();
    _updateNoteRemote(note);
  }

  Future<void> deleteNote(String id) async {
    await _localService.deleteNote(id);
    await refresh(category: category, sort: sort);
    _invalidateCategoryCounts();
    _deleteNoteRemote(id);
  }

  /// Syncs notes with the server; the last write wins.
  ///
  /// Edits and deletions go both ways: for every id the copy with the later
  /// `updatedTimestamp` wins (see [SyncPlanner]). A note deleted on this device
  /// is deleted on the server too, and a newer edit on the server replaces the
  /// local copy. A deletion made on the server is not noticed yet, because the
  /// server does not keep deleted notes.
  ///
  /// Network errors are rethrown to the caller and do not touch [state], so a
  /// failed sync never replaces the local list with an error.
  Future<void> syncWithRemote() async {
    final currentCategory = category;
    final currentSort = sort;

    final localEntries = await _localService.getSyncEntries();
    final remote = await _remoteService.getSnapshot();
    final remoteIds = remote.knownIds;

    final actions = SyncPlanner.plan(
      local: localEntries,
      remote: remote.entries,
    );

    final toPull = <Note>[];
    for (final entry in actions.entries) {
      final id = entry.key;
      switch (entry.value) {
        case SyncAction.pushToRemote:
          final localNote = await _localService.getNoteById(id);
          if (localNote != null) {
            if (remoteIds.contains(id)) {
              await _remoteService.updateNote(id, localNote);
            } else {
              await _remoteService.createNote(localNote);
            }
          }
        case SyncAction.pullToLocal:
          final remoteNote = remote.liveNotes[id];
          if (remoteNote != null) toPull.add(remoteNote);
        case SyncAction.deleteRemote:
          await _remoteService.deleteNote(id);
        case SyncAction.deleteLocal:
          await _localService.deleteNote(id);
      }
    }
    if (toPull.isNotEmpty) {
      await _localService.insertAll(toPull);
    }
    await _localService.purgeTombstones();

    _invalidateCategoryCounts();

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
