import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBlue = Color(0xFF1C1C3A);
  static const Color pink = Color(0xFFD5006D);
  static const Color blue = Color(0xFF00BFFF);
  static const Color lightBlue = Color(0xFFA3D7E7);
  static const Color offWhite = Color(0xFFF0F0F0);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: offWhite,
    primaryColor: pink,
    colorScheme: const ColorScheme.light(
      primary: pink,
      onPrimary: offWhite,
      secondary: blue,
      onSecondary: offWhite,
      surface: offWhite,
      onSurface: darkBlue,
      background: offWhite,
      onBackground: darkBlue,
      error: Colors.redAccent,
      onError: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: darkBlue,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkBlue,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkBlue),
      bodyMedium: TextStyle(color: darkBlue),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: pink,
        foregroundColor: offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
      labelStyle: const TextStyle(color: darkBlue),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: pink,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBlue,
    primaryColor: pink,
    colorScheme: const ColorScheme.dark(
      primary: pink,
      onPrimary: offWhite,
      secondary: blue,
      onSecondary: offWhite,
      surface: darkBlue,
      onSurface: offWhite,
      background: darkBlue,
      onBackground: offWhite,
      error: Colors.redAccent,
      onError: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBlue,
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
        backgroundColor: pink,
        foregroundColor: offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pink, width: 2),
      ),
      labelStyle: const TextStyle(color: offWhite),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: pink,
      unselectedItemColor: Colors.grey,
    ),
  );
}