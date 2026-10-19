import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';

class AppSurfaces {
  static BoxDecoration panel(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: AppBorders.borderRadiusL,
      border: Border.all(
        color: dark
            ? theme.colorScheme.primary.withValues(alpha: 0.18)
            : Colors.white,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: dark ? 0.06 : 0.035),
            theme.colorScheme.surface,
          ),
        ],
      ),
    );
  }
}
