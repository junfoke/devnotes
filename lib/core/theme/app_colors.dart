import 'package:flutter/material.dart';

/// Holds all color tokens for a single theme variant (dark or light).
class AppColorScheme {
  const AppColorScheme({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgSurface,
    required this.accent,
    required this.accentLight,
    required this.accentSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.border,
    required this.codeBg,
    required this.success,
    required this.error,
    required this.warning,
    required this.fabBg,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgSurface;
  final Color accent;
  final Color accentLight;
  final Color accentSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color border;
  final Color codeBg;
  final Color success;
  final Color error;
  final Color warning;
  final Color fabBg;
}

/// Provides static dark and light [AppColorScheme] instances.
class AppColors {
  AppColors._();

  static const AppColorScheme dark = AppColorScheme(
    bgPrimary: Color(0xFF0F0F1A),
    bgSecondary: Color(0xFF1A1A2E),
    bgTertiary: Color(0xFF16162A),
    bgSurface: Color(0xFF252540),
    accent: Color(0xFF7C3AED),
    accentLight: Color(0xFFA78BFA),
    accentSurface: Color(0xFF1E1040),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFF2D2D4A),
    codeBg: Color(0xFF1E1E3A),
    success: Color(0xFF22C55E),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    fabBg: Color(0xFF7C3AED),
  );

  static const AppColorScheme light = AppColorScheme(
    bgPrimary: Color(0xFFF8FAFC),
    bgSecondary: Color(0xFFF1F5F9),
    bgTertiary: Color(0xFFE2E8F0),
    bgSurface: Color(0xFFFFFFFF),
    accent: Color(0xFF7C3AED),
    accentLight: Color(0xFF8B5CF6),
    accentSurface: Color(0xFFF3EEFF),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    codeBg: Color(0xFFF1F5F9),
    success: Color(0xFF16A34A),
    error: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    fabBg: Color(0xFF7C3AED),
  );
}
