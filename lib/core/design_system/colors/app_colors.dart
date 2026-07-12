import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color tertiary = Color(0xFFF59E0B);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighestLight = Color(0xFFF1F5F9);
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceContainerHighestDark = Color(0xFF334155);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFE11D48),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFF84CC16),
  ];

  static Color getGradientSecondaryColor(Color primaryColor) {
    if (primaryColor.toARGB32() == 0xFF1E40AF) return const Color(0xFF3B82F6);
    if (primaryColor.toARGB32() == 0xFF2563EB) return const Color(0xFF60A5FA);
    if (primaryColor.toARGB32() == 0xFF15803D) return const Color(0xFF34D399);
    if (primaryColor.toARGB32() == 0xFFB91C1C) return const Color(0xFFF87171);
    if (primaryColor.toARGB32() == 0xFFC2410C) return const Color(0xFFFB923C);
    if (primaryColor.toARGB32() == 0xFF0E7490) return const Color(0xFF22D3EE);
    if (primaryColor.toARGB32() == 0xFF4338CA) return const Color(0xFF818CF8);
    if (primaryColor.toARGB32() == 0xFF0F766E) return const Color(0xFF2DD4BF);
    if (primaryColor.toARGB32() == 0xFF9F1239) return const Color(0xFFFB7185);

    return HSLColor.fromColor(primaryColor)
        .withLightness(
          (HSLColor.fromColor(primaryColor).lightness + 0.15).clamp(0.0, 1.0),
        )
        .toColor();
  }
}
