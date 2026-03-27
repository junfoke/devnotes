import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/git_sync/data/git_config_repository.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';
import 'package:devnotes/features/git_sync/domain/sync_state.dart';
import 'package:devnotes/core/utils/enums.dart';

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
