import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:passfin/core/design_system/colors/app_contrast.dart';

void main() {
  test(
    'themed header preserves readable labels and period across custom colors',
    () {
      for (final dark in [false, true]) {
        for (final seed in [
          null,
          0xFF0058D9,
          0xFF15803D,
          0xFFB91C1C,
          0xFFC2410C,
          0xFF0E7490,
          0xFF4338CA,
          0xFF0F766E,
          0xFF9F1239,
          0xFFFFFFFF,
          0xFF000000,
          0xFFFFFF00,
        ]) {
          final accent = AppTheme.effectivePrimary(
            isDark: dark,
            colorValue: seed,
          );
          final background = AppContrast.primaryWithWhiteText(
            accent,
            minimumRatio: 7,
          );
          expect(
            AppContrast.ratio(Colors.white, background),
            greaterThanOrEqualTo(7),
          );
          final caption = Color.alphaBlend(
            Colors.white.withValues(alpha: 0.88),
            background,
          );
          expect(
            AppContrast.ratio(caption, background),
            greaterThanOrEqualTo(4.5),
          );
          final period = Color.alphaBlend(
            Colors.white.withValues(alpha: 0.12),
            background,
          );
          expect(
            AppContrast.ratio(Colors.white, period),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    },
  );
}
