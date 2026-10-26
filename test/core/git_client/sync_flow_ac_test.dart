// Luồng sync thật (SyncService + Git2dartClient + remote bare) khi hai máy
// cùng sửa ghi chú. Không bao giờ được mất thay đổi của bên nào.
//
// Quyết định: DECISIONS.md — "Sync theo thứ tự commit → pull → push"
// (2026-10-25). Thứ tự cũ pull → commit từng:
// - lùi toàn bộ thay đổi từ remote khi fast-forward gặp file đang sửa dở;
// - kẹt vĩnh viễn sau khi giải quyết conflict của một lần pull thường.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:git2dart/git2dart.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/git_client/git2dart_client.dart';
import 'package:devnotes/features/git_sync/application/sync_service.dart';
import 'package:devnotes/features/git_sync/domain/conflict_parser.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

void main() {
  late Directory tmp;
  late String remotePath;
  late String phonePath;
  late String laptopPath;
  late SyncService phone;
  late SyncService laptop;
  late Git2dartClient phoneGit;

  const config =
      GitConfig(remoteUrl: 'unused', username: 'u', pat: 'p', branch: 'main');

  Git2dartClient makeRepo(String path) {
    final repo = Repository.init(path: path);
    Reference.create(
        repo: repo, name: 'HEAD', target: 'refs/heads/main', force: true);
    Remote.create(repo: repo, name: 'origin', url: remotePath);
    repo.free();
    return Git2dartClient(repoPath: path);
  }

  SyncService serviceFor(Git2dartClient git) =>
      SyncService(gitClient: git, metadataDb: MetadataDatabase(dbPath: ':memory:'));

  void write(String repo, String name, String content) =>
      File(p.join(repo, name)).writeAsStringSync(content);

  String read(String repo, String name) =>
      File(p.join(repo, name)).readAsStringSync().replaceAll('\r\n', '\n');

  List<String> remoteFiles() {
    final repo = Repository.open(remotePath);
    try {
      final oid = Reference.lookup(repo: repo, name: 'refs/heads/main').target;
      return Commit.lookup(repo: repo, oid: oid)
          .tree
          .entries
          .map((e) => e.name)
          .toList()
        ..sort();
    } finally {
      repo.free();
    }
  }

  String remoteContent(String name) {
    final repo = Repository.open(remotePath);
    try {
      final oid = Reference.lookup(repo: repo, name: 'refs/heads/main').target;
      final entry = Commit.lookup(repo: repo, oid: oid).tree[name];
      return Blob.lookup(repo: repo, oid: entry.oid)
          .content
          .replaceAll('\r\n', '\n');
    } finally {
      repo.free();
    }
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('devnotes_syncflow_');
    remotePath = p.join(tmp.path, 'remote.git');
    Repository.init(path: remotePath, bare: true).free();

    // Laptop tạo ghi chú ban đầu và đẩy lên.
    laptopPath = p.join(tmp.path, 'laptop');
    laptop = serviceFor(makeRepo(laptopPath));
    write(laptopPath, 'a.md', 'A gốc\n');
    write(laptopPath, 'b.md', 'B gốc\n');
    expect((await laptop.sync(config)).success, isTrue);

    // Điện thoại kéo về.
    phonePath = p.join(tmp.path, 'phone');
    phoneGit = makeRepo(phonePath);
    phone = serviceFor(phoneGit);
    expect((await phone.sync(config)).success, isTrue);
    expect(read(phonePath, 'a.md'), 'A gốc\n');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('hai máy sửa hai note khác nhau: sync xong cả hai bản sửa đều còn',
      () async {
    write(laptopPath, 'b.md', 'B sửa trên laptop\n');
    await laptop.sync(config);
    write(phonePath, 'a.md', 'A sửa trên điện thoại\n');

    final result = await phone.sync(config);

    expect(result.success, isTrue);
    expect(read(phonePath, 'a.md'), 'A sửa trên điện thoại\n');
    expect(read(phonePath, 'b.md'), 'B sửa trên laptop\n');
    expect(remoteContent('a.md'), 'A sửa trên điện thoại\n');
    expect(remoteContent('b.md'), 'B sửa trên laptop\n');
  });

  test('cùng sửa một note: báo conflict, không ghi đè im lặng bản nào',
      () async {
    write(laptopPath, 'a.md', 'A sửa trên laptop\n');
    await laptop.sync(config);
    write(phonePath, 'a.md', 'A sửa trên điện thoại\n');

    final result = await phone.sync(config);

    expect(result.success, isFalse);
    expect(result.conflicts, hasLength(1));
    final content = read(phonePath, 'a.md');
    expect(content, contains('A sửa trên laptop'));
    expect(content, contains('A sửa trên điện thoại'));
    // Remote vẫn là bản của laptop — chưa có gì bị đẩy đè lên.
    expect(remoteContent('a.md'), 'A sửa trên laptop\n');
  });

  test('giải quyết conflict xong thì lần sync kế tiếp thành công và đẩy lên',
      () async {
    write(laptopPath, 'a.md', 'A sửa trên laptop\n');
    await laptop.sync(config);
    write(phonePath, 'a.md', 'A sửa trên điện thoại\n');
    final conflicted = (await phone.sync(config)).conflicts.single;

    // User chọn giữ cả hai trên màn conflict.
    final raw = File(conflicted).readAsStringSync();
    File(conflicted)
        .writeAsStringSync(ConflictParser.resolveAll(raw, Resolution.keepBoth));
    await phoneGit.markResolved(conflicted);

    final result = await phone.sync(config);

    expect(result.success, isTrue, reason: result.error);
    expect(remoteContent('a.md'), contains('A sửa trên laptop'));
    expect(remoteContent('a.md'), contains('A sửa trên điện thoại'));
    expect(await phoneGit.conflictedFiles(), isEmpty);

    // Và sync tiếp theo vẫn chạy bình thường, không kẹt.
    expect((await phone.sync(config)).success, isTrue);
  });

  test('conflict mà user xóa luôn file thì vẫn giải quyết được, sync không kẹt',
      () async {
    write(laptopPath, 'a.md', 'A sửa trên laptop\n');
    await laptop.sync(config);
    write(phonePath, 'a.md', 'A sửa trên điện thoại\n');
    final conflicted = (await phone.sync(config)).conflicts.single;

    File(conflicted).deleteSync();
    final result = await phone.sync(config);

    expect(result.success, isTrue, reason: result.error);
    expect(remoteFiles(), ['b.md']);
  });

  test('remote có commit mới, máy này không sửa gì: kéo về đầy đủ', () async {
    write(laptopPath, 'c.md', 'C mới\n');
    await laptop.sync(config);

    final result = await phone.sync(config);

    expect(result.success, isTrue);
    expect(read(phonePath, 'c.md'), 'C mới\n');
  });
}
