class PullResult {
  final bool success;
  final int filesChanged;
  final List<String> conflicts;
  final String? errorMessage;

  const PullResult({
    required this.success,
    required this.filesChanged,
    required this.conflicts,
    this.errorMessage,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

class SwitchBranchResult {
  /// File (đường dẫn tuyệt đối) bị conflict khi merge branch cũ vào branch
  /// mới. Rỗng nghĩa là đã chuyển xong và đã push.
  final List<String> conflicts;

  /// Đã chuyển branch trên máy nhưng đẩy lên remote lỗi — lần Sync sau đẩy.
  final String? pushError;

  const SwitchBranchResult({required this.conflicts, this.pushError});

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Repo còn file conflict chưa giải quyết nên không làm được thao tác vừa
/// gọi (vd chuyển branch). Câu báo cho user do tầng UI dịch.
class UnresolvedConflictsException implements Exception {
  const UnresolvedConflictsException();

  @override
  String toString() =>
      'UnresolvedConflictsException: resolve the remaining conflicts first';
}

abstract class GitClient {
  Future<void> clone(String url, String localPath,
      {String? username, String? password});
  Future<PullResult> pull({String? username, String? password});
  Future<void> commitAll(String message);
  Future<void> push({String? username, String? password});
  Future<String> currentBranch();
  Future<bool> hasChanges();
  Future<List<String>> conflictedFiles();
  Future<void> markResolved(String filePath);
}
