import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_app_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/workspace_search_bar.dart';
import 'package:devnotes/features/workspace/presentation/widgets/collections_row.dart';
import 'package:devnotes/features/workspace/presentation/widgets/note_list_item.dart';
import 'package:devnotes/features/workspace/presentation/widgets/empty_state.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNote() {
    // TODO: Task 10 will implement create note dialog
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
              onChanged: (q) {},
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
              child: notesAsync.when(
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
                            // TODO: Task 10 — delete with confirmation
                          },
                          onLongPress: () {
                            // TODO: Task 10 — context menu
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
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
