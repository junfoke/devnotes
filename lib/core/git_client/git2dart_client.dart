import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/git_client/remote_check.dart';

/// Toàn bộ thao tác git, chạy đồng bộ trên isolate gọi nó.
///
/// Không dùng trực tiếp từ UI — đi qua [Git2dartClient] để được chạy ngoài
/// main isolate (B-11). Mọi trường phải gửi được qua isolate (chỉ chuỗi).
class Git2dartOps {
  final String repoPath;

  Git2dartOps({required this.repoPath});

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

      // Đang dở merge (vừa giải quyết conflict) thì luôn có việc phải commit.
      if (_lookupOid(repo, 'MERGE_HEAD') != null) return true;

      final headCommit = Commit.lookup(repo: repo, oid: repo.head.target);
      return headCommit.tree.oid != newTreeOid;
    } finally {
      repo.free();
    }
  }

  Future<void> commitAll(String message) async {
    final repo = Repository.open(repoPath);
    try {
      // Stage all workspace .md files (including deletions) before committing.
      _stageAllMarkdown(repo);

      final treeOid = repo.index.writeTree();

      final mergeHead = _lookupOid(repo, 'MERGE_HEAD');

      // Skip commit if tree is identical to HEAD (nothing actually changed),
      // or if there is nothing to commit on a fresh repo with no files.
      // Đang dở merge thì không bỏ qua: chọn "Keep Mine" cho cây giống hệt
      // HEAD, nhưng vẫn phải có merge commit để đóng merge lại.
      if (repo.isBranchUnborn) {
        if (Tree.lookup(repo: repo, oid: treeOid).length == 0) return;
      } else if (mergeHead == null) {
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
      // Đang dở một merge (user vừa giải quyết conflict xong): commit này là
      // merge commit — thêm MERGE_HEAD làm cha thứ hai rồi dọn trạng thái
      // merge, nếu không MERGE_HEAD nằm lại làm hỏng những lần pull sau.
      if (mergeHead != null) {
        parents.add(Commit.lookup(repo: repo, oid: mergeHead));
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
      if (mergeHead != null) repo.stateCleanup();
    } finally {
      repo.free();
    }
  }

  Future<void> push({String? username, String? password}) async {
    final repo = Repository.open(repoPath);
    try {
      // Chưa có commit nào (workspace trống, chưa từng sync) — không có gì để
      // đẩy, và push một branch chưa sinh ra sẽ báo lỗi.
      if (repo.isBranchUnborn) return;

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

      final branch = _headBranch(repo);
      final theirHead = _lookupOid(repo, 'refs/remotes/origin/$branch');
      if (theirHead == null) {
        // Remote chưa có branch này — không có gì để kéo.
        return PullResult(
          success: true,
          filesChanged: stats.receivedObjects,
          conflicts: [],
        );
      }

      // 2. Repo chưa có commit nào nhưng remote đã có: lấy nguyên branch từ
      //    remote. Checkout trước, tạo ref sau — checkout lỗi thì repo vẫn y cũ.
      if (repo.isBranchUnborn) {
        Checkout.commit(
          repo: repo,
          commit: Commit.lookup(repo: repo, oid: theirHead),
        );
        Reference.create(
            repo: repo, name: 'refs/heads/$branch', target: theirHead);
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
        // Checkout cây đích TRƯỚC, dời branch SAU. Làm ngược lại thì khi
        // checkout bị chặn (file đang sửa dở), branch đã trỏ tới commit mới
        // trong khi file trên đĩa vẫn cũ — lần commit sau sẽ lùi toàn bộ thay
        // đổi từ remote.
        Checkout.commit(
          repo: repo,
          commit: Commit.lookup(repo: repo, oid: theirHead),
        );
        Reference.create(
          repo: repo,
          name: 'refs/heads/$branch',
          target: theirHead,
          force: true,
        );
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

  Future<List<String>> conflictedFiles() async {
    final repo = Repository.open(repoPath);
    try {
      if (!repo.index.hasConflicts) return <String>[];
      return repo.index.conflicts.keys.map(_toAbsolute).toList();
    } finally {
      repo.free();
    }
  }

  Future<void> markResolved(String filePath) async {
    final repo = Repository.open(repoPath);
    try {
      final relative = _toRelative(filePath);
      if (File('$repoPath/$relative').existsSync()) {
        repo.index.add(relative);
        repo.index.conflicts[relative]?.remove();
      } else {
        // User chọn xóa luôn file đang conflict: `add` sẽ ném lỗi vì file
        // không còn — gỡ các mục conflict và ghi nhận việc xóa.
        repo.index.conflicts[relative]?.remove();
        try {
          repo.index.remove(relative);
        } catch (_) {
          // Không có mục stage 0 nào để gỡ — vậy là đã sạch.
        }
      }
      repo.index.write();
    } finally {
      repo.free();
    }
  }

  /// Chuyển workspace sang branch [target] mà không làm biến mất note nào.
  ///
  /// Xem DECISIONS.md, "Branch local lệch branch cấu hình" (2026-10-24):
  /// 1. Commit mọi thay đổi đang dở trên branch hiện tại.
  /// 2. Fetch; lấy [target] theo thứ tự: branch local sẵn có → `origin/target`
  ///    → tạo mới từ HEAD hiện tại.
  /// 3. Checkout [target] rồi **merge branch cũ vào** để note của nó đi theo.
  ///    Trùng file khác nội dung → dừng ở trạng thái conflict, trả về danh
  ///    sách file để user giải quyết bằng màn hình conflict sẵn có.
  /// 4. Không conflict → push [target]. Branch cũ giữ nguyên, không xóa.
  Future<SwitchBranchResult> switchBranch(String target,
      {String? username, String? password}) async {
    var repo = Repository.open(repoPath);
    try {
      if (!repo.isBranchUnborn &&
          repo.head.name == 'refs/heads/$target') {
        return const SwitchBranchResult(conflicts: []);
      }
      if (repo.index.hasConflicts) {
        throw const UnresolvedConflictsException();
      }
    } finally {
      repo.free();
    }

    await commitAll('DevNotes: lưu thay đổi trước khi chuyển sang $target');

    repo = Repository.open(repoPath);
    try {
      final creds = Callbacks(
        credentials: (username != null && password != null)
            ? UserPass(username: username, password: password)
            : null,
      );
      Remote.lookup(repo: repo, name: 'origin').fetch(callbacks: creds);

      final oldHead = repo.isBranchUnborn ? null : repo.head.target;
      final localRef = 'refs/heads/$target';

      if (_lookupOid(repo, localRef) == null) {
        final base = _lookupOid(repo, 'refs/remotes/origin/$target') ?? oldHead;
        if (base != null) {
          Reference.create(repo: repo, name: localRef, target: base);
        }
      }
      repo.setHead(localRef);
      // An toàn khi force: mọi file .md đã được commit ở bước 1; file không
      // được git theo dõi (collections.json…) không bị đụng tới.
      if (!repo.isBranchUnborn) {
        Checkout.head(repo: repo, strategy: {GitCheckout.force});
      }

      if (oldHead != null && !repo.isBranchUnborn) {
        final analysis = Merge.analysis(repo: repo, theirHead: oldHead);
        if (analysis.result.contains(GitMergeAnalysis.upToDate)) {
          // Branch đích đã chứa toàn bộ branch cũ.
        } else if (analysis.result.contains(GitMergeAnalysis.fastForward)) {
          Reference.create(
              repo: repo, name: localRef, target: oldHead, force: true);
          Checkout.head(repo: repo, strategy: {GitCheckout.force});
        } else {
          Merge.commit(
              repo: repo,
              commit: AnnotatedCommit.lookup(repo: repo, oid: oldHead));
          if (repo.index.hasConflicts) {
            return SwitchBranchResult(
              conflicts: repo.index.conflicts.keys.map(_toAbsolute).toList(),
            );
          }
          repo.index.write();
          final tree = Tree.lookup(repo: repo, oid: repo.index.writeTree());
          final signature =
              Signature.create(name: 'DevNotes', email: 'devnotes@local');
          Commit.create(
            repo: repo,
            updateRef: 'HEAD',
            author: signature,
            committer: signature,
            message: 'Merge previous branch into $target\n',
            tree: tree,
            parents: [
              Commit.lookup(repo: repo, oid: repo.head.target),
              Commit.lookup(repo: repo, oid: oldHead),
            ],
          );
          repo.stateCleanup();
        }
      }
    } finally {
      repo.free();
    }

    // Đã chuyển xong trên máy. Push lỗi (mất mạng, remote đi trước) không
    // làm việc chuyển thất bại — lần Sync sau sẽ đẩy lên.
    try {
      await push(username: username, password: password);
    } catch (e) {
      return SwitchBranchResult(conflicts: const [], pushError: e.toString());
    }
    return const SwitchBranchResult(conflicts: []);
  }

  /// Tên branch HEAD đang trỏ tới, kể cả khi branch chưa có commit nào
  /// (lúc đó `repo.head` ném lỗi, nên đọc thẳng `.git/HEAD`).
  String _headBranch(Repository repo) {
    if (!repo.isBranchUnborn) {
      return repo.head.name.replaceFirst('refs/heads/', '');
    }
    final head = File('$repoPath/.git/HEAD').readAsStringSync().trim();
    const prefix = 'ref: refs/heads/';
    return head.startsWith(prefix) ? head.substring(prefix.length) : 'main';
  }

  static Oid? _lookupOid(Repository repo, String refName) {
    try {
      return Reference.lookup(repo: repo, name: refName).target;
    } catch (_) {
      return null;
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

/// GitClient dùng trong app: chạy mọi thao tác git ngoài main isolate để UI
/// không đơ khi sync (B-11 — log từng báo "Skipped 41 frames").
///
/// Mỗi lần gọi mở repo, làm việc và giải phóng ngay trong isolate tạm, nên
/// không có con trỏ native nào phải đi qua ranh giới isolate. Cấu hình SSL của
/// libgit2 là toàn cục cho cả tiến trình nên đặt một lần ở main là đủ.
///
/// Phòng hờ: lần đầu dùng sẽ thử nạp libgit2 trong một isolate. Nếu không
/// được (từng gặp trên Android ở commit a026ca1) thì chạy thẳng trên main
/// isolate như trước — chậm UI nhưng không hỏng chức năng.
class Git2dartClient implements GitClient {
  Git2dartClient({required this.repoPath});

  final String repoPath;

  static Future<bool>? _isolateUsable;

  /// Đặt `false` để luôn chạy trên isolate gọi (dùng cho test so sánh).
  static bool useIsolates = true;

  /// libgit2 có chạy được trong isolate phụ trên nền tảng này không.
  static Future<bool> get runsInIsolate => _canUseIsolate();

  static Future<bool> _canUseIsolate() {
    return _isolateUsable ??= Isolate.run(() {
      // Chạm vào libgit2 để chắc chắn thư viện native nạp được ở đây.
      Libgit2.version;
      return true;
    }).then((usable) {
      debugPrint('Git2dartClient: git chạy trong isolate phụ');
      return usable;
    }).catchError((Object e) {
      debugPrint('Git2dartClient: không dùng được isolate, chạy trên main: $e');
      return false;
    });
  }

  Future<T> _exec<T>(Future<T> Function(Git2dartOps ops) op) async {
    final ops = Git2dartOps(repoPath: repoPath);
    if (useIsolates && await _canUseIsolate()) {
      return Isolate.run(() => op(ops));
    }
    return op(ops);
  }

  @override
  Future<void> clone(String url, String localPath,
          {String? username, String? password}) =>
      _exec((o) => o.clone(url, localPath,
          username: username, password: password));

  @override
  Future<String> currentBranch() => _exec((o) => o.currentBranch());

  @override
  Future<bool> hasChanges() => _exec((o) => o.hasChanges());

  @override
  Future<void> commitAll(String message) =>
      _exec((o) => o.commitAll(message));

  @override
  Future<void> push({String? username, String? password}) =>
      _exec((o) => o.push(username: username, password: password));

  @override
  Future<PullResult> pull({String? username, String? password}) =>
      _exec((o) => o.pull(username: username, password: password));

  @override
  Future<List<String>> conflictedFiles() => _exec((o) => o.conflictedFiles());

  @override
  Future<void> markResolved(String filePath) =>
      _exec((o) => o.markResolved(filePath));

  /// Xem [Git2dartOps.switchBranch].
  Future<SwitchBranchResult> switchBranch(String target,
          {String? username, String? password}) =>
      _exec((o) =>
          o.switchBranch(target, username: username, password: password));

  /// Xem [Git2dartOps.checkRemote].
  Future<RemoteCheckResult> checkRemote({
    required String remoteUrl,
    required String username,
    required String password,
    required String branch,
  }) =>
      _exec((o) => o.checkRemote(
            remoteUrl: remoteUrl,
            username: username,
            password: password,
            branch: branch,
          ));

  /// Xem [Git2dartOps.initializeRepo].
  Future<void> initializeRepo({
    required String remoteUrl,
    String? username,
    String? password,
    String branch = 'main',
  }) =>
      _exec((o) => o.initializeRepo(
            remoteUrl: remoteUrl,
            username: username,
            password: password,
            branch: branch,
          ));
}
