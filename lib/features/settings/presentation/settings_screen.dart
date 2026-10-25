import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:devnotes/core/file_system/workspace_path_provider.dart';
import 'package:devnotes/core/l10n/l10n.dart';
import 'package:devnotes/core/l10n/locale_provider.dart';
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
    final l = context.l10n;
    final theme = ref.watch(themeProvider);
    final language = ref.watch(localeProvider);

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
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      l.settingsTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _sectionHeader(l.settingsSectionGit, colors),
                  _tile(
                    l.settingsGitRepository,
                    Icons.commit,
                    colors,
                    () => context.push('/settings/git'),
                  ),
                  _sectionHeader(l.settingsSectionSync, colors),
                  _tile(
                    l.settingsSyncFrequency,
                    Icons.sync,
                    colors,
                    () => _openEditorSheet(
                      context,
                      ref,
                      (prefs) => SyncFrequencySheet(initial: prefs),
                    ),
                  ),
                  _sectionHeader(l.settingsSectionEditor, colors),
                  _tile(
                    l.settingsFontAndSize,
                    Icons.text_fields,
                    colors,
                    () => _openEditorSheet(
                      context,
                      ref,
                      (prefs) => FontSettingsSheet(initial: prefs),
                    ),
                  ),
                  _tile(
                    l.settingsToolbarLayout,
                    Icons.dashboard_customize,
                    colors,
                    () => _openEditorSheet(
                      context,
                      ref,
                      (prefs) => ToolbarLayoutSheet(initial: prefs),
                    ),
                  ),
                  _sectionHeader(l.settingsSectionAppearance, colors),
                  _themeTile(context, ref, colors, theme),
                  _languageTile(context, ref, colors, language),
                  _sectionHeader(l.settingsSectionData, colors),
                  _tile(l.settingsExportNotes, Icons.upload_file, colors,
                      () async {
                    try {
                      final path =
                          await WorkspacePathProvider.getWorkspacePath();
                      final service = ExportImportService(workspacePath: path);
                      final tempDir = await getTemporaryDirectory();
                      final zipPath = await service.exportToZip(
                        '${tempDir.path}/devnotes_export.zip',
                      );
                      // File nằm trong cache riêng của app, user không tự mở
                      // được — phải đưa qua share sheet để lưu ra Drive/Files
                      // hoặc gửi đi (B-08).
                      await Share.shareXFiles([
                        XFile(zipPath, mimeType: 'application/zip'),
                      ], subject: l.settingsExportSubject);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.settingsExportFailed('$e'))),
                        );
                      }
                    }
                  }),
                  _tile(
                    l.settingsImportNotes,
                    Icons.download,
                    colors,
                    () => _importNotes(context, ref),
                  ),
                  _tile(
                    l.settingsRebuildIndex,
                    Icons.refresh,
                    colors,
                    () => _rebuildSearchIndex(context, ref),
                  ),
                  _sectionHeader(l.settingsSectionCollections, colors),
                  _tile(
                    l.settingsManageCollections,
                    Icons.folder,
                    colors,
                    () => context.push('/settings/collections'),
                  ),
                  _sectionHeader(l.settingsSectionAbout, colors),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: colors.textMuted),
                    title: Text(
                      'DevNotes ${ref.watch(appVersionProvider).valueOrNull ?? ''}'
                          .trim(),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      l.settingsAboutTagline,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditorSheet(
    BuildContext context,
    WidgetRef ref,
    Widget Function(EditorPreferences prefs) builder,
  ) async {
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

    final l = context.l10n;
    final String summary;
    try {
      final path = await WorkspacePathProvider.getWorkspacePath();
      final report = await ExportImportService(
        workspacePath: path,
      ).importFromZip(zipPath);
      ref.invalidate(noteListProvider);
      summary = [
        l.importAdded(report.added.length),
        l.importSkippedIdentical(report.skippedIdentical.length),
        l.importCopied(report.copied.length),
        for (final e in report.copied.entries) '   ${e.key} → ${e.value}',
        if (report.rejected.isNotEmpty)
          l.importRejected(report.rejected.length),
        for (final name in report.rejected) '   $name',
      ].join('\n');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(l.importFailed(e is ImportException
                ? l.importInvalidZip(e.detail)
                : '$e'))));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.importDoneTitle),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  /// Đọc lại toàn bộ note trên đĩa và dựng lại chỉ mục tìm kiếm.
  Future<void> _rebuildSearchIndex(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    messenger.showSnackBar(
      SnackBar(content: Text(l.rebuildIndexInProgress)),
    );
    try {
      ref.invalidate(noteListProvider);
      ref.invalidate(searchIndexInitProvider);
      await ref.read(searchIndexInitProvider.future);
      final count = (await ref.read(noteListProvider.future)).length;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l.rebuildIndexDone(count))),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l.rebuildIndexFailed('$e'))),
        );
    }
  }

  Widget _sectionHeader(String title, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.accentLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _tile(
    String title,
    IconData icon,
    AppColorScheme colors,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
    );
  }

  static String _themeLabel(AppLocalizations l, ThemePreference t) =>
      switch (t) {
        ThemePreference.system => l.themeSystem,
        ThemePreference.light => l.themeLight,
        ThemePreference.dark => l.themeDark,
      };

  static String _languageLabel(AppLocalizations l, AppLocalePreference p) =>
      switch (p) {
        AppLocalePreference.system => l.languageSystem,
        AppLocalePreference.vi => l.languageVietnamese,
        AppLocalePreference.en => l.languageEnglish,
      };

  /// Theme picker. Uses a popup menu rather than a `DropdownButton` because the
  /// dropdown menu is laid out at the button's own width and overflowed the
  /// right screen edge from this trailing position; the popup
  /// route keeps itself inside the screen bounds.
  Widget _themeTile(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    ThemePreference current,
  ) {
    final l = context.l10n;
    return ListTile(
      leading: Icon(Icons.palette, color: colors.textSecondary),
      title: Text(l.settingsTheme, style: TextStyle(color: colors.textPrimary)),
      trailing: PopupMenuButton<ThemePreference>(
        key: const Key('theme-selector'),
        initialValue: current,
        color: colors.bgSecondary,
        tooltip: l.settingsThemeTooltip,
        onSelected: (value) => ref.read(themeProvider.notifier).setTheme(value),
        itemBuilder: (_) => ThemePreference.values
            .map(
              (t) => PopupMenuItem(
                value: t,
                child: Text(
                  _themeLabel(l, t),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ),
            )
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _themeLabel(l, current),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            Icon(Icons.arrow_drop_down, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  /// Chọn ngôn ngữ giao diện — cùng kiểu popup với ô chọn theme ở trên.
  Widget _languageTile(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    AppLocalePreference current,
  ) {
    final l = context.l10n;
    return ListTile(
      leading: Icon(Icons.language, color: colors.textSecondary),
      title:
          Text(l.settingsLanguage, style: TextStyle(color: colors.textPrimary)),
      trailing: PopupMenuButton<AppLocalePreference>(
        key: const Key('language-selector'),
        initialValue: current,
        color: colors.bgSecondary,
        tooltip: l.settingsLanguageTooltip,
        onSelected: (value) =>
            ref.read(localeProvider.notifier).setLocale(value),
        itemBuilder: (_) => AppLocalePreference.values
            .map(
              (p) => PopupMenuItem(
                value: p,
                child: Text(
                  _languageLabel(l, p),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ),
            )
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _languageLabel(l, current),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            Icon(Icons.arrow_drop_down, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
