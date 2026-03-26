import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devnotes/core/theme/app_colors.dart';
import 'package:devnotes/core/theme/app_theme.dart';

void main() {
  group('AppColors - dark palette', () {
    final dark = AppColors.dark;

    test('bgPrimary is defined', () {
      expect(dark.bgPrimary, const Color(0xFF0F0F1A));
    });

    test('accent is defined', () {
      expect(dark.accent, const Color(0xFF7C3AED));
    });

    test('textPrimary is defined', () {
      expect(dark.textPrimary, const Color(0xFFE2E8F0));
    });

    test('all color fields are non-null', () {
      expect(dark.bgPrimary, isNotNull);
      expect(dark.bgSecondary, isNotNull);
      expect(dark.bgTertiary, isNotNull);
      expect(dark.bgSurface, isNotNull);
      expect(dark.accent, isNotNull);
      expect(dark.accentLight, isNotNull);
      expect(dark.accentSurface, isNotNull);
      expect(dark.textPrimary, isNotNull);
      expect(dark.textSecondary, isNotNull);
      expect(dark.textMuted, isNotNull);
      expect(dark.textOnAccent, isNotNull);
      expect(dark.border, isNotNull);
      expect(dark.codeBg, isNotNull);
      expect(dark.success, isNotNull);
      expect(dark.error, isNotNull);
      expect(dark.warning, isNotNull);
      expect(dark.fabBg, isNotNull);
    });
  });

  group('AppColors - light palette', () {
    final light = AppColors.light;

    test('bgPrimary is defined', () {
      expect(light.bgPrimary, const Color(0xFFF8FAFC));
    });

    test('accent is defined', () {
      expect(light.accent, const Color(0xFF7C3AED));
    });

    test('textPrimary is defined', () {
      expect(light.textPrimary, const Color(0xFF1E293B));
    });

    test('all color fields are non-null', () {
      expect(light.bgPrimary, isNotNull);
      expect(light.bgSecondary, isNotNull);
      expect(light.bgTertiary, isNotNull);
      expect(light.bgSurface, isNotNull);
      expect(light.accent, isNotNull);
      expect(light.accentLight, isNotNull);
      expect(light.accentSurface, isNotNull);
      expect(light.textPrimary, isNotNull);
      expect(light.textSecondary, isNotNull);
      expect(light.textMuted, isNotNull);
      expect(light.textOnAccent, isNotNull);
      expect(light.border, isNotNull);
      expect(light.codeBg, isNotNull);
      expect(light.success, isNotNull);
      expect(light.error, isNotNull);
      expect(light.warning, isNotNull);
      expect(light.fabBg, isNotNull);
    });
  });

  group('AppTheme', () {
    test('dark() returns ThemeData with dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('light() returns ThemeData with light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme appColors extension returns dark palette', () {
      final theme = AppTheme.dark();
      expect(theme.appColors.bgPrimary, const Color(0xFF0F0F1A));
    });

    test('light theme appColors extension returns light palette', () {
      final theme = AppTheme.light();
      expect(theme.appColors.bgPrimary, const Color(0xFFF8FAFC));
    });
  });
}
