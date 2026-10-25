// Nhập ghi chú từ file ZIP không bao giờ được làm mất hay ghi đè note đang có,
// và không được ghi ra ngoài workspace.
//
// Quyết định: DECISIONS.md — "Import ZIP: trùng tên thì tạo bản sao" (2026-10-24)
// Bug B-16: tên mục trong zip kiểu `../x.md` từng ghi được ra ngoài workspace.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/features/settings/data/export_import_service.dart';

void main() {
  late Directory tempDir;
  late Directory workspace;
  late ExportImportService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devnotes_import_');
    workspace = Directory(p.join(tempDir.path, 'workspace'))..createSync();
    service = ExportImportService(workspacePath: workspace.path);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// Tạo file zip chứa các mục [entries] (tên mục → nội dung).
  String makeZip(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
    });
    final zipPath = p.join(tempDir.path, 'import.zip');
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));
    return zipPath;
  }

  void writeNote(String relative, String content) {
    final file = File(p.join(workspace.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String readNote(String relative) =>
      File(p.join(workspace.path, relative)).readAsStringSync();

  bool noteExists(String relative) =>
      File(p.join(workspace.path, relative)).existsSync();

  test('note mới được ghi vào workspace và đếm là đã thêm', () async {
    final report = await service.importFromZip(
        makeZip({'a.md': '# A', 'b.md': '# B'}));

    expect(readNote('a.md'), '# A');
    expect(readNote('b.md'), '# B');
    expect(report.added, ['a.md', 'b.md']);
    expect(report.copied, isEmpty);
    expect(report.skippedIdentical, isEmpty);
    expect(report.rejected, isEmpty);
  });

  test('trùng tên và giống hệt nội dung thì bỏ qua, không đẻ bản sao',
      () async {
    writeNote('a.md', '# A');

    final report = await service.importFromZip(makeZip({'a.md': '# A'}));

    expect(report.skippedIdentical, ['a.md']);
    expect(report.added, isEmpty);
    expect(noteExists('a-1.md'), isFalse);
  });

  test('trùng tên nhưng khác nội dung thì giữ note cũ, ghi bản sao -1',
      () async {
    writeNote('a.md', '# A cũ');

    final report = await service.importFromZip(makeZip({'a.md': '# A mới'}));

    expect(readNote('a.md'), '# A cũ');
    expect(readNote('a-1.md'), '# A mới');
    expect(report.copied, {'a.md': 'a-1.md'});
  });

  test('bản sao -1 đã có thì dùng -2', () async {
    writeNote('a.md', '# A cũ');
    writeNote('a-1.md', '# A bản sao trước');

    final report = await service.importFromZip(makeZip({'a.md': '# A mới'}));

    expect(readNote('a-1.md'), '# A bản sao trước');
    expect(readNote('a-2.md'), '# A mới');
    expect(report.copied, {'a.md': 'a-2.md'});
  });

  test('nhập lại cùng một zip lần hai không sinh thêm file nào', () async {
    writeNote('a.md', '# A cũ');
    final zip = makeZip({'a.md': '# A mới', 'b.md': '# B'});

    await service.importFromZip(zip);
    final second = await service.importFromZip(zip);

    expect(second.added, isEmpty);
    expect(second.copied, isEmpty);
    // a.md trong zip giờ đã giống hệt bản sao a-1.md, b.md giống b.md.
    expect(second.skippedIdentical, unorderedEquals(['a.md', 'b.md']));
    expect(noteExists('a-2.md'), isFalse);
  });

  test('giữ cấu trúc thư mục con', () async {
    final report =
        await service.importFromZip(makeZip({'work/meeting.md': '# M'}));

    expect(readNote(p.join('work', 'meeting.md')), '# M');
    expect(report.added, ['work/meeting.md']);
  });

  test('mục thoát ra ngoài workspace bằng ../ bị từ chối, mục hợp lệ vẫn nhập',
      () async {
    final report = await service.importFromZip(makeZip({
      '../evil.md': 'pwned',
      'work/../../evil2.md': 'pwned',
      'ok.md': '# OK',
    }));

    expect(File(p.join(tempDir.path, 'evil.md')).existsSync(), isFalse);
    expect(File(p.join(tempDir.path, 'evil2.md')).existsSync(), isFalse);
    expect(readNote('ok.md'), '# OK');
    expect(report.rejected,
        unorderedEquals(['../evil.md', 'work/../../evil2.md']));
  });

  test('đường dẫn tuyệt đối trong zip bị từ chối', () async {
    final report = await service.importFromZip(
        makeZip({'/etc/evil.md': 'pwned', 'C:/evil.md': 'pwned'}));

    expect(report.rejected, unorderedEquals(['/etc/evil.md', 'C:/evil.md']));
    expect(report.added, isEmpty);
  });

  test('file không phải .md bị bỏ qua', () async {
    final report = await service
        .importFromZip(makeZip({'img.png': 'xx', '.git/config': 'x'}));

    expect(noteExists('img.png'), isFalse);
    expect(report.added, isEmpty);
  });

  test('file zip hỏng thì báo lỗi và không ghi file nào', () async {
    final zipPath = p.join(tempDir.path, 'broken.zip');
    File(zipPath).writeAsStringSync('đây không phải zip');

    await expectLater(
        service.importFromZip(zipPath), throwsA(isA<ImportException>()));
    expect(workspace.listSync(), isEmpty);
  });
}
