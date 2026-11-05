import 'package:devnotes/core/utils/enums.dart';

/// A single entry in the sync history log.
class SyncLogEntry {
  const SyncLogEntry({
    required this.timestamp,
    required this.action,
    required this.filesChanged,
    required this.success,
    this.errorMessage,
  });

  /// When this sync operation occurred.
  final DateTime timestamp;

  /// The type of git action that was performed.
  final SyncAction action;

  /// Number of files affected by the operation.
  final int filesChanged;

  /// Whether the operation completed without errors.
  final bool success;

  /// Human-readable error message if [success] is false.
  final String? errorMessage;

  SyncLogEntry copyWith({
    DateTime? timestamp,
    SyncAction? action,
    int? filesChanged,
    bool? success,
    Object? errorMessage = _sentinel,
  }) {
    return SyncLogEntry(
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      filesChanged: filesChanged ?? this.filesChanged,
      success: success ?? this.success,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Represents the current state of the git sync feature.
class SyncState {
  const SyncState({
    required this.branchName,
    required this.status,
    this.lastSyncAt,
  });

  /// The currently checked-out git branch.
  final String branchName;

  /// Current synchronisation status.
  final SyncStatus status;

  /// Timestamp of the most recent successful sync *in this session*.
  ///
  /// History that survives a restart lives in SQLite — see
  /// `syncHistoryProvider` / `lastSuccessfulSyncProvider`. This state
  /// deliberately holds no history list: one source of truth only.
  final DateTime? lastSyncAt;

  SyncState copyWith({
    String? branchName,
    SyncStatus? status,
    Object? lastSyncAt = _sentinel,
  }) {
    return SyncState(
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      lastSyncAt:
          lastSyncAt == _sentinel ? this.lastSyncAt : lastSyncAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
