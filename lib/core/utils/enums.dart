/// Sync status indicating the current state of a git synchronization operation.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
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
