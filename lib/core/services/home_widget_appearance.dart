import 'package:flutter/material.dart';

import '../design_system/colors/app_colors.dart';
import '../design_system/colors/app_contrast.dart';

/// Both palettes are saved so Android can change brightness without starting
/// Flutter. All colors are opaque and use the same contrast rules as the app.
class HomeWidgetAppearance {
  static Map<String, Object> toMap({int? colorValue, String mode = 'system'}) {
    final seed = Color(
      colorValue ?? AppColors.primary.toARGB32(),
    ).withAlpha(255);
    return {
      'mode': {'light', 'dark', 'system'}.contains(mode) ? mode : 'system',
      'light': _palette(seed, isDark: false),
      'dark': _palette(seed, isDark: true),
    };
  }

  static Map<String, int> _palette(Color seed, {required bool isDark}) {
    final background = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final foreground = AppContrast.foregroundOn(background);
    final secondary = Color.lerp(foreground, background, .24)!;
    final button = AppContrast.accentOnSurface(
      seed,
      background,
      isDark: isDark,
    );
    return {
      'background': background.toARGB32(),
      'foreground': foreground.toARGB32(),
      'secondary': secondary.toARGB32(),
      'button': button.toARGB32(),
      'on_button': AppContrast.foregroundOn(button).toARGB32(),
    };
  }
}
