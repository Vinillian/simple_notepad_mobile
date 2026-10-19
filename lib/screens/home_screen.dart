import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_status_provider.dart';
import '../utils/sync_error.dart';
import '../utils/sync_retry_policy.dart';
import '../widgets/note_card.dart';
import '../widgets/loading_indicator.dart';
import 'note_edit_screen.dart';
import 'categories_screen.dart';
import 'backup_screen.dart';
import 'settings_screen.dart';
import 'initial_setup_screen.dart';
import '../services/local_app_state_service.dart';
import '../utils/helpers.dart';
import '../services/local_category_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedCategory;
  String sortOrder = 'new';
  bool _isSyncing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Retries of a failed sync (see [SyncRetryPolicy]).
  Timer? _retryTimer;
  int _retryAttempt = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    // When the network comes back, send what could not be sent.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && ref.read(syncPendingProvider) && !_isSyncing) {
        _retryAttempt = 0;
        _syncData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    final delay = SyncRetryPolicy.delayFor(_retryAttempt);
    if (delay == null) return;
    _retryTimer = Timer(delay, () {
      _retryAttempt++;
      if (mounted && !_isSyncing && ref.read(syncPendingProvider)) {
        _syncData(silent: true);
      }
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryAttempt = 0;
  }

  /// Shows the welcome screen only on the very first launch.
  /// Having no categories is not enough: the user may have deleted them all.
  Future<void> _checkFirstRun() async {
    final appState = LocalAppStateService();
    if (await appState.isSetupComplete()) return;

    final categories = await LocalCategoryService().getCategories();
    if (categories.isNotEmpty) {
      // Data already exists, so the setup was effectively done.
      await appState.markSetupComplete();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      notesNotifierProvider(category: selectedCategory, sort: sortOrder),
    );
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final syncPending = ref.watch(syncPendingProvider);
    // Changes that are not on the server yet: try again after a while.
    ref.listen<bool>(syncPendingProvider, (previous, next) {
      if (next) {
        _scheduleRetry();
      } else {
        _cancelRetry();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        actions: [
          IconButton(
            icon: Icon(
              _isSyncing
                  ? Icons.sync_disabled
                  : (syncPending ? Icons.sync_problem : Icons.sync),
              color: syncPending && !_isSyncing ? Colors.orange : null,
            ),
            onPressed: _isSyncing ? null : () => _syncData(),
            tooltip: syncPending
                ? 'Есть изменения, не отправленные на сервер. Нажмите, чтобы повторить'
                : 'Синхронизировать с сервером',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
            tooltip: 'Управление категориями',
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
            tooltip: 'Резервное копирование',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Настройки',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                sortOrder = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new', child: Text('Сначала новые')),
              const PopupMenuItem(value: 'old', child: Text('Сначала старые')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заголовку или тексту...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCategory ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Все категории'),
                    ),
                    ...categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: hexToColor(category.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(category.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value == '' ? null : value;
                    });
                  },
                ),
              ),
              Expanded(
                child: notesAsync.when(
                  data: (notes) {
                    final filteredNotes = _searchQuery.isEmpty
                        ? notes
                        : notes.where((note) {
                      final title = note.title?.toLowerCase() ?? '';
                      final content = note.content.toLowerCase();
                      return title.contains(_searchQuery) ||
                          content.contains(_searchQuery);
                    }).toList();

                    if (filteredNotes.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Нет заметок'
                              : 'Ничего не найдено',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (ctx, i) => NoteCard(
                        note: filteredNotes[i],
                        onTap: filteredNotes[i].type != 'link'
                            ? () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NoteEditScreen(note: filteredNotes[i]),
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(notesNotifierProvider);
                          }
                        }
                            : null,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Удаление'),
                              content: const Text('Удалить заметку?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(notesNotifierProvider(
                                category: selectedCategory,
                                sort: sortOrder)
                                .notifier)
                                .deleteNote(filteredNotes[i].id);
                          }
                        },
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NoteEditScreen(note: filteredNotes[i]),
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(notesNotifierProvider);
                          }
                        },
                      ),
                    );
                  },
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки заметок:\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(notesNotifierProvider);
                            ref.invalidate(categoriesNotifierProvider);
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LoadingIndicator(),
                ),
              ),
            ],
          );
        },
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки категорий:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(categoriesNotifierProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  NoteEditScreen(initialCategoryId: selectedCategory),
            ),
          );
          if (result == true) {
            ref.invalidate(notesNotifierProvider);
          }
        },
      ),
    );
  }

  /// Syncs with the server. A [silent] run (the automatic retry) shows a
  /// message only when it has sent the waiting changes.
  Future<void> _syncData({bool silent = false}) async {
    if (_isSyncing) return;
    if (!silent) _cancelRetry();
    setState(() => _isSyncing = true);
    try {
      await ref.read(categoriesNotifierProvider.notifier).syncWithRemote();
      await ref
          .read(
          notesNotifierProvider(category: selectedCategory, sort: sortOrder)
              .notifier)
          .syncWithRemote();
      // Again: the server deletes a category only after its notes are gone,
      // which the notes sync has just done.
      await ref.read(categoriesNotifierProvider.notifier).syncWithRemote();
      await ref.read(settingsNotifierProvider.notifier).syncWithRemote();

      if (!mounted) return;
      final hadPending = ref.read(syncPendingProvider);
      await ref.read(syncPendingProvider.notifier).clear();
      _retryAttempt = 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(silent && hadPending
                ? 'Изменения отправлены на сервер'
                : 'Синхронизация завершена'),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Sync failed: $e');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
      if (!mounted) return;
      await ref.read(syncPendingProvider.notifier).markPending();
      _scheduleRetry();
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось синхронизировать: ${describeSyncError(e)}. '
              'Локальные заметки не изменены, повторю позже.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
