import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/features/workspace/domain/note_file.dart';

void main() {
  group('NoteFile', () {
    final noteFile = NoteFile(
      filePath: '/workspace/notes/hello.md',
      fileName: 'hello.md',
      title: 'Hello',
      lastModified: DateTime(2026, 3, 1),
      collectionId: 'col-1',
    );

    test('creates with all fields', () {
      expect(noteFile.filePath, '/workspace/notes/hello.md');
      expect(noteFile.fileName, 'hello.md');
      expect(noteFile.title, 'Hello');
      expect(noteFile.lastModified, DateTime(2026, 3, 1));
      expect(noteFile.collectionId, 'col-1');
    });

    test('copyWith updates specified fields', () {
      final updated = noteFile.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.filePath, noteFile.filePath);
      expect(updated.fileName, noteFile.fileName);
      expect(updated.lastModified, noteFile.lastModified);
      expect(updated.collectionId, noteFile.collectionId);
    });

    test('copyWith can update collectionId to null', () {
      final updated = noteFile.copyWith(collectionId: null);
      expect(updated.collectionId, isNull);
    });

    test('equality is based on filePath only', () {
      final sameFile = NoteFile(
        filePath: '/workspace/notes/hello.md',
        fileName: 'different.md',
        title: 'Different Title',
        lastModified: DateTime(2025, 1, 1),
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
        fileName: 'different.md',
        title: 'Different Title',
        lastModified: DateTime(2025, 1, 1),
      );
      expect(noteFile.hashCode, sameFile.hashCode);
    });

    test('collectionId defaults to null when not provided', () {
      final fileWithoutCollection = NoteFile(
        filePath: '/some/file.md',
        fileName: 'file.md',
        title: 'File',
        lastModified: DateTime(2026, 1, 1),
      );
      expect(fileWithoutCollection.collectionId, isNull);
    });
  });
}
