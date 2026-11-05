// Chuyển repo trên máy sang branch đã cấu hình (B-14) mà không làm biến mất
// note nào.
//
// Quyết định: DECISIONS.md — "Branch local lệch branch cấu hình" (2026-10-24)
// Tình huống thật: repo tạo từ trước khi đổi mặc định sang `main` nên nằm ở
// `master`, còn remote có cả `master` lẫn `main`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:git2dart/git2dart.dart';
import 'package:path/path.dart' as p;
import 'package:devnotes/core/git_client/git2dart_client.dart';

void main() {
  late Directory tmp;
  late String remotePath;
  late String localPath;
  late Git2dartClient local;

  /// Tạo repo thường ở [path] với HEAD trỏ vào [branch] và remote `origin`.
  Git2dartClient makeRepo(String path, String branch) {
    final repo = Repository.init(path: path);
    Reference.create(
        repo: repo, name: 'HEAD', target: 'refs/heads/$branch', force: true);
    Remote.create(repo: repo, name: 'origin', url: remotePath);
    repo.free();
    return Git2dartClient(repoPath: path);
  }

  /// Một máy khác đẩy branch `main` có các file [files] lên remote.
  Future<void> otherMachinePushesMain(Map<String, String> files) async {
    final otherPath = p.join(tmp.path, 'other');
    final other = makeRepo(otherPath, 'main');
    files.forEach((name, content) =>
        File(p.join(otherPath, name)).writeAsStringSync(content));
    await other.commitAll('notes from other machine');
    await other.push();
  }

  List<String> branchFiles(String repoPath, String refName) {
    final repo = Repository.open(repoPath);
    try {
      final oid = Reference.lookup(repo: repo, name: refName).target;
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

  /// Đọc file, bỏ `\r` — libgit2 trên Windows áp `core.autocrlf` của máy khi
  /// checkout, còn trên Android thì không. Test chỉ quan tâm nội dung.
  String readText(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  bool refExists(String repoPath, String refName) {
    final repo = Repository.open(repoPath);
    try {
      Reference.lookup(repo: repo, name: refName);
      return true;
    } catch (_) {
      return false;
    } finally {
      repo.free();
    }
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('devnotes_switch_');
    remotePath = p.join(tmp.path, 'remote.git');
    Repository.init(path: remotePath, bare: true).free();

    localPath = p.join(tmp.path, 'local');
    local = makeRepo(localPath, 'master');
    File(p.join(localPath, 'a.md')).writeAsStringSync('# A\n');
    await local.commitAll('note on master');
    await local.push();
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('chuyển sang main: note của master được merge vào, note của main vẫn còn',
      () async {
    await otherMachinePushesMain({'c.md': '# C\n'});

    final result = await local.switchBranch('main');

    expect(result.conflicts, isEmpty);
    expect(await local.currentBranch(), 'main');
    expect(File(p.join(localPath, 'a.md')).existsSync(), isTrue);
    expect(File(p.join(localPath, 'c.md')).existsSync(), isTrue);
    expect(branchFiles(localPath, 'refs/heads/main'), ['a.md', 'c.md']);
  });

  test('sau khi chuyển, main trên remote đã có note của master', () async {
    await otherMachinePushesMain({'c.md': '# C\n'});

    await local.switchBranch('main');

    expect(branchFiles(remotePath, 'refs/heads/main'), ['a.md', 'c.md']);
  });

  test('nhánh master cũ được giữ nguyên làm dự phòng, không bị xóa', () async {
    await otherMachinePushesMain({'c.md': '# C\n'});

    await local.switchBranch('main');

    expect(branchFiles(localPath, 'refs/heads/master'), ['a.md']);
    expect(branchFiles(remotePath, 'refs/heads/master'), ['a.md']);
  });

  test('thay đổi chưa commit trên master được giữ lại sau khi chuyển',
      () async {
    await otherMachinePushesMain({'c.md': '# C\n'});
    File(p.join(localPath, 'b.md')).writeAsStringSync('# B chưa commit\n');

    await local.switchBranch('main');

    expect(readText(p.join(localPath, 'b.md')), '# B chưa commit\n');
    expect(branchFiles(localPath, 'refs/heads/main'), ['a.md', 'b.md', 'c.md']);
  });

  test('remote chưa có main thì tạo main từ master và đẩy lên', () async {
    final result = await local.switchBranch('main');

    expect(result.conflicts, isEmpty);
    expect(await local.currentBranch(), 'main');
    expect(branchFiles(localPath, 'refs/heads/main'), ['a.md']);
    expect(refExists(remotePath, 'refs/heads/main'), isTrue);
  });

  test('cùng file khác nội dung thì dừng ở conflict, giữ cả hai phiên bản',
      () async {
    await otherMachinePushesMain({'a.md': '# A từ máy khác\n'});

    final result = await local.switchBranch('main');

    expect(await local.currentBranch(), 'main');
    expect(result.conflicts, ['$localPath/a.md']);
    final content = readText(p.join(localPath, 'a.md'));
    expect(content, contains('# A\n'));
    expect(content, contains('# A từ máy khác'));
  });

  test('đã ở đúng branch thì không làm gì', () async {
    await local.switchBranch('master');

    expect(await local.currentBranch(), 'master');
    expect(refExists(localPath, 'refs/heads/main'), isFalse);
  });
}
