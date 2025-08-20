import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkestGrey = Color(0xFF222831);
  static const Color darkGrey = Color(0xFF31363F);
  static const Color accentTeal = Color(0xFF76ABAE);
  static const Color offWhite = Color(0xFFEEEEEE);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: offWhite,
    primaryColor: accentTeal,
    colorScheme: const ColorScheme.light(
      primary: accentTeal,
      onPrimary: darkestGrey,
      secondary: darkGrey,
      onSecondary: offWhite,
      background: offWhite,
      onBackground: darkestGrey,
      surface: offWhite,
      onSurface: darkestGrey,
      error: Colors.redAccent,
      onError: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: darkestGrey,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkestGrey,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkestGrey),
      bodyMedium: TextStyle(color: darkestGrey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentTeal,
        foregroundColor: offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentTeal, width: 2),
      ),
      labelStyle: const TextStyle(color: darkestGrey),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkestGrey,
    primaryColor: accentTeal,
    colorScheme: const ColorScheme.dark(
      primary: accentTeal,
      onPrimary: darkestGrey,
      secondary: offWhite,
      onSecondary: darkestGrey,
      background: darkestGrey,
      onBackground: offWhite,
      surface: darkGrey,
      onSurface: offWhite,
      error: Colors.redAccent,
      onError: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkestGrey,
      foregroundColor: offWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: offWhite,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: offWhite),
      bodyMedium: TextStyle(color: offWhite),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentTeal,
        foregroundColor: darkestGrey,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: offWhite),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: offWhite),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentTeal, width: 2),
      ),
      labelStyle: const TextStyle(color: offWhite),
    ),
  );
}
