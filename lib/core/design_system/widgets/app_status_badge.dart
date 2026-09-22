import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/theme/app_semantic_colors.dart';

enum AppBadgeVariant { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark()
            : AppSemanticColors.light());

    Color backgroundColor;
    Color foregroundColor;

    switch (variant) {
      case AppBadgeVariant.success:
        backgroundColor = semantic.successContainer;
        foregroundColor = semantic.onSuccessContainer;
        break;
      case AppBadgeVariant.warning:
        backgroundColor = semantic.warningContainer;
        foregroundColor = semantic.onWarningContainer;
        break;
      case AppBadgeVariant.error:
        backgroundColor = theme.colorScheme.errorContainer;
        foregroundColor = theme.colorScheme.onErrorContainer;
        break;
      case AppBadgeVariant.info:
        backgroundColor = semantic.infoContainer;
        foregroundColor = semantic.onInfoContainer;
        break;
      case AppBadgeVariant.neutral:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppBorders.borderRadiusS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
