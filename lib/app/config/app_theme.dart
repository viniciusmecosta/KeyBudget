import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  static const double defaultPadding = spaceM;
  static const double cardPadding = spaceL;
  static const double sectionPadding = spaceXL;

  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusXXL = 40.0;

  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceContainerHighest = Color(0xFF334155);
  static const Color onDarkSurface = Color(0xFFF8FAFC);
  static const Color onDarkSurfaceVariant = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static final List<Color> chartColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF6366F1),
    const Color(0xFFE11D48),
    const Color(0xFF14B8A6),
    const Color(0xFF8B5CF6),
    const Color(0xFF84CC16),
  ];

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF14B8A6),
      onSecondary: Colors.white,
      tertiary: const Color(0xFFF59E0B),
      onTertiary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
      brightness: Brightness.light,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: onSurfaceVariant.withAlpha((255 * 0.15).round()),
      outlineVariant: onSurfaceVariant.withAlpha((255 * 0.05).round()),
      shadow: onSurface.withAlpha((255 * 0.03).round()),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          color: onSurface,
          fontSize: 32,
          letterSpacing: -0.5),
      headlineSmall: const TextStyle(
          fontWeight: FontWeight.w700,
          color: onSurface,
          fontSize: 24,
          letterSpacing: -0.5),
      titleLarge: const TextStyle(
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontSize: 20,
          letterSpacing: -0.3),
      titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontSize: 16,
          letterSpacing: -0.2),
      titleSmall: const TextStyle(
          fontWeight: FontWeight.w600, color: onSurface, fontSize: 14),
      bodyLarge: const TextStyle(
          color: onSurface,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(
          color: onSurface,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodySmall: const TextStyle(
          color: onSurfaceVariant,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w400),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.2),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side:
            BorderSide(color: onSurfaceVariant.withAlpha((255 * 0.2).round())),
        padding:
            const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceS),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide:
            BorderSide(color: onSurfaceVariant.withAlpha((255 * 0.15).round())),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide:
            BorderSide(color: onSurfaceVariant.withAlpha((255 * 0.15).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceM),
      labelStyle: const TextStyle(color: onSurfaceVariant),
      floatingLabelStyle: const TextStyle(color: primary),
      hintStyle:
          TextStyle(color: onSurfaceVariant.withAlpha((255 * 0.6).round())),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
        side: BorderSide(
            color: onSurfaceVariant.withAlpha((255 * 0.1).round()), width: 1),
      ),
      color: surface,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: onSurfaceVariant.withAlpha((255 * 0.1).round()),
      thickness: 1,
      space: spaceM,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryDark,
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      onPrimary: Colors.white,
      secondary: const Color(0xFF2DD4BF),
      onSecondary: Colors.white,
      tertiary: const Color(0xFFFBBF24),
      onTertiary: darkBackground,
      surface: darkSurface,
      onSurface: onDarkSurface,
      error: error,
      onError: darkBackground,
      brightness: Brightness.dark,
      surfaceContainerHighest: darkSurfaceContainerHighest,
      onSurfaceVariant: onDarkSurfaceVariant,
      outline: onDarkSurfaceVariant.withAlpha((255 * 0.15).round()),
      outlineVariant: onDarkSurfaceVariant.withAlpha((255 * 0.05).round()),
      shadow: Colors.black.withAlpha((255 * 0.2).round()),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          color: onDarkSurface,
          fontSize: 32,
          letterSpacing: -0.5),
      headlineSmall: const TextStyle(
          fontWeight: FontWeight.w700,
          color: onDarkSurface,
          fontSize: 24,
          letterSpacing: -0.5),
      titleLarge: const TextStyle(
          fontWeight: FontWeight.w600,
          color: onDarkSurface,
          fontSize: 20,
          letterSpacing: -0.3),
      titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: onDarkSurface,
          fontSize: 16,
          letterSpacing: -0.2),
      titleSmall: const TextStyle(
          fontWeight: FontWeight.w600, color: onDarkSurface, fontSize: 14),
      bodyLarge: const TextStyle(
          color: onDarkSurface,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(
          color: onDarkSurface,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400),
      bodySmall: const TextStyle(
          color: onDarkSurfaceVariant,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w400),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      iconTheme: IconThemeData(color: onDarkSurface),
      titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onDarkSurface,
          letterSpacing: -0.2),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onDarkSurface,
        side: BorderSide(
            color: onDarkSurfaceVariant.withAlpha((255 * 0.2).round())),
        padding:
            const EdgeInsets.symmetric(horizontal: spaceL, vertical: spaceM),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding:
            const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceS),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
            color: onDarkSurfaceVariant.withAlpha((255 * 0.15).round())),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
            color: onDarkSurfaceVariant.withAlpha((255 * 0.15).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceM),
      labelStyle: const TextStyle(color: onDarkSurfaceVariant),
      floatingLabelStyle: const TextStyle(color: primaryDark),
      hintStyle:
          TextStyle(color: onDarkSurfaceVariant.withAlpha((255 * 0.6).round())),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
        side: BorderSide(
            color: onDarkSurface.withAlpha((255 * 0.1).round()), width: 1),
      ),
      color: darkSurface,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: onDarkSurfaceVariant.withAlpha((255 * 0.15).round()),
      thickness: 1,
      space: spaceM,
    ),
  );
}
