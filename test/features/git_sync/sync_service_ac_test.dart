// Luồng sync: pull → (có thay đổi thì) commit → push.
//
// Quyết định: DECISIONS.md — "Sync luôn push sau khi pull thành công"
// (2026-10-24). Trước đây chỉ push khi có thay đổi mới, nên commit của một lần
// push lỗi mạng nằm kẹt trên máy cho tới khi user sửa thêm note khác.
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/features/git_sync/application/sync_service.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class _FakeGitClient implements GitClient {
  _FakeGitClient({
    this.changes = false,
    this.conflicts = const [],
    List<String> unresolved = const [],
  }) : unresolved = [...unresolved];

  final bool changes;
  final List<String> conflicts;

  /// File git còn đánh dấu conflict từ lần trước (index có conflict).
  final List<String> unresolved;
  final calls = <String>[];

  @override
  Future<PullResult> pull({String? username, String? password}) async {
    calls.add('pull');
    return PullResult(
        success: conflicts.isEmpty, filesChanged: 0, conflicts: conflicts);
  }

  @override
  Future<bool> hasChanges() async => changes;

  @override
  Future<void> commitAll(String message) async => calls.add('commit');

  @override
  Future<void> push({String? username, String? password}) async =>
      calls.add('push');

  @override
  Future<void> clone(String url, String localPath,
          {String? username, String? password}) async =>
      throw UnimplementedError();
  @override
  Future<String> currentBranch() async => 'main';
  @override
  Future<List<String>> conflictedFiles() async => [...unresolved];
  @override
  Future<void> markResolved(String filePath) async {
    calls.add('resolve $filePath');
    unresolved.remove(filePath);
  }
}

void main() {
  late MetadataDatabase db;
  const config = GitConfig(
    remoteUrl: 'https://example.com/notes.git',
    username: 'u',
    pat: 'p',
    branch: 'main',
  );

  setUp(() => db = MetadataDatabase(dbPath: ':memory:'));

  test('có thay đổi thì pull → commit → push theo đúng thứ tự', () async {
    final git = _FakeGitClient(changes: true);

    final result =
        await SyncService(gitClient: git, metadataDb: db).sync(config);

    expect(result.success, isTrue);
    expect(git.calls, ['pull', 'commit', 'push']);
  });

  test('không có thay đổi mới vẫn push, để đẩy commit còn kẹt từ lần trước',
      () async {
    final git = _FakeGitClient(changes: false);

    await SyncService(gitClient: git, metadataDb: db).sync(config);

    expect(git.calls, ['pull', 'push']);
  });

  test('pull ra conflict thì dừng, không commit, không push', () async {
    final git = _FakeGitClient(changes: true, conflicts: ['/w/a.md']);

    final result =
        await SyncService(gitClient: git, metadataDb: db).sync(config);

    expect(result.success, isFalse);
    expect(result.conflicts, ['/w/a.md']);
    expect(git.calls, ['pull']);
  });

  group('file còn đánh dấu conflict từ trước', () {
    const markers = '<<<<<<< HEAD\nmine\n=======\ntheirs\n>>>>>>> abc\n';

    test('file còn dấu conflict thì dừng hẳn: không pull, không commit, không push',
        () async {
      final git = _FakeGitClient(changes: true, unresolved: ['/w/a.md']);
      final service = SyncService(
        gitClient: git,
        metadataDb: db,
        readFile: (_) async => markers,
      );

      final result = await service.sync(config);

      expect(result.success, isFalse);
      expect(result.conflicts, ['/w/a.md']);
      expect(git.calls, isEmpty);
    });

    test('file đã hết dấu conflict thì tự đánh dấu đã giải quyết rồi sync tiếp',
        () async {
      final git = _FakeGitClient(changes: true, unresolved: ['/w/a.md']);
      final service = SyncService(
        gitClient: git,
        metadataDb: db,
        readFile: (_) async => '# A đã sửa xong\n',
      );

      final result = await service.sync(config);

      expect(result.success, isTrue);
      expect(git.calls, ['resolve /w/a.md', 'pull', 'commit', 'push']);
    });

    test('nhiều file: chỉ cần một file còn dấu là dừng, file đó được báo lại',
        () async {
      final git =
          _FakeGitClient(changes: true, unresolved: ['/w/a.md', '/w/b.md']);
      final service = SyncService(
        gitClient: git,
        metadataDb: db,
        readFile: (path) async => path == '/w/b.md' ? markers : '# A\n',
      );

      final result = await service.sync(config);

      expect(result.success, isFalse);
      expect(result.conflicts, ['/w/b.md']);
      expect(git.calls, isNot(contains('commit')));
    });
  });
}
