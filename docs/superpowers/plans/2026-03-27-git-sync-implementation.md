# Git Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the libgit2dart stub with a working git2dart implementation so notes sync to/from GitHub on Android.

**Architecture:** `Git2dartClient` implements the existing `GitClient` interface using `git2dart` FFI bindings. All git operations run inside `Isolate.run()` to avoid blocking the UI. A Smart Init flow handles first-time setup (init local repo or clone remote). `SyncService` orchestrates the pull → commit → push workflow.

**Tech Stack:** git2dart ^0.4.0, Isolate.run, Riverpod providers, existing GitClient/SyncService/MetadataDatabase

**Spec:** `docs/superpowers/specs/2026-03-27-git-sync-implementation-design.md`

---

## Task 1: Swap Dependencies & Android Init

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Update pubspec.yaml**

Replace the commented libgit2dart lines with git2dart:

```yaml
# In pubspec.yaml, replace lines 25-27:
# OLD:
#   # TODO: libgit2dart requires special platform setup (native binaries).
#   # Uncomment when platform configuration is complete.
#   # libgit2dart: ^1.7.2

# NEW:
  git2dart: ^0.4.0
```

- [ ] **Step 2: Run flutter pub get**

```bash
flutter pub get
```
Expected: Dependencies resolved successfully.

- [ ] **Step 3: Add Android initialization to main.dart**

```dart
// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:git2dart/git2dart.dart';

import 'app/app.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await PlatformSpecific.androidInitialize();
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DevNotesApp(),
    ),
  );
}
```

`PlatformSpecific.androidInitialize()` extracts bundled Mozilla CA certificates so HTTPS works on Android. The `Platform.isAndroid` guard allows the app to still run on other platforms without crashing.

- [ ] **Step 4: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore: swap libgit2dart for git2dart, add Android SSL initialization"
```

---

## Task 2: Implement Git2dartClient Core Methods

**Files:**
- Create: `lib/core/git_client/git2dart_client.dart`
- Delete: `lib/core/git_client/libgit2_git_client.dart`

- [ ] **Step 1: Create Git2dartClient with clone, currentBranch, hasChanges**

```dart
// lib/core/git_client/git2dart_client.dart
import 'dart:io';
import 'dart:isolate';
import 'package:git2dart/git2dart.dart';
import 'package:devnotes/core/git_client/git_client.dart';

class Git2dartClient implements GitClient {
  final String repoPath;

  Git2dartClient({required this.repoPath});

  Callbacks _credentials(String? username, String? password) {
    return Callbacks(
      credentials: (username != null && password != null)
          ? UserPass(username: username, password: password)
          : null,
    );
  }

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
}
```

- [ ] **Step 2: Delete the old stub**

Delete `lib/core/git_client/libgit2_git_client.dart`.

- [ ] **Step 3: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found (libgit2_git_client.dart is not imported anywhere else).

- [ ] **Step 4: Commit**

```bash
git add lib/core/git_client/git2dart_client.dart
git rm lib/core/git_client/libgit2_git_client.dart
git commit -m "feat: implement Git2dartClient with full git operations via Isolate"
```

---

## Task 3: Smart Init — First-Time Repo Setup

**Files:**
- Modify: `lib/core/git_client/git2dart_client.dart`

- [ ] **Step 1: Add initializeRepo method**

Add this method to `Git2dartClient` class (not part of `GitClient` interface):

```dart
  /// Initializes the workspace as a git repo.
  /// If remote has data → clone into workspace.
  /// If remote is empty → init local repo, add remote, commit, push.
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
        final repo = Repository.init(path);
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
```

- [ ] **Step 2: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/git_client/git2dart_client.dart
git commit -m "feat: add Smart Init for first-time repo setup (clone or init+push)"
```

---

## Task 4: Bug Fixes — SyncStateNotifier & SyncService

**Files:**
- Modify: `lib/features/git_sync/application/git_providers.dart`
- Modify: `lib/features/git_sync/application/sync_service.dart`

