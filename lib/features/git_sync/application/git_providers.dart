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
  void addHistory(SyncLogEntry entry) {
    state = state.copyWith(history: [...state.history, entry]);
  }
  void setBranch(String branch) => state = state.copyWith(branchName: branch);
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
