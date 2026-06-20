import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            height: AppSpacing.lg,
            width: AppSpacing.lg,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
        break;
      case AppButtonVariant.secondary:
        final theme = Theme.of(context);
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
        break;
      case AppButtonVariant.ghost:
        button = TextButton(onPressed: isLoading ? null : onPressed, child: child);
        break;
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
