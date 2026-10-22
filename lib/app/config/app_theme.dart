import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/colors/app_colors.dart';
import 'package:key_budget/core/design_system/colors/app_contrast.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/theme/app_semantic_colors.dart';
import 'package:key_budget/core/design_system/typography/app_typography.dart';

class AppTheme {
  static const double spaceXS = AppSpacing.xxs;
  static const double spaceS = AppSpacing.xs;
  static const double spaceM = AppSpacing.md;
  static const double spaceL = AppSpacing.lg;
  static const double spaceXL = AppSpacing.xl;
  static const double spaceXXL = AppSpacing.xxl;

  static const double defaultPadding = AppSpacing.md;
  static const double cardPadding = AppSpacing.lg;
  static const double sectionPadding = AppSpacing.xl;

  static const double radiusS = AppBorders.radiusS;
  static const double radiusM = AppBorders.radiusM;
  static const double radiusL = AppBorders.radiusL;
  static const double radiusXL = AppBorders.radiusXL;
  static const double radiusXXL = AppBorders.radiusXXL;

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;

  static const Color background = AppColors.backgroundLight;
  static const Color surface = AppColors.surfaceLight;
  static const Color surfaceContainerHighest =
      AppColors.surfaceContainerHighestLight;
  static const Color onSurface = AppColors.onSurfaceLight;
  static const Color onSurfaceVariant = AppColors.onSurfaceVariantLight;

  static const Color darkBackground = AppColors.backgroundDark;
  static const Color darkSurface = AppColors.surfaceDark;
  static const Color darkSurfaceContainerHighest =
      AppColors.surfaceContainerHighestDark;
  static const Color onDarkSurface = AppColors.onSurfaceDark;
  static const Color onDarkSurfaceVariant = AppColors.onSurfaceVariantDark;

  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color info = AppColors.info;

  static final List<Color> chartColors = AppColors.chartColors;

  static ThemeData getTheme({required bool isDark, int? colorValue}) {
    return _buildTheme(isDark: isDark, colorValue: colorValue);
  }

  static ThemeData get lightTheme => _buildTheme(isDark: false);

  static ThemeData get darkTheme => _buildTheme(isDark: true);

  static Color effectivePrimary({required bool isDark, int? colorValue}) {
    final chosen = colorValue == null
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : Color(colorValue);
    return AppContrast.accentOnSurface(
      chosen,
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      isDark: isDark,
    );
  }

  static ThemeData _buildTheme({required bool isDark, int? colorValue}) {
    final textTheme = AppTypography.getTextTheme(isDark: isDark);

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final primaryColor = effectivePrimary(
      isDark: isDark,
      colorValue: colorValue,
    );
    final onPrimaryColor = AppContrast.foregroundOn(primaryColor);
    final filledPrimaryColor = AppContrast.primaryWithWhiteText(primaryColor);
    final onSurfaceColor = isDark
        ? AppColors.onSurfaceDark
        : AppColors.onSurfaceLight;
    final onSurfaceVariantColor = isDark
        ? AppColors.onSurfaceVariantDark
        : AppColors.onSurfaceVariantLight;
    final surfaceContainerHighestColor = isDark
        ? AppColors.surfaceContainerHighestDark
        : AppColors.surfaceContainerHighestLight;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      extensions: [
        isDark ? AppSemanticColors.dark() : AppSemanticColors.light(),
      ],
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        primaryContainer: Color.alphaBlend(
          primaryColor.withValues(alpha: 0.10),
          surfaceColor,
        ),
        onPrimaryContainer: onSurfaceColor,
        secondaryContainer: surfaceContainerHighestColor,
        onSecondaryContainer: onSurfaceColor,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        onTertiary: isDark ? backgroundColor : Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        surfaceContainerHighest: surfaceContainerHighestColor,
        onSurfaceVariant: onSurfaceVariantColor,
        outline: onSurfaceVariantColor.withAlpha((255 * 0.15).round()),
        outlineVariant: onSurfaceVariantColor.withAlpha((255 * 0.05).round()),
        shadow: (isDark ? Colors.black : onSurfaceColor).withAlpha(
          (255 * (isDark ? 0.2 : 0.03)).round(),
        ),
      ),
      textTheme: textTheme,
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
        elevation: 3,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusXL),
        headerBackgroundColor: surfaceContainerHighestColor,
        headerForegroundColor: onSurfaceColor,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: onSurfaceVariantColor),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: primaryColor,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusXL),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusVerticalXL,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.14),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.12)),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurfaceColor),
        titleTextStyle: textTheme.headlineLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: filledPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
          textStyle: textTheme.titleMedium,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: filledPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: filledPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
        elevation: 3,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurfaceColor,
          side: BorderSide(
            color: onSurfaceVariantColor.withAlpha((255 * 0.2).round()),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: AppBorders.borderRadiusM,
          borderSide: BorderSide(
            color: onSurfaceVariantColor.withAlpha((255 * 0.15).round()),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorders.borderRadiusM,
          borderSide: BorderSide(
            color: onSurfaceVariantColor.withAlpha((255 * 0.15).round()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorders.borderRadiusM,
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorders.borderRadiusM,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorders.borderRadiusM,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariantColor,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: primaryColor),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariantColor),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: primaryColor.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusL,
          side: BorderSide(
            color: isDark
                ? onSurfaceColor.withValues(alpha: 0.08)
                : Colors.white,
            width: 1,
          ),
        ),
        color: surfaceColor,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: onSurfaceVariantColor.withAlpha((255 * 0.15).round()),
        thickness: 1,
        space: AppSpacing.md,
      ),
    );
  }
}
