import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color defaultSpinnerColor;
    switch (variant) {
      case AppButtonVariant.primary:
        defaultSpinnerColor = theme.colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        defaultSpinnerColor = theme.colorScheme.onSecondary;
        break;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        defaultSpinnerColor = theme.colorScheme.primary;
        break;
      case AppButtonVariant.destructive:
        defaultSpinnerColor = theme.colorScheme.onError;
        break;
    }

    final spinnerColor = foregroundColor ?? defaultSpinnerColor;

    Widget child = isLoading
        ? SizedBox(
            height: AppSpacing.lg,
            width: AppSpacing.lg,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: backgroundColor ?? theme.colorScheme.primary,
            foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: backgroundColor ?? theme.colorScheme.secondary,
            foregroundColor: foregroundColor ?? theme.colorScheme.onSecondary,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
            side: BorderSide(
              color: theme.colorScheme.outline,
            ),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: foregroundColor ?? theme.colorScheme.primary,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: backgroundColor ?? theme.colorScheme.error,
            foregroundColor: foregroundColor ?? theme.colorScheme.onError,
            shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadiusM),
            elevation: 0,
          ),
          child: child,
        );
        break;
    }

    final semanticButton = Semantics(
      button: true,
      label: label,
      enabled: !isLoading && onPressed != null,
      child: button,
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: semanticButton)
        : semanticButton;
  }
}
