// AC-traceability tests for NoteFileRepository.
// Bổ sung các Acceptance Criteria chưa được bảo vệ trong
// note_file_repository_test.dart (sanitize tên file, hậu tố trùng,
// bảo toàn metadata khi rename, bỏ qua file không phải .md).
//
// Quyết định: DECISIONS.md — "Tên file sinh từ tiêu đề note",
//             "File .md thiếu hoặc hỏng frontmatter"
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/file_system/note_file_repository.dart';

void main() {
  late Directory tempDir;
  late NoteFileRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_repo_ac_');
    repo = NoteFileRepository(workspacePath: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('UC-001 Create Note', () {
    // AC-1: tiêu đề được sanitize thành tên file an toàn (chữ thường, gạch ngang)
    test('AC-1: sanitizes title into safe lowercase hyphenated filename',
        () async {
      final note = await repo.createNote(title: 'My First Note!', tags: []);
      expect(p.basename(note.filePath), 'my-first-note.md');
    });

    // AC-2: trùng tên -> thêm hậu tố "-1", không ghi đè file cũ
    test('AC-2: appends -1 suffix on duplicate name without overwriting',
        () async {
      final first = await repo.createNote(title: 'Note', tags: []);
      final second = await repo.createNote(title: 'Note', tags: []);

      expect(p.basename(first.filePath), 'note.md');
      expect(p.basename(second.filePath), 'note-1.md');
      expect(File(first.filePath).existsSync(), isTrue);
      expect(File(second.filePath).existsSync(), isTrue);
    });

    // AC-4 (BR-1): tiêu đề tiếng Việt -> tên file ASCII bỏ dấu, title giữ dấu
    test('AC-4: Vietnamese title yields ASCII filename, title keeps diacritics',
        () async {
      final note = await repo.createNote(title: 'Ghi chú họp thứ 2', tags: []);

      expect(p.basename(note.filePath), 'ghi-chu-hop-thu-2.md');
      expect(note.title, 'Ghi chú họp thứ 2');

      final reread = await repo.readNote(note.filePath);
      expect(reread.title, 'Ghi chú họp thứ 2');
    });

    // AC-4 (BR-1): chữ đ/Đ phải map sang d, không bị loại bỏ
    test('AC-4: maps đ/Đ to d instead of dropping it', () async {
      final note = await repo.createNote(title: 'Đặt lịch đi chợ', tags: []);
      expect(p.basename(note.filePath), 'dat-lich-di-cho.md');
    });

    // AC-5 (BR-2): tên cơ sở rỗng -> "untitled", không tạo file ẩn ".md"
    test('AC-5: falls back to untitled when sanitized name is empty', () async {
      final note = await repo.createNote(title: '✨✨✨', tags: []);

      expect(p.basename(note.filePath), 'untitled.md');
      expect(note.title, '✨✨✨');

      final notes = await repo.listNotes();
      expect(notes.single.title, '✨✨✨');
    });

    // AC-5: hai tiêu đề cùng rơi vào fallback không ghi đè lên nhau
    test('AC-5: two unnameable titles do not collide', () async {
      final a = await repo.createNote(title: '✨', tags: []);
      final b = await repo.createNote(title: '🎉', tags: []);

      expect(p.basename(a.filePath), 'untitled.md');
      expect(p.basename(b.filePath), 'untitled-1.md');
    });

    // AC-6 (BR-3): tiêu đề chứa dấu nháy kép không làm hỏng frontmatter
    test('AC-6: title with double quotes survives a write/read roundtrip',
        () async {
      final note =
          await repo.createNote(title: 'Ghi chú "quan trọng"', tags: ['a"b']);

      final reread = await repo.readNote(note.filePath);
      expect(reread.title, 'Ghi chú "quan trọng"');
      expect(reread.tags, ['a"b']);
    });
  });

  group('UC-002 Rename Note', () {
    // AC-1: đổi tên giữ createdAt/tags/content, cập nhật updatedAt, xóa file cũ
    test('AC-1: preserves createdAt/tags/content and updates updatedAt',
        () async {
      final note = await repo.createNote(title: 'Old Name', tags: ['keep']);
      final saved = note.copyWith(content: '# Body');
      await repo.saveNote(saved);
      final before = await repo.readNote(note.filePath);

      await Future.delayed(const Duration(milliseconds: 10));
      final renamed = await repo.renameNote(note.filePath, 'New Name');

      expect(renamed.title, 'New Name');
      expect(renamed.tags, ['keep']);
      expect(renamed.content, '# Body');
      expect(renamed.createdAt, before.createdAt); // bất biến
      expect(renamed.updatedAt.isAfter(before.updatedAt), isTrue); // cập nhật
      expect(File(note.filePath).existsSync(), isFalse); // file cũ đã xóa
      expect(File(renamed.filePath).existsSync(), isTrue);
    });
  });

  group('UC-004 List Notes', () {
    // AC-2: chỉ liệt kê file .md, bỏ qua file khác (json, png, ...)
    test('AC-2: ignores non-markdown files', () async {
      await repo.createNote(title: 'Real Note', tags: []);
      File(p.join(tempDir.path, 'collections.json')).writeAsStringSync('[]');
      File(p.join(tempDir.path, 'image.png')).writeAsStringSync('fake');

      final notes = await repo.listNotes();

      expect(notes.length, 1);
      expect(notes.single.title, 'Real Note');
    });

    // AC-3 (BR-1): file .md không có frontmatter -> title từ heading H1
    test('AC-3: lists a .md file without frontmatter using its H1 as title',
        () async {
      final file = File(p.join(tempDir.path, 'README.md'))
        ..writeAsStringSync('# Project Docs\n\nHello');

      final notes = await repo.listNotes();

      expect(notes.length, 1);
      expect(notes.single.title, 'Project Docs');
      expect(notes.single.content, '# Project Docs\n\nHello');
      expect(
        notes.single.updatedAt.toUtc(),
        file.lastModifiedSync().toUtc(),
      );
    });

    // AC-4 (BR-1): không frontmatter, không H1 -> title từ tên file
    test('AC-4: falls back to the file name when there is no heading',
        () async {
      File(p.join(tempDir.path, 'ghi-chu-cu.md'))
          .writeAsStringSync('chỉ là văn bản thường');

      final notes = await repo.listNotes();

      expect(notes.single.title, 'ghi-chu-cu');
    });

    // AC-5 (BR-1): frontmatter thiếu trường thời gian -> không crash
    test('AC-5: does not throw when frontmatter misses timestamps', () async {
      File(p.join(tempDir.path, 'partial.md')).writeAsStringSync(
        '---\ntitle: "Only Title"\n---\n\nbody',
      );

      final notes = await repo.listNotes();

      expect(notes.length, 1);
      expect(notes.single.title, 'Only Title');
      expect(notes.single.content, 'body');
    });

    // E1: file .md hỏng không được chặn phần còn lại của danh sách
    test('E1: a broken frontmatter file does not break the whole listing',
        () async {
      await repo.createNote(title: 'Good', tags: []);
      File(p.join(tempDir.path, 'broken.md'))
          .writeAsStringSync('---\ntitle: "unclosed\ntags: [oops\n---\n\nbody');

      final notes = await repo.listNotes();

      expect(notes.length, 2);
      expect(notes.map((n) => n.title), contains('Good'));
    });
  });
}
