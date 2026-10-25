import 'package:devnotes/features/git_sync/application/sync_service.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

enum SyncSkipReason {
  /// Một lần sync khác đang chạy.
  alreadyRunning,

  /// Chưa cấu hình git.
  notConfigured,

  /// Sync tự động không chạy khi repo còn conflict chưa giải quyết.
  unresolvedConflicts,
}

/// Repo đang bận với một thao tác git khác (sync, chuyển branch…).
class GitBusyException implements Exception {
  const GitBusyException();

  @override
  String toString() => 'Đang đồng bộ, thử lại sau khi xong.';
}

/// Kết quả một lần gọi [SyncRunner.run]: đúng một trong ba trường khác null.
class SyncOutcome {
  const SyncOutcome.skipped(SyncSkipReason this.skipped)
      : result = null,
        error = null;
  const SyncOutcome.done(SyncResult this.result)
      : skipped = null,
        error = null;
  const SyncOutcome.failed(Object this.error)
      : skipped = null,
        result = null;

  final SyncSkipReason? skipped;
  final SyncResult? result;
  final Object? error;
}

/// Điểm vào duy nhất để chạy sync — dùng chung cho nút Sync và sync tự động,
/// để không bao giờ có hai lần sync chạy chồng lên nhau trên cùng một repo.
class SyncRunner {
  SyncRunner({
    required this.loadConfig,
    required this.hasUnresolvedConflicts,
    required this.prepareRepo,
    required this.doSync,
  });

  final Future<GitConfig?> Function() loadConfig;
  final Future<bool> Function() hasUnresolvedConflicts;

  /// Khởi tạo repo nếu chưa có (`Git2dartClient.initializeRepo`).
  final Future<void> Function(GitConfig config) prepareRepo;
  final Future<SyncResult> Function(GitConfig config) doSync;

  bool _running = false;
  bool get isRunning => _running;

  /// Chạy một thao tác git khác sync (chuyển branch, đánh dấu đã giải quyết
  /// conflict) dưới cùng khóa với sync. Đang có thao tác khác thì ném
  /// [GitBusyException] thay vì chạy chồng lên repo.
  Future<T> exclusive<T>(Future<T> Function() op) async {
    if (_running) throw const GitBusyException();
    _running = true;
    try {
      return await op();
    } finally {
      _running = false;
    }
  }

  /// [auto]: lần sync do hệ thống kích hoạt, không phải user bấm. Sync tự
  /// động bỏ qua khi repo còn conflict — để user tự quyết, không bị app chen
  /// ngang lúc đang giải quyết.
  Future<SyncOutcome> run({bool auto = false}) async {
    if (_running) return const SyncOutcome.skipped(SyncSkipReason.alreadyRunning);
    _running = true;
    try {
      final config = await loadConfig();
      if (config == null) {
        return const SyncOutcome.skipped(SyncSkipReason.notConfigured);
      }
      if (auto && await hasUnresolvedConflicts()) {
        return const SyncOutcome.skipped(SyncSkipReason.unresolvedConflicts);
      }
      await prepareRepo(config);
      return SyncOutcome.done(await doSync(config));
    } catch (e) {
      return SyncOutcome.failed(e);
    } finally {
      _running = false;
    }
  }
}
