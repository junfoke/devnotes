// AC-traceability tests for ThemeNotifier (change & persist theme).
//
// Nghiệp vụ: specs/BUSINESS_OVERVIEW.md#settings (theme)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devnotes/core/theme/theme_provider.dart';
import 'package:devnotes/core/utils/enums.dart';

void main() {
  group('UC-015 Change Theme', () {
    test('defaults to system when nothing persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemePreference.system);
    });

    // AC-1: chọn Dark -> state đổi và được lưu vào SharedPreferences
    test('AC-1: setTheme(dark) updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);

      await notifier.setTheme(ThemePreference.dark);

      expect(notifier.state, ThemePreference.dark);
      expect(prefs.getString('theme_preference'), 'dark');
    });

    // AC-2: system phân giải theo brightness thiết bị
    test('AC-2: system resolves to dark theme when device brightness is dark',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);

      final dark = notifier.resolveTheme(Brightness.dark);
      final light = notifier.resolveTheme(Brightness.light);

      expect(dark.brightness, Brightness.dark);
      expect(light.brightness, Brightness.light);
    });

    // AC-3: bền vững qua khởi động lại (đọc lại từ prefs đã lưu)
    test('AC-3: persisted preference is restored on reload', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemePreference.dark);
    });

    test('invalid persisted value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'bogus'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemePreference.system);
    });
  });
}
