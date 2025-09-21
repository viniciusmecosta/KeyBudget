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
  static const double cardPadding = 20.0;
  static const double sectionPadding = 24.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // Paleta principal mais refinada
  static const Color primary = Color(0xFF6A5AE0);
  static const Color primaryVariant = Color(0xFF8A7AF3);
  static const Color primaryLight = Color(0xFFF0EDFF);
  static const Color secondary = Color(0xFF23B0B0);
  static const Color secondaryLight = Color(0xFFE6F7F7);

  // Backgrounds e surfaces com maior contraste
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Dark theme com melhor contraste
  static const Color darkBackground = Color(0xFF0F0F17);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF24243A);
  static const Color onDarkSurface = Color(0xFFF5F5F7);
  static const Color onDarkSurfaceVariant = Color(0xFF9CA3AF);

  // Estados e alertas
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Indicadores de mudança
  static const Color positiveChange = Color(0xFFEF4444);
  static const Color negativeChange = Color(0xFF10B981);

  // Paleta para gráficos mais harmoniosa
  static final List<Color> chartColors = [
    const Color(0xFFFF6B6B), // Coral suave
    const Color(0xFF4ECDC4), // Turquesa
    const Color(0xFF45B7D1), // Azul céu
    const Color(0xFF96CEB4), // Verde menta
    const Color(0xFFFFA07A), // Salmão
    const Color(0xFF9B59B6), // Roxo
    const Color(0xFFFFD93D), // Amarelo vibrante
    const Color(0xFF6C5CE7), // Roxo profundo
    const Color(0xFF00B894), // Verde esmeralda
    const Color(0xFFE17055), // Laranja terra
    const Color(0xFF74B9FF), // Azul claro
    const Color(0xFFE84393), // Rosa magenta
    const Color(0xFF00CEC9), // Ciano
    const Color(0xFFFDCB6E), // Amarelo dourado
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
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: onSurfaceVariant.withOpacity(0.2),
      outlineVariant: onSurfaceVariant.withOpacity(0.1),
      shadow: onSurface.withOpacity(0.1),
    ).copyWith(
      secondaryContainer: success,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontSize: 28,
        height: 1.2,
      ),
      headlineSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontSize: 24,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontSize: 22,
        height: 1.3,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontSize: 16,
        height: 1.4,
      ),
      titleSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontSize: 14,
        height: 1.4,
      ),
      bodyLarge: const TextStyle(
        color: onSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        color: onSurface,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: const TextStyle(
        color: onSurfaceVariant,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.2,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: onSurfaceVariant.withOpacity(0.1),
        ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(color: onSurfaceVariant),
      floatingLabelStyle: const TextStyle(color: primary),
      hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.6)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
        side: BorderSide(color: onSurfaceVariant.withOpacity(0.08), width: 1),
      ),
      color: surface,
      shadowColor: onSurface.withOpacity(0.05),
    ),
    dividerTheme: DividerThemeData(
      color: onSurfaceVariant.withOpacity(0.12),
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return onSurfaceVariant;
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.3);
          }
          return onSurfaceVariant.withOpacity(0.2);
        },
      ),
    ),
    shadowColor: onSurface.withOpacity(0.03),
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
      surfaceVariant: darkSurfaceVariant,
      onSurfaceVariant: onDarkSurfaceVariant,
      outline: onDarkSurfaceVariant.withOpacity(0.2),
      outlineVariant: onDarkSurfaceVariant.withOpacity(0.1),
      shadow: Colors.black.withOpacity(0.3),
    ).copyWith(
      secondaryContainer: success,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.w700,
        color: onDarkSurface,
        fontSize: 28,
        height: 1.2,
      ),
      headlineSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onDarkSurface,
        fontSize: 24,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontWeight: FontWeight.w700,
        color: onDarkSurface,
        fontSize: 22,
        height: 1.3,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onDarkSurface,
        fontSize: 16,
        height: 1.4,
      ),
      titleSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        color: onDarkSurface,
        fontSize: 14,
        height: 1.4,
      ),
      bodyLarge: const TextStyle(
        color: onDarkSurface,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        color: onDarkSurface,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: const TextStyle(
        color: onDarkSurfaceVariant,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      iconTheme: IconThemeData(color: onDarkSurface),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onDarkSurface,
        height: 1.2,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryVariant,
        foregroundColor: onDarkSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryVariant,
        side: BorderSide(color: primaryVariant.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: onDarkSurfaceVariant.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryVariant, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(color: onDarkSurfaceVariant),
      floatingLabelStyle: const TextStyle(color: primaryVariant),
      hintStyle: TextStyle(color: onDarkSurfaceVariant.withOpacity(0.6)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
        side: BorderSide(color: onDarkSurfaceVariant.withOpacity(0.08), width: 1),
      ),
      color: darkSurface,
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    dividerTheme: DividerThemeData(
      color: onDarkSurfaceVariant.withOpacity(0.12),
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return primaryVariant;
          }
          return onDarkSurfaceVariant;
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return primaryVariant.withOpacity(0.3);
          }
          return onDarkSurfaceVariant.withOpacity(0.2);
        },
      ),
    ),
    shadowColor: Colors.black.withOpacity(0.1),
  );
}