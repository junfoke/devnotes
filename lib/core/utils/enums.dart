/// Sync status indicating the current state of a git synchronization operation.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  /// File has local changes not yet pushed to remote.
  pending,
  /// File is in sync with remote.
  synced,
  /// File has a merge conflict requiring resolution.
  conflict,
}

/// Action taken during a sync log entry.
enum SyncAction {
  push,
  pull,
  commit,
  fetch,
}

/// How frequently automatic syncing should occur.
enum SyncFrequency {
  /// Chỉ sync khi user bấm nút Sync.
  manual,

  /// Tự sync khi mở app và khi quay lại app (cách nhau ≥ 5 phút).
  onOpen,

  /// Như [onOpen], cộng thêm sync định kỳ trong lúc app đang mở.
  periodic,
}

/// User's preferred app theme.
enum ThemePreference {
  system,
  light,
  dark,
}
