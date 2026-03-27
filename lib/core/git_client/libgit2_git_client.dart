import 'package:devnotes/core/git_client/git_client.dart';

class Libgit2GitClient implements GitClient {
  final String repoPath;

  Libgit2GitClient({required this.repoPath});

  @override
  Future<void> clone(String url, String localPath,
      {String? username, String? password}) async {
    throw UnimplementedError('libgit2dart clone not yet implemented');
  }

  @override
  Future<PullResult> pull({String? username, String? password}) async {
    throw UnimplementedError('libgit2dart pull not yet implemented');
  }

  @override
  Future<void> commitAll(String message) async {
    throw UnimplementedError('libgit2dart commit not yet implemented');
  }

  @override
  Future<void> push({String? username, String? password}) async {
    throw UnimplementedError('libgit2dart push not yet implemented');
  }

  @override
  Future<String> currentBranch() async {
    throw UnimplementedError('libgit2dart currentBranch not yet implemented');
  }

  @override
  Future<bool> hasChanges() async {
    throw UnimplementedError('libgit2dart hasChanges not yet implemented');
  }

  @override
  Future<List<String>> conflictedFiles() async {
    throw UnimplementedError(
        'libgit2dart conflictedFiles not yet implemented');
  }

  @override
  Future<void> markResolved(String filePath) async {
    throw UnimplementedError(
        'libgit2dart markResolved not yet implemented');
  }
}
