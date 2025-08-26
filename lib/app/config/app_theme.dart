import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6A5AE0);
  static const Color primaryVariant = Color(0xFF8A7AF3);
  static const Color secondary = Color(0xFF23B0B0);
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E1E2D);
  static const Color darkBackground = Color(0xFF12121E);
  static const Color darkSurface = Color(0xFF1E1E2D);
  static const Color onDarkSurface = Color(0xFFF5F5F7);
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);

  static const Color positiveChange = Color(0xFFE57373);
  static const Color negativeChange = Color(0xFF81C784);

  static final List<Color> chartColors = [
    const Color(0xFFF4A261),
    const Color(0xFF2A9D8F),
    const Color(0xFFE76F51),
    const Color(0xFF264653),
    const Color(0xFFE9C46A),
    const Color(0xFF9B5DE5),
    const Color(0xFF00B295),
    const Color(0xFFF15BB5),
  ];

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: surface,
      secondary: secondary,
      onSecondary: surface,
      surface: surface,
      onSurface: onSurface,
      background: background,
      onBackground: onSurface,
      error: error,
      onError: surface,
      brightness: Brightness.light,
      tertiary: chartColors[5],
    ).copyWith(
      secondaryContainer: success,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold, color: onSurface, fontSize: 28),
      bodyMedium: const TextStyle(color: onSurface, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 5,
        shadowColor: primary.withOpacity(0.4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: onSurface.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surface,
    ),
    shadowColor: onSurface.withOpacity(0.1),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryVariant,
    colorScheme: ColorScheme.dark(
      primary: primaryVariant,
      onPrimary: onDarkSurface,
      secondary: secondary,
      onSecondary: onDarkSurface,
      surface: darkSurface,
      onSurface: onDarkSurface,
      background: darkBackground,
      onBackground: onDarkSurface,
      error: error,
      onError: surface,
      brightness: Brightness.dark,
      tertiary: chartColors[5],
    ).copyWith(secondaryContainer: success),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold, color: onDarkSurface, fontSize: 28),
      bodyMedium: const TextStyle(color: onDarkSurface, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: onDarkSurface),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onDarkSurface,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryVariant,
        foregroundColor: onDarkSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 5,
        shadowColor: primaryVariant.withOpacity(0.4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: onDarkSurface.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: onDarkSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: darkSurface,
    ),
    shadowColor: onDarkSurface.withOpacity(0.1),
  );
}
