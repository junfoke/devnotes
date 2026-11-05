import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';

const kLocalePreferenceKey = 'app_locale';

/// Ngôn ngữ giao diện user chọn trong Settings → Giao diện → Ngôn ngữ.
///
/// Giá trị lưu xuống SharedPreferences là [name]: `system` / `vi` / `en`.
enum AppLocalePreference {
  /// Theo ngôn ngữ của máy; máy không dùng tiếng Việt hay tiếng Anh thì dùng
  /// tiếng Anh.
  system,
  vi,
  en;

  /// Locale ép cho `MaterialApp.locale`; null nghĩa là theo máy.
  Locale? get locale => switch (this) {
        AppLocalePreference.system => null,
        AppLocalePreference.vi => const Locale('vi'),
        AppLocalePreference.en => const Locale('en'),
      };
}

/// Các ngôn ngữ app hỗ trợ — tiếng Anh đứng đầu vì là ngôn ngữ dự phòng.
const kSupportedLocales = [Locale('en'), Locale('vi')];

/// Chọn ngôn ngữ hiển thị từ danh sách ngôn ngữ ưu tiên (của máy, hoặc locale
/// user đã ép): lấy ngôn ngữ đầu tiên app hỗ trợ, không có thì tiếng Anh.
Locale resolveAppLocale(List<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final supported in kSupportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return kSupportedLocales.first;
}

/// Quản lý và lưu [AppLocalePreference] — cùng khuôn với `ThemeNotifier`.
class LocaleNotifier extends StateNotifier<AppLocalePreference> {
  LocaleNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences _prefs;

  static AppLocalePreference _loadInitial(SharedPreferences prefs) {
    final saved = prefs.getString(kLocalePreferenceKey);
    if (saved == null) return AppLocalePreference.system;
    return AppLocalePreference.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppLocalePreference.system,
    );
  }

  /// Đổi ngôn ngữ và lưu lại.
  Future<void> setLocale(AppLocalePreference preference) async {
    state = preference;
    await _prefs.setString(kLocalePreferenceKey, preference.name);
  }
}

/// Provider cho [LocaleNotifier]. Cần [sharedPreferencesProvider] được
/// override lúc khởi động app, giống `themeProvider`.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, AppLocalePreference>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
