import 'dart:io';
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/git_client/remote_check.dart';

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

  /// Stages all workspace .md files using a glob pathspec.
  ///
  /// A glob (not a literal file list) is required so that libgit2's add_all
  /// also records DELETIONS — a file removed from the working directory matches
  /// the pathspec and is dropped from the index. Staging is used instead of
  /// repo.status because status is unreliable for untracked files on Android.
  void _stageAllMarkdown(Repository repo) {
    repo.index.addAll(['*.md']);
    repo.index.write();
  }

  /// Converts a repo-relative path (git's native form) to an absolute
  /// filesystem path the UI can read/write directly.
  String _toAbsolute(String relative) => '$repoPath/$relative';

  /// Converts an absolute filesystem path back to the repo-relative path
  /// used by the git index. Accepts an already-relative path unchanged.
  String _toRelative(String filePath) {
    final prefix = '$repoPath/';
    return filePath.startsWith(prefix)
        ? filePath.substring(prefix.length)
        : filePath;
  }

  @override
  Future<bool> hasChanges() async {
    final repo = Repository.open(repoPath);
    try {
      _stageAllMarkdown(repo);

      // Compare staged tree with HEAD — if different, there are changes
      final newTreeOid = repo.index.writeTree();

      if (repo.isBranchUnborn) {
        // No commits yet — changes exist iff the staged tree is non-empty.
        return Tree.lookup(repo: repo, oid: newTreeOid).length > 0;
      }

      final headCommit = Commit.lookup(repo: repo, oid: repo.head.target);
      return headCommit.tree.oid != newTreeOid;
    } finally {
      repo.free();
    }
  }

  @override
  Future<void> commitAll(String message) async {
    final repo = Repository.open(repoPath);
    try {
      // Stage all workspace .md files (including deletions) before committing.
      _stageAllMarkdown(repo);

      final treeOid = repo.index.writeTree();

      // Skip commit if tree is identical to HEAD (nothing actually changed),
      // or if there is nothing to commit on a fresh repo with no files.
      if (repo.isBranchUnborn) {
        if (Tree.lookup(repo: repo, oid: treeOid).length == 0) return;
      } else {
        final headCommit = Commit.lookup(repo: repo, oid: repo.head.target);
        if (headCommit.tree.oid == treeOid) return;
      }

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
        final conflictPaths =
            repo.index.conflicts.keys.map(_toAbsolute).toList();
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
      return repo.index.conflicts.keys.map(_toAbsolute).toList();
    } finally {
      repo.free();
    }
  }

  @override
  Future<void> markResolved(String filePath) async {
    final repo = Repository.open(repoPath);
    try {
      final relative = _toRelative(filePath);
      repo.index.add(relative);
      repo.index.conflicts[relative]?.remove();
      repo.index.write();
    } finally {
      repo.free();
    }
  }

  /// Checks whether [remoteUrl] is reachable with the given credentials, and
  /// whether it has [branch].
  ///
  /// Runs against a throwaway repo in the system temp directory so it can be
  /// used before anything is saved and never touches the real workspace.
  /// `Remote.ls` only connects and lists refs — it downloads no objects.
  Future<RemoteCheckResult> checkRemote({
    required String remoteUrl,
    required String username,
    required String password,
    required String branch,
  }) async {
    final probeDir =
        Directory.systemTemp.createTempSync('devnotes_remote_probe_');
    try {
      final repo = Repository.init(path: probeDir.path);
      try {
        final remote =
            Remote.create(repo: repo, name: 'origin', url: remoteUrl);
        final refs = remote.ls(
          callbacks: Callbacks(
            credentials: UserPass(username: username, password: password),
          ),
        );
        return evaluateRemoteRefs(
          refNames: refs.map((ref) => ref.name).toList(),
          branch: branch,
        );
      } finally {
        repo.free();
      }
    } catch (e) {
      final message = e.toString();
      return RemoteCheckResult(
        classifyRemoteError(message),
        detail: message,
      );
    } finally {
      if (probeDir.existsSync()) probeDir.deleteSync(recursive: true);
    }
  }

  /// Initializes the workspace as a git repo.
  Future<void> initializeRepo({
    required String remoteUrl,
    String? username,
    String? password,
    String branch = 'main',
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
        checkoutBranch: branch,
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

      // Set HEAD to point to configured branch
      Reference.create(
        repo: repo,
        name: 'HEAD',
        target: 'refs/heads/$branch',
        force: true,
      );

      Remote.create(repo: repo, name: 'origin', url: remoteUrl);
      repo.free();
    }
  }
}
