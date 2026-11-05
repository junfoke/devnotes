import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/features/workspace/application/collections_providers.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/features/workspace/presentation/widgets/collection_actions.dart';

/// Settings → Manage Collections: danh sách collection kèm nút sửa/xóa.
class ManageCollectionsScreen extends ConsumerWidget {
  const ManageCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final l = context.l10n;
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      l.settingsSectionCollections,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: collectionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l.errorWithDetail('$e'))),
                data: (collections) => collections.isEmpty
                    ? Center(
                        child: Text(
                          l.collectionsEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textMuted),
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: collections.length,
                        onReorder: (oldIndex, newIndex) => _reorder(
                          context,
                          ref,
                          collections,
                          oldIndex,
                          newIndex,
                        ),
                        itemBuilder: (context, index) {
                          final c = collections[index];
                          return ListTile(
                            key: ValueKey(c.id),
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                color: colors.textMuted,
                              ),
                            ),
                            title: Text(
                              c.name,
                              style: TextStyle(color: colors.textPrimary),
                            ),
                            subtitle: Text(
                              c.filterTags.isEmpty
                                  ? l.allNotes
                                  : c.filterTags.map((t) => '#$t').join(' '),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l.commonEdit,
                                  icon: Icon(
                                    Icons.edit,
                                    color: colors.textSecondary,
                                  ),
                                  onPressed: () =>
                                      CollectionActions.edit(context, ref, c),
                                ),
                                IconButton(
                                  tooltip: l.commonDelete,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      CollectionActions.delete(context, ref, c),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kéo thả xong: lưu thứ tự mới (sortOrder), chip ở màn chính đổi theo.
  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<Collection> current,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final ids = [for (final c in current) c.id];
    ids.insert(newIndex, ids.removeAt(oldIndex));
    try {
      final repo = await ref.read(collectionsRepositoryProvider.future);
      await repo.reorderCollections(ids);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.collectionEditFailed('$e'))),
        );
      }
    }
    ref.invalidate(collectionsProvider);
  }
}
