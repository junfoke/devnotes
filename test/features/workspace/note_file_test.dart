import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';
import 'package:devnotes/core/utils/enums.dart';

void main() {
  group('NoteFile', () {
    final noteFile = NoteFile(
      filePath: '/workspace/notes/hello.md',
      title: 'Hello',
      tags: ['dart', 'flutter'],
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
      syncStatus: SyncStatus.idle,
      content: '# Hello',
      collectionId: 'col-1',
    );

    test('creates with all fields', () {
      expect(noteFile.filePath, '/workspace/notes/hello.md');
      expect(noteFile.title, 'Hello');
      expect(noteFile.tags, ['dart', 'flutter']);
      expect(noteFile.createdAt, DateTime(2026, 3, 1));
      expect(noteFile.updatedAt, DateTime(2026, 3, 1));
      expect(noteFile.syncStatus, SyncStatus.idle);
      expect(noteFile.content, '# Hello');
      expect(noteFile.collectionId, 'col-1');
    });

    test('copyWith updates specified fields', () {
      final updated = noteFile.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.filePath, noteFile.filePath);
      expect(updated.tags, noteFile.tags);
      expect(updated.createdAt, noteFile.createdAt);
      expect(updated.updatedAt, noteFile.updatedAt);
      expect(updated.collectionId, noteFile.collectionId);
    });

    test('copyWith can update collectionId to null', () {
      final updated = noteFile.copyWith(collectionId: null);
      expect(updated.collectionId, isNull);
    });

    test('copyWith can update conflictRef to null', () {
      final withConflict = noteFile.copyWith(conflictRef: 'ref-abc');
      final cleared = withConflict.copyWith(conflictRef: null);
      expect(cleared.conflictRef, isNull);
    });

    test('equality is based on filePath only', () {
      final sameFile = NoteFile(
        filePath: '/workspace/notes/hello.md',
        title: 'Different Title',
        tags: [],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.idle,
        content: '',
        collectionId: 'col-99',
      );
      expect(noteFile, equals(sameFile));
    });

    test('inequality when filePath differs', () {
      final differentFile = noteFile.copyWith(filePath: '/other/path.md');
      expect(noteFile, isNot(equals(differentFile)));
    });

    test('hashCode is consistent with equality', () {
      final sameFile = NoteFile(
        filePath: '/workspace/notes/hello.md',
        title: 'Different Title',
        tags: [],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.idle,
        content: '',
      );
      expect(noteFile.hashCode, sameFile.hashCode);
    });

    test('collectionId defaults to null when not provided', () {
      final fileWithoutCollection = NoteFile(
        filePath: '/some/file.md',
        title: 'File',
        tags: [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        syncStatus: SyncStatus.idle,
        content: '',
      );
      expect(fileWithoutCollection.collectionId, isNull);
    });

    test('conflictRef defaults to null when not provided', () {
      expect(noteFile.conflictRef, isNull);
    });
  });
}
