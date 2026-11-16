import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Root canvas & elevation
  static const Color background = Color(0xFF0F131C);
  static const Color surface = Color(0xFF0F131C);
  static const Color surfaceContainerLowest = Color(0xFF0A0E16);
  static const Color surfaceContainerLow = Color(0xFF181C24);
  static const Color surfaceContainer = Color(0xFF1C2028);
  static const Color surfaceContainerHigh = Color(0xFF262A33);
  static const Color surfaceContainerHighest = Color(0xFF31353E);
  static const Color surfaceVariant = Color(0xFF31353E);
  static const Color surfaceDim = Color(0xFF0F131C);
  static const Color surfaceBright = Color(0xFF353942);

  // Primary: Electric Emerald
  static const Color primary = Color(0xFF4EDEA3);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFF003824);
  static const Color onPrimaryContainer = Color(0xFF00422B);
  static const Color surfaceTint = Color(0xFF4EDEA3);

  // Secondary: Celestial Violet / Indigo
  static const Color secondary = Color(0xFFC0C1FF);
  static const Color secondaryContainer = Color(0xFF3131C0);
  static const Color onSecondary = Color(0xFF1000A9);
  static const Color onSecondaryContainer = Color(0xFFB0B2FF);

  // Tertiary: Amber Warning
  static const Color tertiary = Color(0xFFFFB95F);
  static const Color tertiaryContainer = Color(0xFFE29100);
  static const Color onTertiary = Color(0xFF472A00);
  static const Color onTertiaryContainer = Color(0xFF523200);

  // Typography & Text Tiers
  static const Color onSurface = Color(0xFFDFE2EE);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFFBBCABF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);

  // Outlines & Borders
  static const Color outline = Color(0xFF86948A);
  static const Color outlineVariant = Color(0xFF3C4A42);
  static const Color cardBorder = Color(
    0x12FFFFFF,
  ); // rgba(255, 255, 255, 0.07)
  static const Color specularHighlight = Color(
    0x1FFFFFFF,
  ); // rgba(255, 255, 255, 0.12)

  // Status & Semantic
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color success = Color(0xFF10B981);
}
