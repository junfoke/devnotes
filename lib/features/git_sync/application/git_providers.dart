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
  /// Starts at [SyncStatus.idle], not `synced`: nothing has been synced yet in
  /// this session, and claiming otherwise shows a green "all good" dot to a
  /// user whose repo may be hours out of date or failing to authenticate.
  SyncStateNotifier()
      : super(const SyncState(
          branchName: 'main',
          status: SyncStatus.idle,
        ));

  void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
  void setSynced() => state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );
  void setError() => state = state.copyWith(status: SyncStatus.error);
  void setConflict() => state = state.copyWith(status: SyncStatus.conflict);
  void setStatus(SyncStatus status) => state = state.copyWith(status: status);
  void setBranch(String branch) => state = state.copyWith(branchName: branch);
}

/// Sync history, read from SQLite so it survives an app restart.
///
/// `SyncService` has always written these entries; the sheet used to read an
/// in-memory list that nothing ever appended to, so it was permanently empty.
final syncHistoryProvider = FutureProvider<List<SyncLogEntry>>((ref) async {
  final db = await ref.watch(metadataDatabaseProvider.future);
  return db.getSyncLog(limit: 20);
});

/// When the last *successful* sync happened, or null if there never was one.
/// Entries come back newest-first, so the first success is the most recent.
final lastSuccessfulSyncProvider = FutureProvider<DateTime?>((ref) async {
  final entries = await ref.watch(syncHistoryProvider.future);
  for (final entry in entries) {
    if (entry.success) return entry.timestamp;
  }
  return null;
});

/// Branch actually checked out in the workspace repo.
///
/// Falls back to the configured branch when the repo does not exist yet or has
/// no commits (unborn HEAD), where `Repository.open`/`head` throws.
final currentBranchProvider = FutureProvider<String>((ref) async {
  final config = await ref.watch(gitConfigProvider.future);
  final fallback = config?.branch ?? 'main';
  try {
    final client = await ref.watch(gitClientProvider.future);
    return await client.currentBranch();
  } catch (_) {
    return fallback;
  }
});

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
