import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:uuid/uuid.dart';
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
      TooltipService.showTooltips(
        context: context,
        tooltipKey: 'workspace',
        targets: [
          TooltipService.createTarget(
            key: _searchKey,
            title: 'Search',
            description: 'Search through all your notes with full-text search.',
          ),
          TooltipService.createTarget(
            key: _syncKey,
            title: 'Sync',
            description: 'Tap to sync your notes with your Git repository.',
          ),
          TooltipService.createTarget(
            key: _fabKey,
            title: 'New Note',
            description: 'Create a new Markdown note.',
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

  void _createCollection() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateCollectionDialog(),
    );
    if (result == null) return;
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
  }

  void _createNote() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateNoteDialog(),
    );
    if (result == null) return;
    final note = await ref.read(createNoteProvider(
      (title: result['title'] as String, tags: result['tags'] as List<String>),
    ).future);
    if (mounted) {
      context.push('/editor/${Uri.encodeComponent(note.filePath)}');
    }
  }

  void _showNoteContextMenu(NoteFile note) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                final newTitle = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      RenameNoteDialog(currentTitle: note.title),
                );
                if (newTitle != null) {
                  await ref.read(renameNoteProvider(
                    (filePath: note.filePath, newTitle: newTitle),
                  ).future);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: Text(
                      'Delete "${note.title}"? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(
                    deleteNoteProvider(note.filePath).future,
                  );
                }
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
    ref.watch(searchIndexInitProvider);
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceAppBar(
              key: _syncKey,
              onSyncTap: () async {
                final config = await ref.read(gitConfigProvider.future);
                if (!context.mounted) return;
                if (config == null) {
                  context.push('/settings/git');
                  return;
                }
                // TODO: call SyncService.sync(config) when git client is implemented
              },
              onGitStatusTap: () {
                final syncState = ref.read(syncStateProvider);
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SyncHistorySheet(
                    branchName: syncState.branchName,
                    lastSyncAt: syncState.lastSyncAt,
                    entries: syncState.history,
                  ),
                );
              },
              onSettingsTap: () => context.push('/settings'),
              gitStatusColor: colors.success,
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
                              'No results found',
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
                        Center(child: Text('Search error: $e')),
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
                    if (displayNotes.isEmpty) {
                      return EmptyState(onCreateFirst: _createNote);
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
                                  title: const Text('Delete Note'),
                                  content: Text(
                                    'Delete "${note.title}"? This cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(
                                  deleteNoteProvider(note.filePath).future,
                                );
                              }
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
                  error: (e, _) => Center(child: Text('Error: $e')),
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
