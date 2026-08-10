import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/settings/data/export_import_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text('Settings',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _sectionHeader('Git', colors),
                  _tile('Git Repository', Icons.commit, colors,
                      () => context.push('/settings/git')),
                  _sectionHeader('Sync', colors),
                  _tile('Sync Frequency', Icons.sync, colors, () {}),
                  _sectionHeader('Editor', colors),
                  _tile('Font & Size', Icons.text_fields, colors, () {}),
                  _tile('Toolbar Layout', Icons.dashboard_customize,
                      colors, () {}),
                  _sectionHeader('Appearance', colors),
                  _themeTile(context, ref, colors, theme),
                  _sectionHeader('Data', colors),
                  _tile('Export Notes', Icons.upload_file, colors, () async {
                    try {
                      final path =
                          await WorkspacePathProvider.getWorkspacePath();
                      final service =
                          ExportImportService(workspacePath: path);
                      final tempDir = await getTemporaryDirectory();
                      final zipPath = await service.exportToZip(
                          '${tempDir.path}/devnotes_export.zip');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exported to $zipPath')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  }),
                  _tile('Import Notes', Icons.download, colors, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Import from Files app coming soon'),
                      ),
                    );
                  }),
                  _tile(
                      'Rebuild Search Index', Icons.refresh, colors, () {}),
                  _sectionHeader('Collections', colors),
                  _tile('Manage Collections', Icons.folder, colors, () {}),
                  _sectionHeader('About', colors),
                  ListTile(
                    leading:
                        Icon(Icons.info_outline, color: colors.textMuted),
                    title: Text('DevNotes v1.0.0',
                        style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text(
                        'Local-first Markdown notes for devs',
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title,
          style: TextStyle(
              color: colors.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1)),
    );
  }

  Widget _tile(String title, IconData icon, AppColorScheme colors,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
    );
  }

  static String _themeLabel(ThemePreference t) =>
      t.name[0].toUpperCase() + t.name.substring(1);

  /// Theme picker. Uses a popup menu rather than a `DropdownButton` because the
  /// dropdown menu is laid out at the button's own width and overflowed the
  /// right screen edge from this trailing position; the popup
  /// route keeps itself inside the screen bounds.
  Widget _themeTile(BuildContext context, WidgetRef ref,
      AppColorScheme colors, ThemePreference current) {
    return ListTile(
      leading: Icon(Icons.palette, color: colors.textSecondary),
      title: Text('Theme', style: TextStyle(color: colors.textPrimary)),
      trailing: PopupMenuButton<ThemePreference>(
        key: const Key('theme-selector'),
        initialValue: current,
        color: colors.bgSecondary,
        tooltip: 'Chọn giao diện',
        onSelected: (value) =>
            ref.read(themeProvider.notifier).setTheme(value),
        itemBuilder: (_) => ThemePreference.values
            .map(
              (t) => PopupMenuItem(
                value: t,
                child: Text(
                  _themeLabel(t),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ),
            )
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _themeLabel(current),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            Icon(Icons.arrow_drop_down, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
