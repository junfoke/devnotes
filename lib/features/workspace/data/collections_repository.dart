import 'dart:convert';
import 'dart:io';
import 'package:devnotes/features/workspace/domain/collection.dart';

class CollectionsRepository {
  final String storagePath;

  CollectionsRepository({required this.storagePath});

  Future<List<Collection>> loadCollections() async {
    final file = File(storagePath);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final collections =
        list.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
    // Sắp theo sortOrder (ổn định: cùng sortOrder thì giữ thứ tự trong file).
    final indexed = collections.asMap().entries.toList()
      ..sort((a, b) {
        final bySort = a.value.sortOrder.compareTo(b.value.sortOrder);
        return bySort != 0 ? bySort : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  /// Lưu thứ tự mới theo danh sách [orderedIds]; collection không có trong
  /// danh sách được giữ lại ở cuối.
  Future<void> reorderCollections(List<String> orderedIds) async {
    final all = await loadCollections();
    final byId = {for (final c in all) c.id: c};
    final ordered = [
      for (final id in orderedIds)
        if (byId.containsKey(id)) byId[id]!,
      for (final c in all)
        if (!orderedIds.contains(c.id)) c,
    ];
    await saveCollections([
      for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(sortOrder: i),
    ]);
  }

  Future<void> saveCollections(List<Collection> collections) async {
    final file = File(storagePath);
    final json = jsonEncode(collections.map((c) => c.toJson()).toList());
    await file.writeAsString(json);
  }

  /// Thay collection cùng `id` bằng [updated]; không có thì không làm gì.
  Future<void> updateCollection(Collection updated) async {
    final all = await loadCollections();
    await saveCollections([
      for (final c in all) c.id == updated.id ? updated : c,
    ]);
  }

  /// Xóa collection [id] khỏi danh sách.
  ///
  /// Chỉ bỏ nhóm — collection là bộ lọc ảo theo tag, **không** đụng tới file
  /// `.md` nào. Xem DECISIONS.md, "Xóa collection" (2026-10-24).
  Future<void> deleteCollection(String id) async {
    final all = await loadCollections();
    await saveCollections(all.where((c) => c.id != id).toList());
  }
}
