// test/core/file_system/note_file_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/note_file_repository.dart';
import 'package:devnotes/core/file_system/frontmatter_parser.dart';

void main() {
  late Directory tempDir;
  late NoteFileRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_test_');
    repo = NoteFileRepository(workspacePath: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('NoteFileRepository', () {
    test('createNote creates .md file with frontmatter', () async {
      final note = await repo.createNote(title: 'Test Note', tags: ['dart']);
      expect(note.title, 'Test Note');
      expect(note.tags, ['dart']);
      final file = File(note.filePath);
      expect(file.existsSync(), isTrue);
      final raw = file.readAsStringSync();
      final parsed = FrontmatterParser.parse(raw);
      expect(parsed.title, 'Test Note');
    });

    test('listNotes returns all .md files sorted by updatedAt desc', () async {
      await repo.createNote(title: 'Note 1', tags: []);
      await Future.delayed(Duration(milliseconds: 10)); // ensure different timestamps
      await repo.createNote(title: 'Note 2', tags: []);
      final notes = await repo.listNotes();
      expect(notes.length, 2);
      // Most recently updated first
      expect(notes[0].title, 'Note 2');
    });

    test('readNote reads existing file', () async {
      final created = await repo.createNote(title: 'Read Me', tags: ['test']);
      final read = await repo.readNote(created.filePath);
      expect(read.title, 'Read Me');
      expect(read.tags, ['test']);
    });

    test('saveNote writes updated content', () async {
      final note = await repo.createNote(title: 'Original', tags: []);
      final updated = note.copyWith(title: 'Updated Title', content: '# Updated Content');
      await repo.saveNote(updated);
      final read = await repo.readNote(note.filePath);
      expect(read.title, 'Updated Title');
      expect(read.content, '# Updated Content');
    });

    test('deleteNote removes file', () async {
      final note = await repo.createNote(title: 'Delete Me', tags: []);
      await repo.deleteNote(note.filePath);
      expect(File(note.filePath).existsSync(), isFalse);
    });

    test('renameNote moves file and updates title', () async {
      final note = await repo.createNote(title: 'Old Name', tags: []);
      final renamed = await repo.renameNote(note.filePath, 'New Name');
      expect(renamed.title, 'New Name');
      expect(File(note.filePath).existsSync(), isFalse);
      expect(File(renamed.filePath).existsSync(), isTrue);
    });

    test('createNote handles duplicate names', () async {
      final note1 = await repo.createNote(title: 'Same Name', tags: []);
      final note2 = await repo.createNote(title: 'Same Name', tags: []);
      expect(note1.filePath, isNot(equals(note2.filePath)));
    });
  });
}
