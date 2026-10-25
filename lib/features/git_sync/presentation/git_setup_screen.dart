import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/git_client/remote_check.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/application/sync_controller.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';
import 'package:devnotes/features/git_sync/presentation/conflict_screen.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';

class GitSetupScreen extends ConsumerStatefulWidget {
  const GitSetupScreen({super.key});

  @override
  ConsumerState<GitSetupScreen> createState() => _GitSetupScreenState();
}

class _GitSetupScreenState extends ConsumerState<GitSetupScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _patController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  bool _loading = false;
  bool _checking = false;
  bool _switching = false;

  /// Kết quả lần kiểm tra kết nối gần nhất, null khi chưa kiểm tra lần nào.
  RemoteCheckResult? _checkResult;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final GitConfig? config;
    try {
      config = await ref.read(gitConfigProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không đọc được cấu hình Git: $e')));
      }
      return;
    }
    if (config != null && mounted) {
      _urlController.text = config.remoteUrl;
      _usernameController.text = config.username;
      _patController.text = config.pat;
      _branchController.text = config.branch;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _patController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  /// Thử kết nối tới remote bằng đúng thông tin đang nhập trên form.
  ///
  /// Không lưu gì cả — mục đích là để người dùng biết credential có dùng được
  /// hay không *trước khi* lưu, thay vì chỉ phát hiện lúc bấm Sync.
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

    RemoteCheckResult result;
    try {
      final client = await ref.read(gitClientProvider.future);
      result = await client.checkRemote(
        remoteUrl: url,
        username: username,
        password: pat,
        branch: branch.isEmpty ? 'main' : branch,
      );
    } catch (e) {
      // Không để nút quay mãi nếu khởi tạo git/isolate lỗi.
      result = RemoteCheckResult(RemoteCheckStatus.unknown, detail: '$e');
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = result;
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final pat = _patController.text.trim();
    final branch = _branchController.text.trim();
    if (url.isEmpty || username.isEmpty || pat.isEmpty) {
      setState(() => _checkResult = const RemoteCheckResult(
            RemoteCheckStatus.unknown,
            detail: 'Cần nhập đủ URL, username và PAT để lưu.',
          ));
      return;
    }

    setState(() => _loading = true);
    final config = GitConfig(
      remoteUrl: url,
      username: username,
      pat: pat,
      branch: branch.isEmpty ? 'main' : branch,
    );
    try {
      await ref.read(gitConfigRepoProvider).saveConfig(config);
      ref.invalidate(gitConfigProvider);
      ref.invalidate(currentBranchProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không lưu được cấu hình Git: $e')));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Git credentials saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect Repository'),
        content: const Text(
          'This will remove your saved Git credentials. Your local notes will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(gitConfigRepoProvider).deleteConfig();
      ref.invalidate(gitConfigProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không xóa được cấu hình Git: $e')));
      }
      return;
    }
    if (mounted) {
      _urlController.clear();
      _usernameController.clear();
      _patController.clear();
      _branchController.text = 'main';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Git credentials removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Cảnh báo khi repo trên máy đang ở branch khác branch đã cấu hình (B-14),
  /// kèm nút chuyển. Repo chưa tồn tại thì provider trả về đúng branch cấu
  /// hình, nên không hiện gì.
  Widget _buildBranchMismatch(AppColorScheme colors, GitConfig config) {
    final local = ref.watch(currentBranchProvider).valueOrNull;
    if (local == null || local == config.branch) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const Key('branch-mismatch'),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: colors.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Branch không khớp cấu hình',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ghi chú trên máy đang ở branch "$local", nhưng cấu hình là '
            '"${config.branch}". Sync hiện đang đẩy lên "$local".',
            style: TextStyle(
                color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  _switching ? null : () => _switchBranch(local, config),
              child: _switching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Chuyển sang "${config.branch}"'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchBranch(String from, GitConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Chuyển sang "${config.branch}"?'),
        content: Text(
          'Ghi chú của "$from" sẽ được gộp vào "${config.branch}" rồi đẩy lên '
          'remote. Không note nào bị xóa; branch "$from" vẫn được giữ lại làm '
          'bản dự phòng.\n\nNếu cùng một note bị sửa khác nhau ở hai branch, '
          'bạn sẽ được chuyển tới màn hình giải quyết xung đột.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _switching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = await ref.read(gitClientProvider.future);
      // Cùng khóa với sync: không để sync tự động chạy chồng lúc đang chuyển.
      final result = await ref.read(syncControllerProvider).exclusive(
            () => client.switchBranch(
              config.branch,
              username: config.username,
              password: config.pat,
            ),
          );
      ref.invalidate(currentBranchProvider);
      ref.invalidate(noteListProvider);
      ref.read(syncStateProvider.notifier).setBranch(config.branch);
      if (!mounted) return;
      if (result.hasConflicts) {
        messenger.showSnackBar(SnackBar(
          content: Text('Đã chuyển sang "${config.branch}", còn '
              '${result.conflicts.length} note xung đột. Giải quyết xong '
              'rồi bấm Sync.'),
        ));
        // Khi chuyển branch, "ours" là branch đích, "theirs" là branch cũ.
        context.push(ConflictScreen.location(result.conflicts.first,
            ours: config.branch, theirs: from));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.pushError == null
              ? 'Đã chuyển sang "${config.branch}" và đẩy lên remote.'
              : 'Đã chuyển sang "${config.branch}" nhưng chưa đẩy lên được '
                  '(${result.pushError}). Lần Sync sau sẽ đẩy.'),
        ));
      }
    } catch (e) {
      ref.invalidate(currentBranchProvider);
      messenger.showSnackBar(
          SnackBar(content: Text('Chuyển branch thất bại: $e')));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final configAsync = ref.watch(gitConfigProvider);
    final hasConfig = configAsync.valueOrNull != null;

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
                  Text('Git Setup',
                      style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 24),
              // Status card
              if (hasConfig)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.success.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: colors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Configured", không phải "Connected": chỗ này chỉ
                            // biết là đã có credential lưu, chưa biết credential
                            // đó còn dùng được không. Muốn biết thì bấm nút
                            // "Kiểm tra kết nối" ở dưới.
                            Text('Repository configured',
                                style: TextStyle(color: colors.success, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              configAsync.valueOrNull?.remoteUrl ?? '',
                              style: TextStyle(color: colors.textMuted, fontSize: 12, fontFamily: 'JetBrainsMono'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.accentLight, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connect your private Git repository to sync notes across devices. Your data stays in your control.',
                          style: TextStyle(color: colors.accentLight, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              if (configAsync.valueOrNull case final config?)
                _buildBranchMismatch(colors, config),
              // Form fields
              _buildField('Git Remote URL', _urlController,
                  'https://github.com/user/devnotes.git', colors),
              const SizedBox(height: 20),
              _buildField('Username', _usernameController,
                  'your-github-username', colors),
              const SizedBox(height: 20),
              _buildField('Personal Access Token (PAT)', _patController,
                  'ghp_xxxxxxxxxxxx', colors, obscure: true),
              const SizedBox(height: 20),
              _buildField('Branch', _branchController,
                  'main', colors),
              const SizedBox(height: 16),
              // Security notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield, color: colors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your data is secure',
                              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Credentials are stored locally on your device using encrypted storage.',
                            style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Kết quả kiểm tra kết nối
              if (_checkResult != null) _buildCheckResult(colors),
              const SizedBox(height: 12),
              // Nút kiểm tra kết nối — chạy trước khi lưu
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
              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.textOnAccent))
                      : Icon(Icons.save, color: colors.textOnAccent),
                  label: Text(
                    hasConfig ? 'Update Credentials' : 'Save Credentials',
                    style: TextStyle(color: colors.textOnAccent, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              // Disconnect button (only if config exists)
              if (hasConfig) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _disconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Disconnect Repository'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      AppColorScheme colors, {bool obscure = false}) {
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
