import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds [ThemeData] instances for dark and light variants.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colors = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bgPrimary,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: colors.accentLight,
        surface: colors.bgSurface,
        error: colors.error,
        onPrimary: colors.textOnAccent,
        onSecondary: colors.textOnAccent,
        onSurface: colors.textPrimary,
        onError: colors.textOnAccent,
      ),
      cardColor: colors.bgSurface,
      dividerColor: colors.border,
      textTheme: _buildTextTheme(colors.textPrimary, colors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgSecondary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.fabBg,
        foregroundColor: colors.textOnAccent,
      ),
    );
  }

  static ThemeData light() {
    final colors = AppColors.light;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.bgPrimary,
      colorScheme: ColorScheme.light(
        primary: colors.accent,
        secondary: colors.accentLight,
        surface: colors.bgSurface,
        error: colors.error,
        onPrimary: colors.textOnAccent,
        onSecondary: colors.textOnAccent,
        onSurface: colors.textPrimary,
        onError: colors.textOnAccent,
      ),
      cardColor: colors.bgSurface,
      dividerColor: colors.border,
      textTheme: _buildTextTheme(colors.textPrimary, colors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgSecondary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.fabBg,
        foregroundColor: colors.textOnAccent,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      bodyLarge: TextStyle(color: primary),
      bodyMedium: TextStyle(color: primary),
      bodySmall: TextStyle(color: secondary),
      titleLarge: TextStyle(color: primary),
      titleMedium: TextStyle(color: primary),
      titleSmall: TextStyle(color: secondary),
    );
  }
}

/// Extension to conveniently access [AppColorScheme] from any [ThemeData].
extension AppColorsExtension on ThemeData {
  AppColorScheme get appColors {
    return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  }
}
