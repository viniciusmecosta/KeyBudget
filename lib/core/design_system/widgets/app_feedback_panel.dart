import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/theme/app_semantic_colors.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';

enum AppFeedbackType { empty, error, warning, info }

class AppFeedbackPanel extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final AppFeedbackType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppFeedbackPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.type = AppFeedbackType.empty,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark()
            : AppSemanticColors.light());

    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case AppFeedbackType.empty:
        iconColor = theme.colorScheme.onSurfaceVariant;
        defaultIcon = Icons.inbox_outlined;
        break;
      case AppFeedbackType.error:
        iconColor = theme.colorScheme.error;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case AppFeedbackType.warning:
        iconColor = semantic.warning;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case AppFeedbackType.info:
        iconColor = semantic.info;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((255 * 0.1).round()),
                borderRadius: AppBorders.borderRadiusCircular,
              ),
              child: Icon(icon ?? defaultIcon, size: 40, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: type == AppFeedbackType.error
                    ? AppButtonVariant.destructive
                    : AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
