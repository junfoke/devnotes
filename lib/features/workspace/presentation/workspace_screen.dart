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

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    ref.read(searchQueryProvider.notifier).state = '';
    super.dispose();
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
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceAppBar(
              onSyncTap: () {},
              onGitStatusTap: () {},
              gitStatusColor: colors.success,
            ),
            WorkspaceSearchBar(
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
              collections: const [],
              selectedId: ref.watch(selectedCollectionProvider),
              onSelect: (id) =>
                  ref.read(selectedCollectionProvider.notifier).state = id,
              onAdd: () {},
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
                    if (notes.isEmpty) {
                      return EmptyState(onCreateFirst: _createNote);
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(noteListProvider);
                      },
                      child: ListView.separated(
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => Divider(
                          color: colors.border,
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        itemBuilder: (context, index) {
                          final note = notes[index];
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
        onPressed: _createNote,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
