import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/data/collections_repository.dart';
import 'package:devnotes/features/workspace/domain/collection.dart';

void main() {
  late CollectionsRepository repo;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_collections_test_');
    repo = CollectionsRepository(storagePath: '${tempDir.path}/collections.json');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('CollectionsRepository', () {
    test('starts with empty list', () async {
      final collections = await repo.loadCollections();
      expect(collections, isEmpty);
    });

    test('save and load roundtrip', () async {
      final col = Collection(
        id: 'col-1',
        name: 'Flutter',
        filterTags: ['flutter'],
        icon: Icons.folder,
        color: Colors.purple,
      );
      await repo.saveCollections([col]);
      final loaded = await repo.loadCollections();
      expect(loaded.length, 1);
      expect(loaded[0].name, 'Flutter');
      expect(loaded[0].filterTags, ['flutter']);
    });

    test('overwrite replaces all', () async {
      final col1 = Collection(
        id: '1', name: 'A', filterTags: ['a'],
        icon: Icons.folder, color: Colors.red,
      );
      final col2 = Collection(
        id: '2', name: 'B', filterTags: ['b'],
        icon: Icons.folder, color: Colors.blue,
      );
      await repo.saveCollections([col1, col2]);
      await repo.saveCollections([col1]);
      final loaded = await repo.loadCollections();
      expect(loaded.length, 1);
    });
  });
}