- [ ] **Step 1: Fix SyncStateNotifier wrong enum values**

In `lib/features/git_sync/application/git_providers.dart`, the notifier uses wrong SyncStatus values:

```dart
// BEFORE (wrong):
void setSyncing() => state = state.copyWith(status: SyncStatus.pending);
void setError() => state = state.copyWith(status: SyncStatus.conflict);

// AFTER (correct):
void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
void setError() => state = state.copyWith(status: SyncStatus.error);
```

Also add a method to record sync history:

```dart
void addHistory(SyncLogEntry entry) {
  state = state.copyWith(history: [...state.history, entry]);
}
```

Full updated class:

```dart
class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier()
      : super(const SyncState(
          branchName: 'main',
          status: SyncStatus.synced,
        ));

  void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
  void setSynced() => state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );
  void setError() => state = state.copyWith(status: SyncStatus.error);
  void setBranch(String branch) => state = state.copyWith(branchName: branch);
  void addHistory(SyncLogEntry entry) {
    state = state.copyWith(history: [...state.history, entry]);
  }
}
```

Add import at top of file:

```dart
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
```

(This import already exists — verify it's there.)

- [ ] **Step 2: Remove redundant rebuildIndex from SyncService**

In `lib/features/git_sync/application/sync_service.dart`, remove the search engine rebuild block (lines 80-87) since `searchIndexInitProvider` already watches `noteListProvider` and rebuilds automatically.

Also remove the unused `searchEngine` and `noteRepo` fields since they are no longer needed by SyncService.

Updated SyncService:

```dart
// lib/features/git_sync/application/sync_service.dart
import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class SyncResult {
  final bool success;
  final int filesChanged;
  final List<String> conflicts;
  final String? error;

  const SyncResult({
    required this.success,
    this.filesChanged = 0,
    this.conflicts = const [],
    this.error,
  });
}

class SyncService {
  final GitClient gitClient;
  final MetadataDatabase metadataDb;

  SyncService({
    required this.gitClient,
    required this.metadataDb,
  });

  Future<SyncResult> sync(GitConfig config) async {
    try {
      // 1. Pull
      final pullResult = await gitClient.pull(
        username: config.username,
        password: config.pat,
      );

      if (pullResult.hasConflicts) {
        for (final file in pullResult.conflicts) {
          metadataDb.upsertSyncStatus(file, SyncStatus.conflict);
        }
        metadataDb.addSyncLogEntry(
          action: SyncAction.pull,
          filesChanged: pullResult.filesChanged,
          success: false,
          errorMessage: '${pullResult.conflicts.length} conflicts',
        );
        return SyncResult(
          success: false,
          filesChanged: pullResult.filesChanged,
          conflicts: pullResult.conflicts,
        );
      }

      // 2. Check for local changes
      final hasChanges = await gitClient.hasChanges();
      if (hasChanges) {
        final timestamp = DateTime.now().toUtc().toIso8601String();
        await gitClient.commitAll('DevNotes sync $timestamp');
        await gitClient.push(
          username: config.username,
          password: config.pat,
        );
      }

      // 3. Update metadata
      final totalChanged = pullResult.filesChanged + (hasChanges ? 1 : 0);
      metadataDb.addSyncLogEntry(
        action: hasChanges ? SyncAction.push : SyncAction.pull,
        filesChanged: totalChanged,
        success: true,
      );

      return SyncResult(success: true, filesChanged: totalChanged);
    } catch (e) {
      metadataDb.addSyncLogEntry(
        action: SyncAction.push,
        filesChanged: 0,
        success: false,
        errorMessage: e.toString(),
      );
      return SyncResult(success: false, error: e.toString());
    }
  }
}
```

- [ ] **Step 3: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 4: Run tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/git_sync/application/git_providers.dart lib/features/git_sync/application/sync_service.dart
git commit -m "fix: correct SyncStateNotifier enum values, remove redundant search rebuild from SyncService"
```

---

## Task 5: Provider Wiring — GitClient, MetadataDb, SyncService

**Files:**
- Modify: `lib/features/git_sync/application/git_providers.dart`
- Create: `lib/features/git_sync/application/metadata_database_provider.dart`

- [ ] **Step 1: Create MetadataDatabase provider**

```dart
// lib/features/git_sync/application/metadata_database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/core/file_system/metadata_database.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:path/path.dart' as p;

final metadataDatabaseProvider = FutureProvider<MetadataDatabase>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  final dbPath = p.join(p.dirname(path), 'metadata.db');
  final db = MetadataDatabase(dbPath: dbPath);
  ref.onDispose(db.close);
  return db;
});
```

- [ ] **Step 2: Add gitClientProvider and syncServiceProvider to git_providers.dart**

Add these providers at the bottom of `lib/features/git_sync/application/git_providers.dart`:

```dart
import 'package:devnotes/core/git_client/git2dart_client.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:devnotes/features/git_sync/application/metadata_database_provider.dart';
import 'package:devnotes/features/git_sync/application/sync_service.dart';

