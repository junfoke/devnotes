import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:devnotes/features/settings/domain/editor_preferences.dart';
import 'package:devnotes/features/settings/data/preferences_repository.dart';

final preferencesRepoProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(),
);

final editorPreferencesProvider = FutureProvider<EditorPreferences>((
  ref,
) async {
  final repo = ref.watch(preferencesRepoProvider);
  return repo.loadEditorPreferences();
});

/// Phiên bản app đọc từ gói cài đặt (vd "v1.0.0") — không ghi cứng trong UI.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});
