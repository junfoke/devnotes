// Sửa/xóa collection chỉ thay đổi nhóm ảo, không bao giờ đụng tới ghi chú.
//
// Quyết định: DECISIONS.md — "Xóa collection" (2026-10-24)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/features/workspace/data/collections_repository.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

void main() {
  late Directory workspace;
  late CollectionsRepository repo;

  const work = Collection(
    id: 'work',
    name: 'Work',
    icon: Icons.folder,
    color: Color(0xFF9C27B0),
    filterTags: ['work'],
  );
  const home = Collection(
    id: 'home',
    name: 'Home',
    icon: Icons.folder,
    color: Color(0xFF2196F3),
    filterTags: ['home'],
  );

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('devnotes_collections_');
    repo = CollectionsRepository(
        storagePath: p.join(workspace.path, 'collections.json'));
    await repo.saveCollections([work, home]);
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('xóa collection chỉ bỏ nhóm, các note có tag đó vẫn còn nguyên',
      () async {
    final note = File(p.join(workspace.path, 'hop.md'))
      ..writeAsStringSync('---\ntitle: "Họp"\ntags: ["work"]\n---\n\nnội dung');

    await repo.deleteCollection('work');

    expect(await repo.loadCollections(), [home]);
    expect(note.existsSync(), isTrue);
    expect(note.readAsStringSync(), contains('nội dung'));
  });

  test('xóa id không tồn tại thì danh sách giữ nguyên', () async {
    await repo.deleteCollection('khong-co');

    expect(await repo.loadCollections(), [work, home]);
  });

  test('sửa tên và tag giữ nguyên id và vị trí trong danh sách', () async {
    await repo.updateCollection(
        work.copyWith(name: 'Công việc', filterTags: ['work', 'meeting']));

    final loaded = await repo.loadCollections();
    expect(loaded.map((c) => c.id), ['work', 'home']);
    expect(loaded.first.name, 'Công việc');
    expect(loaded.first.filterTags, ['work', 'meeting']);
  });

  test('sắp xếp lại collection: lưu thứ tự mới, tải lên đúng thứ tự đó',
      () async {
    await repo.reorderCollections(['home', 'work']);

    final loaded = await repo.loadCollections();
    expect(loaded.map((c) => c.id), ['home', 'work']);
    expect(loaded.map((c) => c.sortOrder), [0, 1]);
  });

  test('collection lưu lộn thứ tự trong file vẫn tải lên theo sortOrder',
      () async {
    await repo.saveCollections(
        [work.copyWith(sortOrder: 5), home.copyWith(sortOrder: 1)]);

    final loaded = await repo.loadCollections();
    expect(loaded.map((c) => c.id), ['home', 'work']);
  });
}