final gitClientProvider = FutureProvider<Git2dartClient>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return Git2dartClient(repoPath: path);
});

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final gitClient = await ref.watch(gitClientProvider.future);
  final metadataDb = await ref.watch(metadataDatabaseProvider.future);
  return SyncService(
    gitClient: gitClient,
    metadataDb: metadataDb,
  );
});
```

Full updated `git_providers.dart`:

```dart
// lib/features/git_sync/application/git_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/git_sync/data/git_config_repository.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/core/git_client/git2dart_client.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:devnotes/features/git_sync/application/metadata_database_provider.dart';
import 'package:devnotes/features/git_sync/application/sync_service.dart';

final gitConfigRepoProvider = Provider<GitConfigRepository>(
  (ref) => GitConfigRepository(),
);

final gitConfigProvider = FutureProvider<GitConfig?>((ref) async {
  final repo = ref.watch(gitConfigRepoProvider);
  return repo.loadConfig();
});

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>(
  (ref) => SyncStateNotifier(),
);

class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier()
      : super(const SyncState(
          branchName: 'main',
          status: SyncStatus.synced,
        ));

  void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
  void setSynced() => state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );
  void setError() => state = state.copyWith(status: SyncStatus.error);
  void setBranch(String branch) => state = state.copyWith(branchName: branch);
  void addHistory(SyncLogEntry entry) {
    state = state.copyWith(history: [...state.history, entry]);
  }
}

final gitClientProvider = FutureProvider<Git2dartClient>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return Git2dartClient(repoPath: path);
});

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final gitClient = await ref.watch(gitClientProvider.future);
  final metadataDb = await ref.watch(metadataDatabaseProvider.future);
  return SyncService(
    gitClient: gitClient,
    metadataDb: metadataDb,
  );
});
```

- [ ] **Step 3: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/git_sync/application/metadata_database_provider.dart lib/features/git_sync/application/git_providers.dart
git commit -m "feat: add providers for GitClient, MetadataDatabase, and SyncService"
```

---

## Task 6: Wire Sync into Workspace Screen

**Files:**
- Modify: `lib/features/workspace/presentation/workspace_screen.dart`
- Modify: `lib/features/workspace/presentation/widgets/workspace_app_bar.dart`

- [ ] **Step 1: Update WorkspaceAppBar to support syncing state**

In `lib/features/workspace/presentation/widgets/workspace_app_bar.dart`, add a `isSyncing` parameter:

