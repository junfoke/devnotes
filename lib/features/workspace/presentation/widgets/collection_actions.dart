import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/workspace/application/collections_providers.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';
import 'package:devnotes/features/workspace/presentation/widgets/create_collection_dialog.dart';

/// Thao tác sửa/xóa collection, dùng chung cho menu nhấn giữ chip ở
/// Workspace và màn Settings → Manage Collections.
class CollectionActions {
  static Future<void> edit(
      BuildContext context, WidgetRef ref, Collection collection) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateCollectionDialog(initial: collection),
    );
    if (result == null) return;
    final repo = await ref.read(collectionsRepositoryProvider.future);
    await repo.updateCollection(collection.copyWith(
      name: result['name'] as String,
      filterTags: result['tags'] as List<String>,
    ));
    ref.invalidate(collectionsProvider);
  }

  /// Hỏi xác nhận rồi xóa. Chỉ bỏ nhóm — note bên trong giữ nguyên.
  static Future<void> delete(
      BuildContext context, WidgetRef ref, Collection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa collection "${collection.name}"?'),
        content: const Text(
            'Chỉ xóa nhóm. Các ghi chú bên trong vẫn giữ nguyên trong All Notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repo = await ref.read(collectionsRepositoryProvider.future);
    await repo.deleteCollection(collection.id);
    // Collection đang lọc vừa bị xóa thì quay về All Notes.
    if (ref.read(selectedCollectionProvider) == collection.id) {
      ref.read(selectedCollectionProvider.notifier).state = null;
    }
    ref.invalidate(collectionsProvider);
  }

  /// Bottom sheet Sửa / Xóa khi nhấn giữ một chip collection.
  static void showMenu(
      BuildContext context, WidgetRef ref, Collection collection) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                edit(context, ref, collection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                delete(context, ref, collection);
              },
            ),
          ],
        ),
      ),
    );
  }
}
