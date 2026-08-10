import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/git_client/remote_check.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class OnboardingGitScreen extends ConsumerStatefulWidget {
  const OnboardingGitScreen({super.key});

  @override
  ConsumerState<OnboardingGitScreen> createState() =>
      _OnboardingGitScreenState();
}

class _OnboardingGitScreenState extends ConsumerState<OnboardingGitScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _patController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  bool _loading = false;
  bool _checking = false;

  /// Kết quả lần kiểm tra kết nối gần nhất, null khi chưa kiểm tra lần nào.
  RemoteCheckResult? _checkResult;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _patController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  /// Thử kết nối bằng thông tin đang nhập, không lưu gì.
  /// Cố ý *không* chặn nút Connect: người dùng có thể đang offline mà vẫn muốn
  /// lưu cấu hình để dùng sau.
  Future<void> _checkConnection() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final pat = _patController.text.trim();
    final branch = _branchController.text.trim();

    if (url.isEmpty || username.isEmpty || pat.isEmpty) {
      setState(() => _checkResult = const RemoteCheckResult(
            RemoteCheckStatus.unknown,
            detail: 'Cần nhập đủ URL, username và PAT trước khi kiểm tra.',
          ));
      return;
    }

    setState(() {
      _checking = true;
      _checkResult = null;
    });

    final client = await ref.read(gitClientProvider.future);
    final result = await client.checkRemote(
      remoteUrl: url,
      username: username,
      password: pat,
      branch: branch.isEmpty ? 'main' : branch,
    );

    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = result;
    });
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final pat = _patController.text.trim();
    final branch = _branchController.text.trim();
    if (url.isEmpty || username.isEmpty || pat.isEmpty) return;

    setState(() => _loading = true);
    final config = GitConfig(
      remoteUrl: url,
      username: username,
      pat: pat,
      branch: branch.isEmpty ? 'main' : branch,
    );
    await ref.read(gitConfigRepoProvider).saveConfig(config);
    ref.invalidate(gitConfigProvider);
    setState(() => _loading = false);

    if (mounted) context.go('/onboarding/first-note');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Git Setup',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: colors.accentLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connect your private Git repository to sync notes across devices. You can always set this up later in Settings.',
                        style: TextStyle(
                          color: colors.accentLight,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField(
                'Git Remote URL',
                _urlController,
                'https://github.com/user/devnotes.git',
                colors,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Username',
                _usernameController,
                'your-github-username',
                colors,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Personal Access Token',
                _patController,
                'ghp_xxxxxxxxxxxx',
                colors,
                obscure: true,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Branch',
                _branchController,
                'main',
                colors,
              ),
              const SizedBox(height: 16),
              if (_checkResult != null) _buildCheckResult(colors),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkConnection,
                  icon: _checking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.accent))
                      : Icon(Icons.wifi_tethering, color: colors.accent),
                  label: Text(
                    _checking ? 'Đang kiểm tra…' : 'Kiểm tra kết nối',
                    style: TextStyle(
                        color: colors.accent, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _connect,
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textOnAccent,
                          ),
                        )
                      : Icon(Icons.sync, color: colors.textOnAccent),
                  label: Text(
                    'Connect Repository',
                    style: TextStyle(
                      color: colors.textOnAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/onboarding/first-note'),
                  child: Text(
                    'Skip for now — set up later in Settings',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hộp kết quả kiểm tra kết nối — xanh khi được, đỏ kèm hướng xử lý khi hỏng.
  Widget _buildCheckResult(AppColorScheme colors) {
    final result = _checkResult!;
    final good = result.ok;
    final tint = good ? colors.success : colors.error;
    final branch = _branchController.text.trim();

    return Container(
      key: const Key('remote-check-result'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tint.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(good ? Icons.check_circle : Icons.error_outline,
              color: tint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.describe(branch: branch.isEmpty ? 'main' : branch),
              style: TextStyle(color: tint, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint,
    AppColorScheme colors, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            filled: true,
            fillColor: colors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}
