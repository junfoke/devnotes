// Lựa chọn ngôn ngữ giao diện: System / Tiếng Việt / English.
//
// Luật: lưu ở SharedPreferences, key `app_locale`, giá trị `system`/`vi`/`en`.
// "System" theo ngôn ngữ máy; máy không dùng tiếng Việt hay tiếng Anh thì
// dùng tiếng Anh.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/l10n/locale_provider.dart';
import 'package:devnotes/core/theme/theme_provider.dart';

void main() {
  Future<(ProviderContainer, SharedPreferences)> containerWith(
      Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return (container, prefs);
  }

  group('localeProvider', () {
    test('chưa chọn gì thì mặc định là System', () async {
      final (container, _) = await containerWith({});

      expect(container.read(localeProvider), AppLocalePreference.system);
      expect(container.read(localeProvider).locale, isNull);
    });

    test('chọn Tiếng Việt / English thì lưu "vi" / "en"', () async {
      final (container, prefs) = await containerWith({});

      await container
          .read(localeProvider.notifier)
          .setLocale(AppLocalePreference.vi);
      expect(container.read(localeProvider), AppLocalePreference.vi);
      expect(prefs.getString('app_locale'), 'vi');

      await container
          .read(localeProvider.notifier)
          .setLocale(AppLocalePreference.en);
      expect(container.read(localeProvider), AppLocalePreference.en);
      expect(prefs.getString('app_locale'), 'en');
    });

    test('chọn lại System thì lưu "system"', () async {
      final (container, prefs) = await containerWith({'app_locale': 'vi'});

      await container
          .read(localeProvider.notifier)
          .setLocale(AppLocalePreference.system);

      expect(prefs.getString('app_locale'), 'system');
      expect(container.read(localeProvider).locale, isNull);
    });

    test('mở lại app thì đọc đúng lựa chọn đã lưu', () async {
      final (vi, _) = await containerWith({'app_locale': 'vi'});
      expect(vi.read(localeProvider), AppLocalePreference.vi);
      expect(vi.read(localeProvider).locale, const Locale('vi'));

      final (en, _) = await containerWith({'app_locale': 'en'});
      expect(en.read(localeProvider), AppLocalePreference.en);
      expect(en.read(localeProvider).locale, const Locale('en'));
    });

    test('giá trị lưu không hợp lệ thì quay về System', () async {
      final (container, _) = await containerWith({'app_locale': 'fr'});

      expect(container.read(localeProvider), AppLocalePreference.system);
    });
  });

  group('resolveAppLocale', () {
    test('máy dùng tiếng Việt thì hiện tiếng Việt', () {
      expect(resolveAppLocale(const [Locale('vi', 'VN')]), const Locale('vi'));
    });

    test('máy dùng tiếng Anh thì hiện tiếng Anh', () {
      expect(resolveAppLocale(const [Locale('en', 'GB')]), const Locale('en'));
    });

    test('máy dùng ngôn ngữ khác thì dùng tiếng Anh', () {
      expect(resolveAppLocale(const [Locale('fr', 'FR')]), const Locale('en'));
      expect(resolveAppLocale(const [Locale('ja')]), const Locale('en'));
      expect(resolveAppLocale(const []), const Locale('en'));
      expect(resolveAppLocale(null), const Locale('en'));
    });

    test('lấy ngôn ngữ đầu tiên app hỗ trợ trong danh sách ưu tiên', () {
      expect(
        resolveAppLocale(const [Locale('fr'), Locale('vi'), Locale('en')]),
        const Locale('vi'),
      );
    });
  });
}
