import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/git_client/git_client.dart';

void main() {
  group('GitClient interface', () {
    test('MockGitClient implements all methods', () {
      final client = MockGitClient();
      expect(client, isA<GitClient>());
    });
  });
}

class MockGitClient implements GitClient {
  @override
  Future<void> clone(String url, String localPath,
      {String? username, String? password}) async {}
  @override
  Future<PullResult> pull({String? username, String? password}) async =>
      PullResult(success: true, filesChanged: 0, conflicts: []);
  @override
  Future<void> commitAll(String message) async {}
  @override
  Future<void> push({String? username, String? password}) async {}
  @override
  Future<String> currentBranch() async => 'main';
  @override
  Future<bool> hasChanges() async => false;
  @override
  Future<List<String>> conflictedFiles() async => [];
  @override
  Future<void> markResolved(String filePath) async {}
}
