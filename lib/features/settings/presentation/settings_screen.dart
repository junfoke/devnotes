import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:devnotes/core/theme/app_theme.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';
import 'package:devnotes/features/settings/application/settings_providers.dart';
import 'package:devnotes/features/settings/data/export_import_service.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/features/settings/presentation/editor_settings_sheets.dart';
import 'package:devnotes/features/workspace/application/search_providers.dart';
import 'package:devnotes/features/workspace/application/workspace_providers.dart';

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
                  _tile('Sync Frequency', Icons.sync, colors,
                      () => _openEditorSheet(context, ref,
                          (prefs) => SyncFrequencySheet(initial: prefs))),
                  _sectionHeader('Editor', colors),
                  _tile('Font & Size', Icons.text_fields, colors,
                      () => _openEditorSheet(context, ref,
                          (prefs) => FontSettingsSheet(initial: prefs))),
                  _tile('Toolbar Layout', Icons.dashboard_customize, colors,
                      () => _openEditorSheet(context, ref,
                          (prefs) => ToolbarLayoutSheet(initial: prefs))),
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
                      // File nằm trong cache riêng của app, user không tự mở
                      // được — phải đưa qua share sheet để lưu ra Drive/Files
                      // hoặc gửi đi (B-08).
                      await Share.shareXFiles(
                        [XFile(zipPath, mimeType: 'application/zip')],
                        subject: 'DevNotes export',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  }),
                  _tile('Import Notes', Icons.download, colors,
                      () => _importNotes(context, ref)),
                  _tile('Rebuild Search Index', Icons.refresh, colors,
                      () => _rebuildSearchIndex(context, ref)),
                  _sectionHeader('Collections', colors),
                  _tile('Manage Collections', Icons.folder, colors,
                      () => context.push('/settings/collections')),
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

  Future<void> _openEditorSheet(BuildContext context, WidgetRef ref,
      Widget Function(EditorPreferences prefs) builder) async {
    final prefs = await ref.read(editorPreferencesProvider.future);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).appColors.bgSecondary,
      builder: (_) => builder(prefs),
    );
  }

  /// Chọn file zip rồi nhập — không ghi đè note nào, xem
  /// `ExportImportService.importFromZip`.
  Future<void> _importNotes(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final zipPath = picked?.files.single.path;
    if (zipPath == null || !context.mounted) return;

    final String summary;
    try {
      final path = await WorkspacePathProvider.getWorkspacePath();
      final report =
          await ExportImportService(workspacePath: path).importFromZip(zipPath);
      ref.invalidate(noteListProvider);
      summary = [
        'Thêm mới: ${report.added.length}',
        'Bỏ qua vì đã có y hệt: ${report.skippedIdentical.length}',
        'Trùng tên nên lưu thành bản sao: ${report.copied.length}',
        for (final e in report.copied.entries) '   ${e.key} → ${e.value}',
        if (report.rejected.isNotEmpty)
          'Từ chối (đường dẫn không an toàn): ${report.rejected.length}',
        for (final name in report.rejected) '   $name',
      ].join('\n');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nhập thất bại: $e')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đã nhập ghi chú'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Đọc lại toàn bộ note trên đĩa và dựng lại chỉ mục tìm kiếm.
  Future<void> _rebuildSearchIndex(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Đang dựng lại chỉ mục tìm kiếm...')));
    try {
      ref.invalidate(noteListProvider);
      ref.invalidate(searchIndexInitProvider);
      await ref.read(searchIndexInitProvider.future);
      final count = (await ref.read(noteListProvider.future)).length;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('Đã dựng lại chỉ mục cho $count ghi chú')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('Dựng lại chỉ mục thất bại: $e')));
    }
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
