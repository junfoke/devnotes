import 'dart:io';
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git_client.dart';

class Git2dartClient implements GitClient {
  final String repoPath;

  Git2dartClient({required this.repoPath});

  @override
  Future<void> clone(String url, String localPath,
      {String? username, String? password}) async {
    final repo = Repository.clone(
      url: url,
      localPath: localPath,
      callbacks: Callbacks(
        credentials: (username != null && password != null)
            ? UserPass(username: username, password: password)
            : null,
      ),
    );
    repo.free();
  }

  @override
  Future<String> currentBranch() async {
    final repo = Repository.open(repoPath);
    try {
      final fullName = repo.head.name;
      return fullName.replaceFirst('refs/heads/', '');
    } finally {
      repo.free();
    }
  }

  /// Lists all .md files relative to repoPath for staging.
  List<String> _workspaceFiles() {
    return Directory(repoPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  @override
  Future<bool> hasChanges() async {
    final repo = Repository.open(repoPath);
    try {
      // On unborn branch, any .md file in workspace is a new change
      if (repo.isBranchUnborn) {
        return _workspaceFiles().isNotEmpty;
      }
      return repo.status.isNotEmpty;
    } finally {
      repo.free();
    }
  }

  @override
  Future<void> commitAll(String message) async {
    final repo = Repository.open(repoPath);
    try {
      // On unborn branch, repo.status may not detect untracked files properly.
      // Manually add all .md files from workspace.
      if (repo.isBranchUnborn) {
        final files = _workspaceFiles();
        if (files.isEmpty) return;
        repo.index.addAll(files);
        repo.index.write();
      } else {
        final statusMap = repo.status;
        if (statusMap.isEmpty) return;
        repo.index.addAll(statusMap.keys.toList());
        repo.index.write();
      }

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
  }

  @override
  Future<void> push({String? username, String? password}) async {
    final repo = Repository.open(repoPath);
    try {
      // Ensure push refspec is set for current branch
      String branch;
      try {
        branch = repo.head.name.replaceFirst('refs/heads/', '');
      } catch (_) {
        branch = 'main';
      }

      final remote = Remote.lookup(repo: repo, name: 'origin');
      remote.push(
        refspecs: ['refs/heads/$branch:refs/heads/$branch'],
        callbacks: Callbacks(
          credentials: (username != null && password != null)
              ? UserPass(username: username, password: password)
              : null,
        ),
      );
    } finally {
      repo.free();
    }
  }

  @override
  Future<PullResult> pull({String? username, String? password}) async {
    final repo = Repository.open(repoPath);
    try {
      final creds = Callbacks(
        credentials: (username != null && password != null)
            ? UserPass(username: username, password: password)
            : null,
      );

      // 1. Fetch
      final remote = Remote.lookup(repo: repo, name: 'origin');
      final stats = remote.fetch(callbacks: creds);

      // 2. Handle unborn branch (no commits yet) — nothing to merge
      if (repo.isBranchUnborn) {
        return PullResult(
          success: true,
          filesChanged: stats.receivedObjects,
          conflicts: [],
        );
      }

      // 3. Find local branch
      String branch;
      try {
        branch = repo.head.name.replaceFirst('refs/heads/', '');
      } catch (_) {
        branch = 'main';
      }
      final remoteRefName = 'refs/remotes/origin/$branch';
      final Oid theirHead;
      try {
        theirHead = Reference.lookup(repo: repo, name: remoteRefName).target;
      } catch (_) {
        return PullResult(
          success: true,
          filesChanged: stats.receivedObjects,
          conflicts: [],
        );
      }

      // 3. Analyze merge
      final analysis = Merge.analysis(repo: repo, theirHead: theirHead);

      if (analysis.result.contains(GitMergeAnalysis.upToDate)) {
        return PullResult(success: true, filesChanged: 0, conflicts: []);
      }

      if (analysis.result.contains(GitMergeAnalysis.fastForward)) {
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
  }

  @override
  Future<List<String>> conflictedFiles() async {
    final repo = Repository.open(repoPath);
    try {
      if (!repo.index.hasConflicts) return <String>[];
      return repo.index.conflicts.keys.toList();
    } finally {
      repo.free();
    }
  }

  @override
  Future<void> markResolved(String filePath) async {
    final repo = Repository.open(repoPath);
    try {
      repo.index.add(filePath);
      repo.index.conflicts[filePath]?.remove();
      repo.index.write();
    } finally {
      repo.free();
    }
  }

  /// Initializes the workspace as a git repo.
  Future<void> initializeRepo({
    required String remoteUrl,
    String? username,
    String? password,
  }) async {
    final gitDir = Directory('$repoPath/.git');
    if (gitDir.existsSync()) return;

    // Back up existing local .md files
    final workspace = Directory(repoPath);
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
        localPath: repoPath,
        callbacks: Callbacks(
          credentials: (username != null && password != null)
              ? UserPass(username: username, password: password)
              : null,
        ),
      );
      cloneSucceeded = true;
      repo.free();
    } catch (_) {
      cloneSucceeded = false;
    }

    if (cloneSucceeded) {
      for (final entry in backups.entries) {
        final target = File('$repoPath/${entry.key}');
        if (!target.existsSync()) {
          target.writeAsBytesSync(entry.value);
        }
      }
    } else {
      // Restore backed-up files
      for (final entry in backups.entries) {
        File('$repoPath/${entry.key}').writeAsBytesSync(entry.value);
      }

      // Init fresh repo — only setup, no commit (sync() handles that)
      final repo = Repository.init(path: repoPath);

      // Set HEAD to point to main instead of master (matches GitHub default)
      Reference.create(
        repo: repo,
        name: 'HEAD',
        target: 'refs/heads/main',
        force: true,
      );

      Remote.create(repo: repo, name: 'origin', url: remoteUrl);
      repo.free();
    }
  }
}
