/// One item as seen by one side of the sync (the device or the server).
///
/// A deletion is kept as a "tombstone": the item is still listed, with
/// [deleted] set and [updatedAt] set to the time of the deletion.
class SyncEntry {
  const SyncEntry(this.id, this.updatedAt, {this.deleted = false});

  final String id;

  /// Time of the last change in milliseconds since the epoch.
  final int updatedAt;

  final bool deleted;
}

/// What has to be done for one id so that both sides end up the same.
enum SyncAction {
  /// Create or update the item on the server.
  pushToRemote,

  /// Create or update the item on the device.
  pullToLocal,

  /// Delete the item on the server.
  deleteRemote,

  /// Delete the item on the device.
  deleteLocal,
}

/// Decides what to do with every id after comparing the local and the remote
/// lists. It only compares ids, timestamps and deletion flags, so it has no
/// dependency on the database or the network and is easy to test.
///
/// Rules (the last write wins):
/// - An id that exists on one side only is copied to the other side, unless it
///   is a tombstone (there is nothing to delete on the side that never had it).
/// - When both sides have the id, the side with the greater `updatedAt` wins:
///   its content is copied, or its deletion is applied.
/// - With equal timestamps a deletion wins over an edit, and two live copies
///   are treated as equal.
/// - Two tombstones need nothing, whatever their timestamps.
class SyncPlanner {
  const SyncPlanner._();

  /// Returns the actions for the ids that need one; ids that are already in
  /// sync are left out.
  static Map<String, SyncAction> plan({
    required List<SyncEntry> local,
    required List<SyncEntry> remote,
  }) {
    final localById = {for (final e in local) e.id: e};
    final remoteById = {for (final e in remote) e.id: e};
    final ids = {...localById.keys, ...remoteById.keys};

    final actions = <String, SyncAction>{};
    for (final id in ids) {
      final action = _decide(localById[id], remoteById[id]);
      if (action != null) actions[id] = action;
    }
    return actions;
  }

  static SyncAction? _decide(SyncEntry? local, SyncEntry? remote) {
    if (local == null && remote == null) return null;

    if (remote == null) {
      return local!.deleted ? null : SyncAction.pushToRemote;
    }
    if (local == null) {
      return remote.deleted ? null : SyncAction.pullToLocal;
    }

    // Both sides already agree that the item is gone.
    if (local.deleted && remote.deleted) return null;

    if (local.updatedAt > remote.updatedAt) {
      return local.deleted ? SyncAction.deleteRemote : SyncAction.pushToRemote;
    }
    if (remote.updatedAt > local.updatedAt) {
      return remote.deleted ? SyncAction.deleteLocal : SyncAction.pullToLocal;
    }

    // Equal timestamps.
    if (local.deleted && !remote.deleted) return SyncAction.deleteRemote;
    if (remote.deleted && !local.deleted) return SyncAction.deleteLocal;
    return null;
  }
}
