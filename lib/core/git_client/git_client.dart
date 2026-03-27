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
