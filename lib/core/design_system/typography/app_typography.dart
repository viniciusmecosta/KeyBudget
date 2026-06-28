import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getTextTheme({required bool isDark}) {
    final baseTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final variantColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 40,
          letterSpacing: -1.0),
      displayMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 32,
          letterSpacing: -0.8),
      displaySmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 28,
          letterSpacing: -0.6),
      headlineLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 24,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 20,
          letterSpacing: -0.4),
      headlineSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 18,
          letterSpacing: -0.3),
      titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 16,
          letterSpacing: -0.2),
      titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 14,
          letterSpacing: -0.1),
      titleSmall: TextStyle(
          fontWeight: FontWeight.w600, color: textColor, fontSize: 12),
      bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodySmall: TextStyle(
          color: variantColor,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
          color: variantColor, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
          color: variantColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
  }
}
