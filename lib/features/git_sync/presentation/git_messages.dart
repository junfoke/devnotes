import 'package:devnotes/core/git_client/git_client.dart';
import 'package:devnotes/core/git_client/remote_check.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/features/git_sync/application/sync_runner.dart';

/// Thông báo kết quả kiểm tra kết nối remote, theo ngôn ngữ đang chọn, nói rõ
/// user phải làm gì tiếp. Lỗi không nhận ra thì giữ nguyên thông điệp gốc
/// của libgit2 để còn debug.
String describeRemoteCheck(
  AppLocalizations l,
  RemoteCheckResult result, {
  required String branch,
}) {
  switch (result.status) {
    case RemoteCheckStatus.ok:
      return result.remoteBranches.isEmpty
          ? l.remoteCheckOkEmpty(branch)
          : l.remoteCheckOkFound(branch);
    case RemoteCheckStatus.invalidCredentials:
      return l.remoteCheckInvalidCredentials;
    case RemoteCheckStatus.repoNotFound:
      return l.remoteCheckRepoNotFound;
    case RemoteCheckStatus.networkUnreachable:
      return l.remoteCheckNetworkUnreachable;
    case RemoteCheckStatus.branchNotFound:
      return l.remoteCheckBranchNotFound(
          branch, result.remoteBranches.join(', '));
    case RemoteCheckStatus.unknown:
      return l.remoteCheckUnknown(result.detail ?? l.unknownError);
  }
}

/// Lỗi của chính form cấu hình Git (chưa gọi tới remote), hiện cùng chỗ với
/// kết quả kiểm tra kết nối.
enum GitFormIssue { missingFieldsForCheck, missingFieldsForSave, missingFieldsForConnect }

String describeGitFormIssue(AppLocalizations l, GitFormIssue issue) =>
    switch (issue) {
      GitFormIssue.missingFieldsForCheck => l.gitMissingFieldsCheck,
      GitFormIssue.missingFieldsForSave => l.gitMissingFieldsSave,
      GitFormIssue.missingFieldsForConnect => l.gitMissingFieldsConnect,
    };

/// Chi tiết lỗi để ghép sau câu báo đã dịch. Lỗi do chính app ném ra (repo
/// đang bận, còn conflict) được dịch; lỗi kỹ thuật từ libgit2/IO giữ nguyên.
String describeError(AppLocalizations l, Object error) => switch (error) {
      GitBusyException() => l.gitBusy,
      UnresolvedConflictsException() => l.unresolvedConflictsBeforeSwitch,
      _ => '$error',
    };
