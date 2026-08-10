/// Configuration for connecting to a remote git repository.
class GitConfig {
  const GitConfig({
    required this.remoteUrl,
    required this.username,
    required this.pat,
    this.branch = 'main',
  });

  /// HTTPS URL of the remote repository (e.g. "https://github.com/user/repo").
  final String remoteUrl;

  /// Git username used for authentication.
  final String username;

  /// Personal Access Token used for HTTPS authentication.
  final String pat;

  /// Target branch name for sync (e.g. "main" or "master").
  final String branch;

  GitConfig copyWith({
    String? remoteUrl,
    String? username,
    String? pat,
    String? branch,
  }) {
    return GitConfig(
      remoteUrl: remoteUrl ?? this.remoteUrl,
      username: username ?? this.username,
      pat: pat ?? this.pat,
      branch: branch ?? this.branch,
    );
  }
}
