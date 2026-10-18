import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              Color.alphaBlend(
                theme.colorScheme.primary.withValues(
                  alpha: dark ? 0.06 : 0.035,
                ),
                theme.colorScheme.surface,
              ),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorders.borderRadiusL,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
