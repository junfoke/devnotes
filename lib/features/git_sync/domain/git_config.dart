/// Configuration for connecting to a remote git repository.
class GitConfig {
  const GitConfig({
    required this.remoteUrl,
    required this.username,
    required this.pat,
  });

  /// HTTPS URL of the remote repository (e.g. "https://github.com/user/repo").
  final String remoteUrl;

  /// Git username used for authentication.
  final String username;

  /// Personal Access Token used for HTTPS authentication.
  final String pat;

  GitConfig copyWith({
    String? remoteUrl,
    String? username,
    String? pat,
  }) {
    return GitConfig(
      remoteUrl: remoteUrl ?? this.remoteUrl,
      username: username ?? this.username,
      pat: pat ?? this.pat,
    );
  }
}
