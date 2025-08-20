import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkGrey = Color(0xFF393D3F);
  static const Color offWhite = Color(0xFFFDFDFF);
  static const Color softGrey = Color(0xFFC6C5B9);
  static const Color accentBlue = Color(0xFF62929E);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: offWhite,
    primaryColor: accentBlue,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      onPrimary: offWhite,
      secondary: softGrey,
      onSecondary: darkGrey,
      background: offWhite,
      onBackground: darkGrey,
      surface: offWhite,
      onSurface: darkGrey,
      error: Colors.redAccent,
      onError: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: darkGrey,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkGrey,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkGrey),
      bodyMedium: TextStyle(color: darkGrey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: softGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: softGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: darkGrey),
    ),
  );
}
