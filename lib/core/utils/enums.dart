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
  manual,
  onSave,
  periodic,
}

/// User's preferred app theme.
enum ThemePreference {
  system,
  light,
  dark,
}
