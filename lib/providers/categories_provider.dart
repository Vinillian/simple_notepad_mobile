import 'package:flutter/foundation.dart' as foundation;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/category.dart';
import '../services/local_category_service.dart';
import '../services/local_note_service.dart';
import '../services/category_service.dart';
import '../utils/sync_planner.dart';
import 'notes_provider.dart';

part 'categories_provider.g.dart';

@riverpod
class CategoryNotesCount extends _$CategoryNotesCount {
  @override
  Future<Map<String, int>> build() async {
    ref.watch(notesNotifierProvider(category: null, sort: 'new'));
    final localNoteService = LocalNoteService();
    final notes = await localNoteService.getNotes();
    final Map<String, int> countMap = {};
    for (var note in notes) {
      countMap[note.categoryId] = (countMap[note.categoryId] ?? 0) + 1;
    }
    return countMap;
  }
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  late final LocalCategoryService _localService = LocalCategoryService();
  late final CategoryService _remoteService = CategoryService();

  @override
  Future<List<Category>> build() async {
    return _fetchLocalCategories();
  }

  Future<List<Category>> _fetchLocalCategories() async {
    return await _localService.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocalCategories());
    ref.invalidate(categoryNotesCountProvider);
  }

  Future<void> addCategory(Category category) async {
    final updatedAt = await _localService.createCategory(category);
    await refresh();
    _syncCategoryToRemote(category, updatedAt);
  }

  /// Saves the new name and colour of a category, then sends them to the
  /// server. If the request fails, the next sync sends the change, because
  /// the local change time is newer.
  Future<void> updateCategory(Category category) async {
    final updatedAt = await _localService.updateCategory(category);
    await refresh();
    _pushCategoryUpdate(category, updatedAt);
  }

  Future<void> deleteCategory(String id) async {
    await _localService.deleteCategory(id);
    await refresh();
    _deleteCategoryFromRemote(id);
  }

  /// Syncs categories with the server; the last write wins.
  ///
  /// For every id the copy with the later change time wins (see
  /// [SyncPlanner]): a category created, changed or deleted on one side is
  /// created, changed or deleted on the other. Deletions are kept as
  /// tombstones on both sides, so a deleted category does not come back.
  ///
  /// The server refuses to delete a category that still has notes, and the
  /// notes of a deleted category are only deleted on the server by the notes
  /// sync, which runs after this one. Such a deletion is therefore left for
  /// the next run (the home screen runs this sync again after the notes).
  /// A category deleted on the server that still has notes on this device is
  /// kept and sent to the server again, so those notes keep their category.
  ///
  /// Network errors are rethrown to the caller and do not touch [state], so a
  /// failed sync never replaces the local list with an error.
  Future<void> syncWithRemote() async {
    final localEntries = await _localService.getSyncEntries();
    final remote = await _remoteService.getSnapshot();
    final remoteIds = remote.knownIds;
    final remoteUpdatedAt = remote.updatedAtById;
    final localUpdatedAt = {for (final e in localEntries) e.id: e.updatedAt};

    final actions = SyncPlanner.plan(
      local: localEntries,
      remote: remote.entries,
    );

    final toPull = <Category>[];
    for (final entry in actions.entries) {
      final id = entry.key;
      switch (entry.value) {
        case SyncAction.pushToRemote:
          final localCategory = await _localService.getCategoryById(id);
          if (localCategory != null) {
            await _pushCategory(
              localCategory,
              localUpdatedAt[id] ?? 0,
              existsOnServer: remoteIds.contains(id),
            );
          }
        case SyncAction.pullToLocal:
          final remoteCategory = remote.liveCategories[id];
          if (remoteCategory != null) toPull.add(remoteCategory);
        case SyncAction.deleteRemote:
          try {
            await _remoteService.deleteCategory(id);
          } catch (e) {
            foundation.debugPrint('Category $id is not deleted on the server '
                'yet, will retry on the next sync: $e');
          }
        case SyncAction.deleteLocal:
          final categoryToDelete = await _localService.getCategoryById(id);
          if (categoryToDelete == null) break;
          if (await _localService.hasLiveNotes(id)) {
            final now = DateTime.now().millisecondsSinceEpoch;
            await _localService.setUpdatedTimestamp(id, now);
            await _pushCategory(categoryToDelete, now, existsOnServer: true);
          } else {
            await _localService.deleteCategory(id);
          }
      }
    }
    if (toPull.isNotEmpty) {
      await _localService.insertAll(toPull, updatedAt: remoteUpdatedAt);
    }
    await _localService.purgeTombstones();

    ref.invalidate(categoryNotesCountProvider);
    state = AsyncValue.data(await _localService.getCategories());
  }

  Future<void> _pushCategory(
    Category category,
    int updatedAt, {
    required bool existsOnServer,
  }) async {
    if (existsOnServer) {
      await _remoteService.updateCategory(category, updatedAt: updatedAt);
    } else {
      await _remoteService.createCategory(category, updatedAt: updatedAt);
    }
  }

  /// Sends a new category to the server in a single request, without
  /// downloading the whole list first. A failure is only logged.
  Future<void> _syncCategoryToRemote(Category category, int updatedAt) async {
    try {
      await _remoteService.createCategory(category, updatedAt: updatedAt);
    } catch (e) {
      foundation.debugPrint('_syncCategoryToRemote error: $e');
    }
  }

  Future<void> _pushCategoryUpdate(Category category, int updatedAt) async {
    try {
      await _remoteService.updateCategory(category, updatedAt: updatedAt);
    } catch (e) {
      foundation.debugPrint('_pushCategoryUpdate error: $e');
    }
  }

  Future<void> _deleteCategoryFromRemote(String id) async {
    try {
      await _remoteService.deleteCategory(id);
    } catch (e) {
      foundation.debugPrint('_deleteCategoryFromRemote error: $e');
    }
  }
}
