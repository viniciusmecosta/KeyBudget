import 'package:passfin/core/design_system/surfaces/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: AppSurfaces.panel(context),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorders.borderRadiusL,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
