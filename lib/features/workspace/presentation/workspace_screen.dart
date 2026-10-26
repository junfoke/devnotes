import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_app_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_search_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/collections_row.dart';
import 'package:devnotes/features/workspace/presentation/widgets/note_list_item.dart';
import 'package:devnotes/features/workspace/presentation/widgets/empty_state.dart';
import 'package:devnotes/features/workspace/presentation/widgets/create_note_dialog.dart';
import 'package:devnotes/features/workspace/presentation/widgets/rename_note_dialog.dart';
import 'package:devnotes/features/workspace/application/search_providers.dart';
import 'package:devnotes/features/workspace/presentation/widgets/search_results_list.dart';
import 'package:devnotes/features/workspace/application/collections_providers.dart';
import 'package:devnotes/features/workspace/presentation/widgets/create_collection_dialog.dart';
import 'package:devnotes/features/workspace/presentation/widgets/collection_actions.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/git_sync/application/sync_runner.dart';
import 'package:devnotes/features/git_sync/presentation/conflict_screen.dart';
import 'package:devnotes/features/git_sync/presentation/git_messages.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/presentation/widgets/sync_history_sheet.dart';
import 'package:devnotes/features/onboarding/application/tooltip_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  final _searchKey = GlobalKey();
  final _syncKey = GlobalKey();
  final _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l = context.l10n;
      TooltipService.showTooltips(
        context: context,
        tooltipKey: 'workspace',
        targets: [
          TooltipService.createTarget(
            key: _searchKey,
            title: l.tooltipSearchTitle,
            description: l.tooltipSearchDesc,
          ),
          TooltipService.createTarget(
            key: _syncKey,
            title: l.tooltipSyncTitle,
            description: l.tooltipSyncDesc,
          ),
          TooltipService.createTarget(
            key: _fabKey,
            title: l.newNote,
            description: l.tooltipNewNoteDesc,
            align: ContentAlign.top,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    ref.read(searchQueryProvider.notifier).state = '';
    super.dispose();
  }

  void _showSyncSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Chạy một thao tác; lỗi thì báo bằng snackbar thay vì im lặng.
  /// [failMessage] dựng câu báo đã dịch từ chi tiết lỗi.
  Future<T?> _guard<T>(
    String Function(AppLocalizations l, String error) failMessage,
    Future<T> Function() op,
  ) async {
    try {
      return await op();
    } catch (e) {
      if (mounted) {
        // Lỗi do app ném ra (vd. đang sync nên đổi tên báo bận) được dịch.
        final l = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failMessage(l, describeError(l, e)))));
      }
      return null;
    }
  }

  Future<void> _deleteNote(NoteFile note) =>
      _guard((l, e) => l.noteDeleteFailed(e),
          () => ref.read(noteActionsProvider).delete(note.filePath));

  void _createCollection() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateCollectionDialog(),
    );
    if (result == null) return;
    await _guard((l, e) => l.collectionCreateFailed(e), () async {
      final existing = await ref.read(collectionsProvider.future);
      final repo = await ref.read(collectionsRepositoryProvider.future);
      final newCol = Collection(
        id: const Uuid().v4(),
        name: result['name'] as String,
        filterTags: result['tags'] as List<String>,
        icon: Icons.folder,
        color: Colors.blue,
        sortOrder: existing.length,
      );
      await repo.saveCollections([...existing, newCol]);
      ref.invalidate(collectionsProvider);
    });
  }

  void _createNote() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateNoteDialog(),
    );
    if (result == null) return;
    final note = await _guard(
      (l, e) => l.noteCreateFailed(e),
      () => ref.read(noteActionsProvider).create(
            title: result['title'] as String,
            tags: result['tags'] as List<String>,
          ),
    );
    if (note != null && mounted) {
      context.push('/editor/${Uri.encodeComponent(note.filePath)}');
    }
  }

  void _showNoteContextMenu(NoteFile note) {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.commonRename),
              onTap: () async {
                Navigator.pop(context);
                final newTitle = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      RenameNoteDialog(currentTitle: note.title),
                );
                if (newTitle != null) {
                  final result = await _guard(
                    (l, e) => l.noteRenameFailed(e),
                    () => ref
                        .read(noteActionsProvider)
                        .rename(note.filePath, newTitle),
                  );
                  // Note không sửa được link (đọc/ghi lỗi) phải báo, không
                  // để link gãy lặng lẽ.
                  final failed = result?.failedFiles ?? const <String>[];
                  if (failed.isNotEmpty && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.noteLinksUpdateFailed(
                          failed.map(p.basename).join(', '))),
                    ));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l.commonDelete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l.deleteNoteTitle),
                    content: Text(l.deleteNoteConfirm(note.title)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.commonCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.commonDelete,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    ref.watch(searchIndexInitProvider);
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceAppBar(
              key: _syncKey,
              isSyncing: ref.watch(syncStateProvider).status == SyncStatus.syncing,
              onSyncTap: () async {
                final config = await ref.read(gitConfigProvider.future);
                if (!context.mounted) return;
                if (config == null) {
                  context.push('/settings/git');
                  return;
                }

                final outcome = await ref.read(syncControllerProvider).sync();
                if (!context.mounted) return;

                final result = outcome.result;
                if (outcome.skipped == SyncSkipReason.alreadyRunning) {
                  _showSyncSnack(l.syncAlreadyRunning);
                } else if (outcome.error case final error?) {
                  _showSyncSnack(l.syncError(describeError(l, error)));
                } else if (result == null) {
                  // Bỏ qua vì lý do khác — không có gì để báo.
                } else if (result.conflicts.isNotEmpty) {
                  context.push(ConflictScreen.location(result.conflicts.first));
                } else if (result.success) {
                  _showSyncSnack(l.syncDone(result.filesChanged));
                } else {
                  _showSyncSnack(l.syncFailed(result.error ?? l.unknownError));
                }
              },
              onGitStatusTap: () async {
                // Lịch sử và thời điểm sync gần nhất đọc từ SQLite nên vẫn
                // đúng sau khi khởi động lại app.
                final loaded = await _guard(
                  (l, e) => l.syncHistoryLoadFailed(e),
                  () async => (
                    await ref.read(syncHistoryProvider.future),
                    await ref.read(lastSuccessfulSyncProvider.future),
                    await ref.read(currentBranchProvider.future),
                  ),
                );
                if (loaded == null || !context.mounted) return;
                final (entries, lastSyncAt, branch) = loaded;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SyncHistorySheet(
                    branchName: branch,
                    lastSyncAt: lastSyncAt,
                    entries: entries,
                  ),
                );
              },
              onSettingsTap: () => context.push('/settings'),
              gitStatusColor: () {
                final syncStatus = ref.watch(syncStateProvider).status;
                final hasConfig = ref.watch(gitConfigProvider).valueOrNull != null;
                if (!hasConfig) return colors.textMuted;
                switch (syncStatus) {
                  case SyncStatus.synced:
                  case SyncStatus.success:
                    return colors.success;
                  case SyncStatus.syncing:
                  case SyncStatus.pending:
                    return colors.warning;
                  case SyncStatus.error:
                  case SyncStatus.conflict:
                    return colors.error;
                  default:
                    return colors.textMuted;
                }
              }(),
            ),
            WorkspaceSearchBar(
              key: _searchKey,
              controller: _searchController,
              onChanged: (q) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(
                  const Duration(milliseconds: 300),
                  () => ref.read(searchQueryProvider.notifier).state = q,
                );
              },
              onTap: () {},
            ),
            CollectionsRow(
              collections: ref.watch(collectionsProvider).valueOrNull ?? [],
              selectedId: ref.watch(selectedCollectionProvider),
              onSelect: (id) =>
                  ref.read(selectedCollectionProvider.notifier).state = id,
              onAdd: _createCollection,
              onLongPress: (col) =>
                  CollectionActions.showMenu(context, ref, col),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: () {
                final query = ref.watch(searchQueryProvider);
                if (query.trim().isNotEmpty) {
                  final searchAsync = ref.watch(searchResultsProvider);
                  return searchAsync.when(
                    data: (results) => results.isEmpty
                        ? Center(
                            child: Text(
                              l.searchNoResults,
                              style: TextStyle(color: colors.textMuted),
                            ),
                          )
                        : SearchResultsList(
                            results: results,
                            onTap: (filePath) => context.push(
                                '/editor/${Uri.encodeComponent(filePath)}'),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text(l.searchError('$e'))),
                  );
                }
                return notesAsync.when(
                  data: (notes) {
                    var displayNotes = notes;
                    final selectedId = ref.watch(selectedCollectionProvider);
                    if (selectedId != null) {
                      final collections = ref.watch(collectionsProvider).valueOrNull ?? [];
                      final selected = collections.where((c) => c.id == selectedId).firstOrNull;
                      if (selected != null && selected.filterTags.isNotEmpty) {
                        displayNotes = notes.where((note) =>
                          note.tags.any((tag) => selected.filterTags.contains(tag))
                        ).toList();
                      }
                    }
                    if (notes.isEmpty) {
                      return EmptyState(onCreateFirst: _createNote);
                    }
                    if (displayNotes.isEmpty) {
                      // Có note nhưng collection đang chọn không khớp note
                      // nào — đừng nói "chưa có ghi chú" như workspace trống.
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.collectionNoNotes,
                                style: TextStyle(color: colors.textMuted)),
                            TextButton(
                              onPressed: () => ref
                                  .read(selectedCollectionProvider.notifier)
                                  .state = null,
                              child: Text(l.collectionShowAll),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(noteListProvider);
                      },
                      child: ListView.separated(
                        itemCount: displayNotes.length,
                        separatorBuilder: (_, __) => Divider(
                          color: colors.border,
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        itemBuilder: (context, index) {
                          final note = displayNotes[index];
                          return NoteListItem(
                            note: note,
                            onTap: () => context.push(
                              '/editor/${Uri.encodeComponent(note.filePath)}',
                            ),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(l.deleteNoteTitle),
                                  content: Text(l.deleteNoteConfirm(note.title)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l.commonCancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        l.commonDelete,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) await _deleteNote(note);
                            },
                            onLongPress: () {
                              _showNoteContextMenu(note);
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.noteListLoadFailed('$e'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error)),
                        TextButton(
                          onPressed: () => ref.invalidate(noteListProvider),
                          child: Text(l.commonRetry),
                        ),
                      ],
                    ),
                  ),
                );
              }(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: _createNote,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
