import '../utils/sync_planner.dart';
import 'category.dart';

/// The server's category list as the sync needs it: one [SyncEntry] per
/// category (deletions included, as "tombstones") and the full content of the
/// live categories only.
class RemoteCategoriesSnapshot {
  const RemoteCategoriesSnapshot({
    required this.entries,
    required this.liveCategories,
  });

  /// Every category the server listed, with its change time and deletion flag.
  final List<SyncEntry> entries;

  /// Categories that are not deleted, by id.
  final Map<String, Category> liveCategories;

  /// Ids of everything the server has, tombstones included. A category in
  /// this set must be updated with `PUT` (which also brings a deleted
  /// category back), not created again.
  Set<String> get knownIds => {for (final e in entries) e.id};

  /// Change time of every category the server listed, by id.
  Map<String, int> get updatedAtById =>
      {for (final e in entries) e.id: e.updatedAt};

  /// Builds the snapshot from the decoded JSON list of `GET /categories`.
  ///
  /// A server that does not send `updated_timestamp` and `deleted` (an old
  /// one) is treated as having unchanged (time 0), undeleted categories.
  factory RemoteCategoriesSnapshot.fromJson(List<dynamic> json) {
    final entries = <SyncEntry>[];
    final liveCategories = <String, Category>{};
    for (final item in json) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String;
      final updatedAt = (map['updated_timestamp'] as num?)?.toInt() ?? 0;
      final deleted = _isDeleted(map['deleted']);
      entries.add(SyncEntry(id, updatedAt, deleted: deleted));
      // The content of a tombstone is never used, so it is not parsed.
      if (!deleted) liveCategories[id] = Category.fromJson(map);
    }
    return RemoteCategoriesSnapshot(
      entries: entries,
      liveCategories: liveCategories,
    );
  }

  static bool _isDeleted(Object? value) =>
      value == true || (value is num && value != 0);
}
