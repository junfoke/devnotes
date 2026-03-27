import 'dart:io';
import 'dart:isolate';
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git_client.dart';

class Git2dartClient implements GitClient {
  final String repoPath;

  Git2dartClient({required this.repoPath});

  @override
  Future<void> clone(String url, String localPath,
      {String? username, String? password}) async {
    final u = username;
    final p = password;
    await Isolate.run(() {
      final repo = Repository.clone(
        url: url,
        localPath: localPath,
        callbacks: Callbacks(
          credentials: (u != null && p != null)
              ? UserPass(username: u, password: p)
              : null,
        ),
      );
      repo.free();
    });
  }

  @override
  Future<String> currentBranch() async {
    final path = repoPath;
    return Isolate.run(() {
      final repo = Repository.open(path);
      try {
        final fullName = repo.head.name;
        return fullName.replaceFirst('refs/heads/', '');
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<bool> hasChanges() async {
    final path = repoPath;
    return Isolate.run(() {
      final repo = Repository.open(path);
      try {
        return repo.status.isNotEmpty;
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<void> commitAll(String message) async {
    final path = repoPath;
    await Isolate.run(() {
      final repo = Repository.open(path);
      try {
        final statusMap = repo.status;
        if (statusMap.isEmpty) return;

        repo.index.addAll(statusMap.keys.toList());
        repo.index.write();

        final treeOid = repo.index.writeTree();
        final tree = Tree.lookup(repo: repo, oid: treeOid);

        final signature = Signature.create(
          name: 'DevNotes',
          email: 'devnotes@local',
        );

        final parents = <Commit>[];
        if (!repo.isBranchUnborn) {
          parents.add(Commit.lookup(repo: repo, oid: repo.head.target));
        }

        Commit.create(
          repo: repo,
          updateRef: 'HEAD',
          author: signature,
          committer: signature,
          message: '$message\n',
          tree: tree,
          parents: parents,
        );
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<void> push({String? username, String? password}) async {
    final path = repoPath;
    final u = username;
    final p = password;
    await Isolate.run(() {
      final repo = Repository.open(path);
      try {
        final remote = Remote.lookup(repo: repo, name: 'origin');
        remote.push(
          callbacks: Callbacks(
            credentials: (u != null && p != null)
                ? UserPass(username: u, password: p)
                : null,
          ),
        );
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<PullResult> pull({String? username, String? password}) async {
    final path = repoPath;
    final u = username;
    final p = password;
    return Isolate.run(() {
      final repo = Repository.open(path);
      try {
        final creds = Callbacks(
          credentials: (u != null && p != null)
              ? UserPass(username: u, password: p)
              : null,
        );

        // 1. Fetch
        final remote = Remote.lookup(repo: repo, name: 'origin');
        final stats = remote.fetch(callbacks: creds);

        // 2. Find remote tracking branch
        final branch = repo.head.name.replaceFirst('refs/heads/', '');
        final remoteRefName = 'refs/remotes/origin/$branch';
        final Oid theirHead;
        try {
          theirHead = Reference.lookup(repo: repo, name: remoteRefName).target;
        } catch (_) {
          // No remote tracking ref — nothing to merge
          return PullResult(
            success: true,
            filesChanged: stats.receivedObjects,
            conflicts: [],
          );
        }

        // 3. Analyze merge
        final analysis = Merge.analysis(repo: repo, theirHead: theirHead);

        if (analysis.result.contains(GitMergeAnalysis.upToDate)) {
          return PullResult(
            success: true,
            filesChanged: 0,
            conflicts: [],
          );
        }

        if (analysis.result.contains(GitMergeAnalysis.fastForward)) {
          // Fast-forward
          Reference.create(
            repo: repo,
            name: 'refs/heads/$branch',
            target: theirHead,
            force: true,
          );
          Checkout.head(repo: repo);
          return PullResult(
            success: true,
            filesChanged: stats.receivedObjects,
            conflicts: [],
          );
        }

        // 4. Normal merge
        final annotatedCommit = AnnotatedCommit.lookup(
          repo: repo,
          oid: theirHead,
        );
        Merge.commit(repo: repo, commit: annotatedCommit);

        // 5. Check conflicts
        if (repo.index.hasConflicts) {
          final conflictPaths = repo.index.conflicts.keys.toList();
          return PullResult(
            success: false,
            filesChanged: stats.receivedObjects,
            conflicts: conflictPaths,
          );
        }

        // 6. Create merge commit
        repo.index.write();
        final tree = Tree.lookup(repo: repo, oid: repo.index.writeTree());
        final signature = Signature.create(
          name: 'DevNotes',
          email: 'devnotes@local',
        );
        Commit.create(
          repo: repo,
          updateRef: 'HEAD',
          author: signature,
          committer: signature,
          message: 'Merge remote-tracking branch origin/$branch\n',
          tree: tree,
          parents: [
            Commit.lookup(repo: repo, oid: repo.head.target),
            Commit.lookup(repo: repo, oid: theirHead),
          ],
        );
        repo.stateCleanup();

        return PullResult(
          success: true,
          filesChanged: stats.receivedObjects,
          conflicts: [],
        );
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<List<String>> conflictedFiles() async {
    final path = repoPath;
    return Isolate.run(() {
      final repo = Repository.open(path);
      try {
        if (!repo.index.hasConflicts) return <String>[];
        return repo.index.conflicts.keys.toList();
      } finally {
        repo.free();
      }
    });
  }

  @override
  Future<void> markResolved(String filePath) async {
    final path = repoPath;
    await Isolate.run(() {
      final repo = Repository.open(path);
      try {
        repo.index.add(filePath);
        repo.index.conflicts[filePath]?.remove();
        repo.index.write();
      } finally {
        repo.free();
      }
    });
  }

  /// Initializes the workspace as a git repo.
  /// If remote has data -> clone into workspace.
  /// If remote is empty -> init local repo, add remote, commit, push.
  Future<void> initializeRepo({
    required String remoteUrl,
    String? username,
    String? password,
  }) async {
    final gitDir = Directory('$repoPath/.git');
    if (gitDir.existsSync()) return; // Already a git repo

    final path = repoPath;
    final u = username;
    final p = password;

    await Isolate.run(() {
      // Back up existing local .md files
      final workspace = Directory(path);
      final localFiles = workspace
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      final backups = <String, List<int>>{};
      for (final file in localFiles) {
        final name = file.uri.pathSegments.last;
        backups[name] = file.readAsBytesSync();
      }

      // Try to clone the remote repo
      bool cloneSucceeded = false;
      try {
        final repo = Repository.clone(
          url: remoteUrl,
          localPath: path,
          callbacks: Callbacks(
            credentials: (u != null && p != null)
                ? UserPass(username: u, password: p)
                : null,
          ),
        );
        cloneSucceeded = true;
        repo.free();
      } catch (_) {
        // Clone failed — remote is empty or doesn't exist yet
        cloneSucceeded = false;
      }

      if (cloneSucceeded) {
        // Restore backed-up local files that don't exist in the clone
        for (final entry in backups.entries) {
          final target = File('$path/${entry.key}');
          if (!target.existsSync()) {
            target.writeAsBytesSync(entry.value);
          }
        }
      } else {
        // Restore backed-up files (clone may have cleared workspace)
        for (final entry in backups.entries) {
          File('$path/${entry.key}').writeAsBytesSync(entry.value);
        }

        // Init fresh repo
        final repo = Repository.init(path: path);
        Remote.create(repo: repo, name: 'origin', url: remoteUrl);

        // Stage and commit all .md files
        final statusMap = repo.status;
        if (statusMap.isNotEmpty) {
          repo.index.addAll(statusMap.keys.toList());
          repo.index.write();

          final treeOid = repo.index.writeTree();
          final tree = Tree.lookup(repo: repo, oid: treeOid);
          final signature = Signature.create(
            name: 'DevNotes',
            email: 'devnotes@local',
          );

          Commit.create(
            repo: repo,
            updateRef: 'HEAD',
            author: signature,
            committer: signature,
            message: 'Initial commit from DevNotes\n',
            tree: tree,
            parents: [],
          );

          // Push
          try {
            final remote = Remote.lookup(repo: repo, name: 'origin');
            remote.push(
              callbacks: Callbacks(
                credentials: (u != null && p != null)
                    ? UserPass(username: u, password: p)
                    : null,
              ),
            );
          } catch (_) {
            // Push may fail if remote doesn't accept pushes yet — that's ok
          }
        }

        repo.free();
      }
    });
  }
}
