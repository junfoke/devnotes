import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/enums.dart';
import 'app_theme.dart';

const _kThemePreferenceKey = 'theme_preference';

/// Manages and persists the user's [ThemePreference].
class ThemeNotifier extends StateNotifier<ThemePreference> {
  ThemeNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences _prefs;

  static ThemePreference _loadInitial(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemePreferenceKey);
    if (saved == null) return ThemePreference.system;
    return ThemePreference.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemePreference.system,
    );
  }

  /// Updates the preference and persists it.
  Future<void> setTheme(ThemePreference preference) async {
    state = preference;
    await _prefs.setString(_kThemePreferenceKey, preference.name);
  }

  /// Resolves the effective [ThemeData] given the current platform brightness.
  ThemeData resolveTheme(Brightness platformBrightness) {
    switch (state) {
      case ThemePreference.dark:
        return AppTheme.dark();
      case ThemePreference.light:
        return AppTheme.light();
      case ThemePreference.system:
        return platformBrightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light();
    }
  }
}

/// Provider for [ThemeNotifier]. Requires [SharedPreferences] to be available
/// via [sharedPreferencesProvider].
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemePreference>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Override this provider at app startup with the actual [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at app startup.',
  );
});
