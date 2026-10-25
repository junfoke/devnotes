import 'package:flutter_riverpod/flutter_riverpod.dart';
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
