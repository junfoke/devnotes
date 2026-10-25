import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/core/utils/enums.dart';

class PreferencesRepository {
  Future<EditorPreferences> loadEditorPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    var toolbar = prefs.getStringList('editor_toolbar_items');
    if (!(prefs.getBool('editor_tools_migrated_v1') ?? false)) {
      // Di trú một lần: người dùng cũ được thêm 4 nút mới lên ĐẦU danh sách
      // ghim (ruling R5 — để cuối thì khuất màn hình trên điện thoại hẹp).
      if (toolbar != null) {
        toolbar = [
          for (final id in EditorPreferences.pinnedAddedByToolsUpdate)
            if (!toolbar.contains(id)) id,
          ...toolbar,
        ];
        await prefs.setStringList('editor_toolbar_items', toolbar);
      }
      await prefs.setBool('editor_tools_migrated_v1', true);
    }
    return EditorPreferences(
      lineHeight: EditorLineHeight.values.firstWhere(
        (e) => e.name == prefs.getString('editor_line_height'),
        orElse: () => EditorLineHeight.normal,
      ),
      wordWrap: prefs.getBool('editor_word_wrap') ?? true,
      focusMode: prefs.getBool('editor_focus_mode') ?? false,
      hiddenTools: prefs.getStringList('editor_hidden_tools') ?? const [],
      fontSize:
          prefs.getDouble('editor_font_size') ??
          EditorPreferences.defaultFontSize,
      fontFamily: prefs.getString('editor_font_family') ?? 'JetBrainsMono',
      autoSaveInterval: Duration(
        seconds:
            prefs.getInt('editor_autosave_seconds') ??
            EditorPreferences.defaultAutoSaveInterval.inSeconds,
      ),
      toolbarItems: toolbar ?? EditorPreferences.defaultToolbarItems,
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == (prefs.getString('sync_frequency') ?? 'manual'),
        orElse: () => SyncFrequency.manual,
      ),
      periodicInterval: Duration(
        minutes: prefs.getInt('sync_periodic_minutes') ?? 30,
      ),
    );
  }

  Future<void> saveEditorPreferences(EditorPreferences pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('editor_font_size', pref.fontSize);
    await prefs.setString('editor_font_family', pref.fontFamily);
    await prefs.setInt(
      'editor_autosave_seconds',
      pref.autoSaveInterval.inSeconds,
    );
    await prefs.setStringList('editor_toolbar_items', pref.toolbarItems);
    await prefs.setString('editor_line_height', pref.lineHeight.name);
    await prefs.setBool('editor_word_wrap', pref.wordWrap);
    await prefs.setBool('editor_focus_mode', pref.focusMode);
    await prefs.setStringList('editor_hidden_tools', pref.hiddenTools);
    // Lưu tức là đã chốt danh sách ghim: không di trú nữa.
    await prefs.setBool('editor_tools_migrated_v1', true);
    await prefs.setString('sync_frequency', pref.syncFrequency.name);
    await prefs.setInt(
      'sync_periodic_minutes',
      pref.periodicInterval.inMinutes,
    );
  }
}
