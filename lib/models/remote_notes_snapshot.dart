import '../utils/note_id.dart';
import '../utils/sync_planner.dart';
import 'note.dart';

/// The server's note list as the sync needs it: one [SyncEntry] per note
/// (deletions included, as "tombstones") and the full content of the live
/// notes only.
class RemoteNotesSnapshot {
  const RemoteNotesSnapshot({required this.entries, required this.liveNotes});

  /// Every note the server listed, with its change time and deletion flag.
  final List<SyncEntry> entries;

  /// Notes that are not deleted, by id.
  final Map<String, Note> liveNotes;

  /// Ids of everything the server has, tombstones included. A note that is
  /// in this set must be updated with `PUT` (which also brings a deleted note
  /// back), not created again.
  Set<String> get knownIds => {for (final e in entries) e.id};

  /// Builds the snapshot from the decoded JSON list of `GET /notes`.
  ///
  /// A server that does not send the `deleted` field (or ignores
  /// `include_deleted`) is treated as having no deletions.
  factory RemoteNotesSnapshot.fromJson(List<dynamic> json) {
    final entries = <SyncEntry>[];
    final liveNotes = <String, Note>{};
    for (final item in json) {
      final map = item as Map<String, dynamic>;
      final id = noteIdFromValue(map['id']);
      final updatedAt = (map['updated_timestamp'] as num).toInt();
      final deleted = _isDeleted(map['deleted']);
      entries.add(SyncEntry(id, updatedAt, deleted: deleted));
      // The content of a tombstone is never used, so it is not parsed.
      if (!deleted) liveNotes[id] = Note.fromJson(map);
    }
    return RemoteNotesSnapshot(entries: entries, liveNotes: liveNotes);
  }

  static bool _isDeleted(Object? value) =>
      value == true || (value is num && value != 0);
}
