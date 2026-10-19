import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_app_state_service.dart';

/// Whether some local changes may not be on the server yet.
///
/// It is set when a change could not be sent right away or a sync failed, and
/// cleared when a full sync succeeds. The sync compares change times, so a
/// change that was not sent is found and sent by the next sync; this flag
/// only tells the user about it and triggers that sync again. It is stored,
/// so it survives a restart of the app.
class SyncPendingNotifier extends Notifier<bool> {
  final LocalAppStateService _storage = LocalAppStateService();

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      if (await _storage.isSyncPending()) state = true;
    } catch (_) {
      // The flag is only a hint, a failed read is not worth an error.
    }
  }

  Future<void> markPending() async {
    if (!state) state = true;
    try {
      await _storage.setSyncPending(true);
    } catch (_) {}
  }

  Future<void> clear() async {
    if (state) state = false;
    try {
      await _storage.setSyncPending(false);
    } catch (_) {}
  }
}

final syncPendingProvider =
    NotifierProvider<SyncPendingNotifier, bool>(SyncPendingNotifier.new);
