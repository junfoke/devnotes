# Git Sync Implementation with git2dart

> Design spec for replacing the libgit2dart stub with a working git2dart implementation on Android.

## Scope

Implement real Git sync (clone, pull, commit, push) using the `git2dart` package. Android only — iOS deferred until git2dart adds iOS support. Uses the existing `GitClient` abstract interface.

## Decisions

- **Package**: `git2dart ^0.4.0` (active fork of discontinued libgit2dart)
- **Platform**: Android first (arm64-v8a, x86_64). iOS later.
- **Init strategy**: Smart Init — if remote is empty, init + push local notes. If remote has data, clone and merge.
- **Conflict resolution**: Use existing ConflictScreen (Keep Mine/Theirs/Both)
- **Threading**: All git operations run in `Isolate.run()` to avoid blocking UI

## 1. Dependencies

### pubspec.yaml changes

Remove commented `libgit2dart` line. Add:

```yaml
git2dart: ^0.4.0
```

`git2dart_binaries` is pulled transitively.

### main.dart changes

Add Android-specific initialization before `runApp`:

```dart
import 'package:git2dart/git2dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformSpecific.androidInitialize();
  // ... existing code
}
```

`PlatformSpecific.androidInitialize()` extracts bundled Mozilla CA certificates so HTTPS works on Android.

## 2. Git2dartClient

Replace `lib/core/git_client/libgit2_git_client.dart` with `lib/core/git_client/git2dart_client.dart`.

Implements the existing `GitClient` abstract interface. The workspace directory (`devnotes_workspace/`) is the git repo.

### Method mapping

| GitClient method | git2dart implementation |
|---|---|
| `clone(url, localPath, {username, password})` | `Repository.clone(url: url, localPath: localPath, callbacks: Callbacks(credentials: UserPass(username: username, password: password)))` |
| `pull({username, password})` | Fetch via `Remote.lookup` + `remote.fetch()`. Then `Merge.analysis()` → fast-forward (move ref) or normal merge (`Merge.commit()` + check conflicts + create merge commit + `stateCleanup()`). Return `PullResult` with conflict list. |
| `commitAll(message)` | `repo.index.addAll(repo.status.keys.toList())` → `index.write()` → `index.writeTree()` → `Commit.create()` with HEAD as parent |
| `push({username, password})` | `Remote.lookup(name: 'origin')` → `remote.push(callbacks: ...)` |
| `currentBranch()` | `repo.head.name` → strip `refs/heads/` prefix |
| `hasChanges()` | `repo.status.isNotEmpty` |
| `conflictedFiles()` | `repo.index.conflicts.keys.toList()` |
| `markResolved(filePath)` | `repo.index.add(filePath)` → remove conflict entry → `index.write()` |

### Isolate execution

All methods wrap their git2dart calls inside `Isolate.run()`:

```dart
Future<PullResult> pull({String? username, String? password}) async {
  return Isolate.run(() {
    final repo = Repository.open(repoPath);
    try {
      // ... fetch, merge, etc.
    } finally {
      repo.free();
    }
  });
}
```

`Repository` objects cannot cross isolate boundaries, so each method opens and closes the repo within the isolate.

### Smart Init

New method `initializeRepo()` on Git2dartClient (not part of GitClient interface):

1. Check if `repoPath/.git` exists
2. If NOT a git repo:
   a. Try to clone the remote repo into a temp directory to check if it has commits
   b. If clone succeeds and has files → move cloned `.git` into workspace, checkout (preserving local .md files by backing them up first, then restoring non-conflicting ones after checkout)
   c. If clone fails (empty repo) or repo has no commits → `Repository.init(repoPath)`, `Remote.create(name: 'origin', url: ...)`, commit all existing .md files, push
3. If already a git repo → no-op

## 3. Provider Wiring

### New/updated providers in `git_providers.dart`

```dart
final gitClientProvider = Provider<Git2dartClient>((ref) {
  // Created lazily, workspace path resolved synchronously from cached value
  return Git2dartClient(repoPath: workspacePath);
});
```

This requires knowing the workspace path. Options:
- Make it a `FutureProvider` that awaits `WorkspacePathProvider.getWorkspacePath()`
- Or cache the path at app startup

