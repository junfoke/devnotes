import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/application/sync_runner.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';

/// Chạy sync và cập nhật trạng thái chung của app (chấm trạng thái, lịch sử,
/// danh sách note). Phần hiển thị (snackbar, mở màn conflict) do nơi gọi lo.
class SyncController {
  SyncController(this._ref);

  final Ref _ref;

  late final SyncRunner _runner = SyncRunner(
    loadConfig: () => _ref.read(gitConfigProvider.future),
    hasUnresolvedConflicts: () async {
      try {
        final client = await _ref.read(gitClientProvider.future);
        return (await client.conflictedFiles()).isNotEmpty;
      } catch (_) {
        // Repo chưa tồn tại → không thể có conflict.
        return false;
      }
    },
    prepareRepo: (config) async {
      final client = await _ref.read(gitClientProvider.future);
      await client.initializeRepo(
        remoteUrl: config.remoteUrl,
        username: config.username,
        password: config.pat,
        branch: config.branch,
      );
    },
    doSync: (config) async {
      final service = await _ref.read(syncServiceProvider.future);
      return service.sync(config);
    },
  );

  bool get isRunning => _runner.isRunning;

  /// Xem [SyncRunner.exclusive]: chạy thao tác git khác dưới cùng khóa với
  /// sync; đang bận thì ném [GitBusyException].
  Future<T> exclusive<T>(Future<T> Function() op) => _runner.exclusive(op);

  Future<SyncOutcome> sync({bool auto = false}) async {
    final state = _ref.read(syncStateProvider.notifier);
    if (_runner.isRunning) {
      return const SyncOutcome.skipped(SyncSkipReason.alreadyRunning);
    }
    final previous = _ref.read(syncStateProvider).status;
    state.setSyncing();
    final outcome = await _runner.run(auto: auto);

    final result = outcome.result;
    if (outcome.skipped != null) {
      // Không chạy gì cả — trả chấm trạng thái về như trước khi bấm.
      state.setStatus(previous);
      return outcome;
    } else if (result == null) {
      state.setError();
    } else if (result.conflicts.isNotEmpty) {
      state.setConflict();
    } else if (result.success) {
      state.setSynced();
      _ref.invalidate(noteListProvider);
    } else {
      state.setError();
    }
    // SyncService vừa ghi thêm bản ghi vào sync_log.
    _ref.invalidate(syncHistoryProvider);
    _ref.invalidate(currentBranchProvider);
    return outcome;
  }
}

final syncControllerProvider =
    Provider<SyncController>((ref) => SyncController(ref));

/// Thời điểm lần tự sync gần nhất được kích hoạt (trong phiên này).
final lastAutoSyncAtProvider = StateProvider<DateTime?>((ref) => null);
