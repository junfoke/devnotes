import 'package:devnotes/core/utils/enums.dart';

/// Thời điểm có thể kích hoạt sync tự động.
enum AutoSyncTrigger {
  /// App vừa khởi động.
  appOpen,

  /// App quay lại foreground sau khi bị ẩn.
  appResume,

  /// Timer định kỳ của chế độ [SyncFrequency.periodic].
  timer,
}

/// Quyết định có tự sync hay không. Xem DECISIONS.md, "Sync tự động".
///
/// Chỉ sync khi app đang mở — không có sync nền: libgit2 chạy qua FFI không
/// sống được trong tiến trình nền của Android, và sync nền tốn pin.
class AutoSyncPolicy {
  /// Khoảng cách tối thiểu giữa hai lần tự sync khi quay lại app — để chuyển
  /// qua lại giữa các app không sinh ra sync liên tục.
  static const resumeGap = Duration(minutes: 5);

  static bool shouldRun({
    required SyncFrequency frequency,
    required AutoSyncTrigger trigger,
    required DateTime? lastAutoSyncAt,
    required DateTime now,
  }) {
    if (frequency == SyncFrequency.manual) return false;
    switch (trigger) {
      case AutoSyncTrigger.appOpen:
        return true;
      case AutoSyncTrigger.appResume:
        return lastAutoSyncAt == null ||
            now.difference(lastAutoSyncAt) >= resumeGap;
      case AutoSyncTrigger.timer:
        return frequency == SyncFrequency.periodic;
    }
  }
}