Recommendation: `FutureProvider` to stay consistent with existing pattern.

```dart
final gitClientProvider = FutureProvider<Git2dartClient>((ref) async {
  final path = await WorkspacePathProvider.getWorkspacePath();
  return Git2dartClient(repoPath: path);
});
```

### SyncService provider

```dart
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final gitClient = await ref.watch(gitClientProvider.future);
  final metadataDb = await ref.watch(metadataDatabaseProvider.future);
  final searchEngine = await ref.watch(searchEngineProvider.future);
  final noteRepo = await ref.watch(noteFileRepositoryProvider.future);
  return SyncService(
    gitClient: gitClient,
    metadataDb: metadataDb,
    searchEngine: searchEngine,
    noteRepo: noteRepo,
  );
});
```

Note: `metadataDatabaseProvider` does not exist yet — needs to be created (currently MetadataDatabase is not exposed via a provider).

## 4. Sync Flow (updated workspace_screen.dart)

When user taps "Sync Now":

```
1. Check gitConfigProvider → if null, navigate to /settings/git
2. Set syncStateProvider → syncing
3. Get Git2dartClient from provider
4. Call git2dartClient.initializeRepo() (no-op if already init)
5. Call syncService.sync(config)
6. If conflicts → navigate to /conflict/:filePath for each conflict
7. Set syncStateProvider → synced (or error)
8. Invalidate noteListProvider to refresh UI
9. Show SnackBar with result
```

### WorkspaceAppBar visual feedback

- Git status dot colors based on `syncStateProvider`:
  - `synced` → green (success)
  - `pending`/syncing → yellow (warning)
  - `conflict`/error → red (error)
  - No config → gray (textMuted)
- While syncing: replace "Sync Now" text with CircularProgressIndicator

## 5. Error Handling

| Error | Handling |
|---|---|
| Network unreachable | Catch in Isolate → SyncResult(error: "No internet connection") → SnackBar |
| Auth failed (401) | git2dart throws on fetch/push → SyncResult(error: "Authentication failed") → SnackBar + suggest Settings |
| Remote repo not found (404) | Catch on clone/fetch → SyncResult(error: "Repository not found") |
| Merge conflicts | PullResult(conflicts: [...]) → navigate to ConflictScreen |
| Isolate crash | try-catch around Isolate.run → SyncResult(error: message) |
| Workspace backup fail | If backup before clone fails → abort, keep local files |

## 6. Files Changed

| Action | File |
|---|---|
| Create | `lib/core/git_client/git2dart_client.dart` |
| Delete | `lib/core/git_client/libgit2_git_client.dart` |
| Modify | `pubspec.yaml` (swap libgit2dart → git2dart) |
| Modify | `lib/main.dart` (add PlatformSpecific.androidInitialize) |
| Modify | `lib/features/git_sync/application/git_providers.dart` (add gitClientProvider, syncServiceProvider) |
| Modify | `lib/features/workspace/presentation/workspace_screen.dart` (wire real sync) |
| Modify | `lib/features/workspace/presentation/widgets/workspace_app_bar.dart` (sync animation) |
| Create | `lib/features/git_sync/application/metadata_database_provider.dart` (expose MetadataDatabase) |
| Modify | `test/core/git_client/git_client_test.dart` (update mock if needed) |

## 7. Bug Fixes (from code review)

Issues found during exploration to fix alongside this work:

1. **SyncService.sync()** calls `searchEngine.rebuildIndex()` after every sync — this is now redundant since `searchIndexInitProvider` watches `noteListProvider`. Remove the rebuildIndex call from SyncService.
2. **SyncStateNotifier** uses wrong SyncStatus values — `setSyncing()` uses `SyncStatus.pending` and `setError()` uses `SyncStatus.conflict`. These should be `SyncStatus.syncing` and `SyncStatus.error`.
3. **editor_screen.dart** `_save()` should trigger `onChanged` callback for search re-index — currently saves to disk but `noteListProvider` is invalidated which handles this.

## 8. Out of Scope

- iOS support (waiting for git2dart)
- SSH key authentication (HTTPS with PAT only)
- Branch switching (main/master only)
- Automatic periodic sync (manual only for now)
- Partial sync / selective file sync
