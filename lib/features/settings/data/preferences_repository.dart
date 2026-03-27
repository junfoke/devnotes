import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/core/utils/enums.dart';

class PreferencesRepository {
  Future<EditorPreferences> loadEditorPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return EditorPreferences(
      fontSize: prefs.getDouble('editor_font_size') ?? 14.0,
      fontFamily: prefs.getString('editor_font_family') ?? 'JetBrainsMono',
      autoSaveInterval: Duration(
          seconds: prefs.getInt('editor_autosave_seconds') ?? 3),
      toolbarItems: prefs.getStringList('editor_toolbar_items') ??
          EditorPreferences.defaultToolbarItems,
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == (prefs.getString('sync_frequency') ?? 'manual'),
        orElse: () => SyncFrequency.manual,
      ),
      periodicInterval: Duration(
          minutes: prefs.getInt('sync_periodic_minutes') ?? 30),
    );
  }

  Future<void> saveEditorPreferences(EditorPreferences pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('editor_font_size', pref.fontSize);
    await prefs.setString('editor_font_family', pref.fontFamily);
    await prefs.setInt(
        'editor_autosave_seconds', pref.autoSaveInterval.inSeconds);
    await prefs.setStringList('editor_toolbar_items', pref.toolbarItems);
    await prefs.setString('sync_frequency', pref.syncFrequency.name);
    await prefs.setInt(
        'sync_periodic_minutes', pref.periodicInterval.inMinutes);
  }
}
