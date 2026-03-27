import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class GitConfigRepository {
  GitConfigRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _remoteUrlKey = 'git_remote_url';
  static const _usernameKey = 'git_username';
  static const _patKey = 'git_pat';

  Future<GitConfig?> loadConfig() async {
    final url = await _storage.read(key: _remoteUrlKey);
    final username = await _storage.read(key: _usernameKey);
    final pat = await _storage.read(key: _patKey);
    if (url == null || username == null || pat == null) return null;
    return GitConfig(remoteUrl: url, username: username, pat: pat);
  }

  Future<void> saveConfig(GitConfig config) async {
    await _storage.write(key: _remoteUrlKey, value: config.remoteUrl);
    await _storage.write(key: _usernameKey, value: config.username);
    await _storage.write(key: _patKey, value: config.pat);
  }

  Future<void> deleteConfig() async {
    await _storage.delete(key: _remoteUrlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _patKey);
  }

  Future<bool> hasConfig() async {
    final url = await _storage.read(key: _remoteUrlKey);
    return url != null;
  }
}
