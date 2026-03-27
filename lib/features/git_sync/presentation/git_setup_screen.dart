import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/features/git_sync/application/git_providers.dart';
import 'package:devnotes/features/git_sync/domain/git_config.dart';

class GitSetupScreen extends ConsumerStatefulWidget {
  const GitSetupScreen({super.key});

  @override
  ConsumerState<GitSetupScreen> createState() => _GitSetupScreenState();
}

class _GitSetupScreenState extends ConsumerState<GitSetupScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _patController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final config = await ref.read(gitConfigProvider.future);
    if (config != null && mounted) {
      _urlController.text = config.remoteUrl;
      _usernameController.text = config.username;
      _patController.text = config.pat;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _patController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final pat = _patController.text.trim();
    if (url.isEmpty || username.isEmpty || pat.isEmpty) return;

    setState(() => _loading = true);
    final config = GitConfig(remoteUrl: url, username: username, pat: pat);
    await ref.read(gitConfigRepoProvider).saveConfig(config);
    ref.invalidate(gitConfigProvider);
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

    await ref.read(gitConfigRepoProvider).deleteConfig();
    ref.invalidate(gitConfigProvider);
    if (mounted) {
      _urlController.clear();
      _usernameController.clear();
      _patController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Git credentials removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                            Text('Repository Connected',
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
              // Form fields
              _buildField('Git Remote URL', _urlController,
                  'https://github.com/user/devnotes.git', colors),
              const SizedBox(height: 20),
              _buildField('Username', _usernameController,
                  'your-github-username', colors),
              const SizedBox(height: 20),
              _buildField('Personal Access Token (PAT)', _patController,
                  'ghp_xxxxxxxxxxxx', colors, obscure: true),
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
              const SizedBox(height: 32),
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
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Skip for now — use local storage only',
                      style: TextStyle(color: colors.textMuted, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
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