```dart
import 'package:flutter/material.dart';
import 'package:devnotes/core/theme/app_theme.dart';

class WorkspaceAppBar extends StatelessWidget {
  final VoidCallback onSyncTap;
  final VoidCallback onGitStatusTap;
  final VoidCallback onSettingsTap;
  final Color gitStatusColor;
  final bool isSyncing;

  const WorkspaceAppBar({
    super.key,
    required this.onSyncTap,
    required this.onGitStatusTap,
    required this.onSettingsTap,
    required this.gitStatusColor,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DevNotes',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onGitStatusTap,
                  child: Row(
                    children: [
                      Icon(Icons.commit, size: 20, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gitStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: isSyncing ? null : onSyncTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSyncing ? colors.bgSurface : colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSyncing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accent,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(Icons.sync, size: 16, color: colors.textOnAccent),
                              const SizedBox(width: 6),
                              Text(
                                'Sync Now',
                                style: TextStyle(
                                  color: colors.textOnAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.settings, color: colors.textSecondary),
                  onPressed: onSettingsTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire real sync flow in workspace_screen.dart**

In `lib/features/workspace/presentation/workspace_screen.dart`, update the `WorkspaceAppBar` section in the `build` method.

Add import at top:

```dart
import 'package:devnotes/features/git_sync/application/sync_service.dart';
```

Replace the WorkspaceAppBar widget:

```dart
            WorkspaceAppBar(
              key: _syncKey,
              isSyncing: ref.watch(syncStateProvider).status == SyncStatus.syncing,
              onSyncTap: () async {
                final config = await ref.read(gitConfigProvider.future);
                if (!context.mounted) return;
                if (config == null) {
                  context.push('/settings/git');
                  return;
                }

                // Start sync
                ref.read(syncStateProvider.notifier).setSyncing();

                try {
                  // Smart init (no-op if already a repo)
                  final gitClient = await ref.read(gitClientProvider.future);
                  await gitClient.initializeRepo(
                    remoteUrl: config.remoteUrl,
                    username: config.username,
                    password: config.pat,
                  );

                  // Sync
                  final syncService = await ref.read(syncServiceProvider.future);
                  final result = await syncService.sync(config);

                  if (!context.mounted) return;

                  if (result.conflicts.isNotEmpty) {
                    ref.read(syncStateProvider.notifier).setError();
                    context.push('/conflict/${Uri.encodeComponent(result.conflicts.first)}');
                  } else if (result.success) {
                    ref.read(syncStateProvider.notifier).setSynced();
                    ref.invalidate(noteListProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Synced — ${result.filesChanged} file(s) changed'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ref.read(syncStateProvider.notifier).setError();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sync failed: ${result.error ?? "Unknown error"}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ref.read(syncStateProvider.notifier).setError();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sync error: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onGitStatusTap: () {
                final syncState = ref.read(syncStateProvider);
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SyncHistorySheet(
                    branchName: syncState.branchName,
                    lastSyncAt: syncState.lastSyncAt,
                    entries: syncState.history,
                  ),
                );
              },
              onSettingsTap: () => context.push('/settings'),
              gitStatusColor: () {
                final syncStatus = ref.watch(syncStateProvider).status;
                final hasConfig = ref.watch(gitConfigProvider).valueOrNull != null;
                if (!hasConfig) return colors.textMuted;
                switch (syncStatus) {
                  case SyncStatus.synced:
                  case SyncStatus.success:
                    return colors.success;
                  case SyncStatus.syncing:
                  case SyncStatus.pending:
                    return colors.warning;
                  case SyncStatus.error:
                  case SyncStatus.conflict:
                    return colors.error;
                  default:
                    return colors.textMuted;
                }
              }(),
            ),
```

- [ ] **Step 3: Verify flutter analyze passes**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/workspace/presentation/widgets/workspace_app_bar.dart lib/features/workspace/presentation/workspace_screen.dart
git commit -m "feat: wire real Git sync into workspace — Smart Init, pull/push, status feedback"
```

---

## Task 7: Update Tests & Final Verification

**Files:**
- Modify: `test/core/git_client/git_client_test.dart`

- [ ] **Step 1: Update git client test**

The existing test uses a `MockGitClient`. Verify it still compiles since the `GitClient` interface is unchanged. No changes should be needed, but confirm:

```bash
flutter test test/core/git_client/git_client_test.dart
```
Expected: PASS.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues found.

- [ ] **Step 4: Build debug APK**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: verify all tests pass and app builds with git2dart integration"
```
