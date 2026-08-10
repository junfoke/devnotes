// Integration tests for Git2dartClient against real temp repositories.
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#git-sync — staging/commit/push behavior.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git2dart_client.dart';

void main() {
  late Directory tmp;
  late Git2dartClient client;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gitclient_');
    Repository.init(path: tmp.path).free();
    client = Git2dartClient(repoPath: tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Builds a real merge conflict on a.md, leaving the repo mid-merge
  /// (index has conflicts, working file has markers, MERGE_HEAD set).
  Future<void> createConflict() async {
    File('${tmp.path}/a.md').writeAsStringSync('base\n');
    await client.commitAll('base');

    final repo = Repository.open(tmp.path);
    try {
      final c0 = Commit.lookup(repo: repo, oid: repo.head.target);
      final mainRef = repo.head.name; // refs/heads/master or main
      Branch.create(repo: repo, name: 'theirs', target: c0);

      // theirs: base -> "theirs change"
      repo.setHead('refs/heads/theirs');
      Checkout.head(repo: repo, strategy: {GitCheckout.force});
      File('${tmp.path}/a.md').writeAsStringSync('theirs change\n');
      await client.commitAll('theirs');
      final theirHead =
          Reference.lookup(repo: repo, name: 'refs/heads/theirs').target;

      // main: base -> "mine change"
      repo.setHead(mainRef);
      Checkout.head(repo: repo, strategy: {GitCheckout.force});
      File('${tmp.path}/a.md').writeAsStringSync('mine change\n');
      await client.commitAll('mine');

      // merge theirs into main -> conflict
      final annotated = AnnotatedCommit.lookup(repo: repo, oid: theirHead);
      Merge.commit(repo: repo, commit: annotated);
    } finally {
      repo.free();
    }
  }

  List<String> headTreeFileNames() {
    final repo = Repository.open(tmp.path);
    try {
      final commit = Commit.lookup(repo: repo, oid: repo.head.target);
      final names = commit.tree.entries.map((e) => e.name).toList()..sort();
      return names;
    } finally {
      repo.free();
    }
  }

  group('Git2dartClient staging', () {
    test('commitAll syncs deletions: a removed .md is dropped from the tree',
        () async {
      File('${tmp.path}/a.md').writeAsStringSync('# A');
      File('${tmp.path}/b.md').writeAsStringSync('# B');
      await client.commitAll('init');
      expect(headTreeFileNames(), ['a.md', 'b.md']);

      File('${tmp.path}/a.md').deleteSync();
      expect(await client.hasChanges(), isTrue,
          reason: 'deleting a file is a change that must be detected');

      await client.commitAll('delete a');
      expect(headTreeFileNames(), ['b.md'],
          reason: 'deletion must be committed to the tree');
    });
  });

  group('Git2dartClient conflict handling', () {
    test('conflictedFiles returns absolute paths that can be read', () async {
      await createConflict();
      final files = await client.conflictedFiles();
      expect(files, isNotEmpty);
      for (final p in files) {
        expect(p.startsWith(tmp.path), isTrue,
            reason: 'conflict path must be absolute (under repo path), got: $p');
        expect(File(p).existsSync(), isTrue,
            reason: 'conflict path must point to a real file');
      }
    });
  });
}
