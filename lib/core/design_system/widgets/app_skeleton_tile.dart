import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_loading_shimmer.dart';

/// Placeholder matching the app's list cards without implying real content.
class AppSkeletonTile extends StatelessWidget {
  const AppSkeletonTile({
    super.key,
    this.showSubtitle = true,
    this.trailingWidth = 24,
    this.avatarSize = 48,
    this.animate = true,
  });

  final bool showSubtitle;
  final double trailingWidth;
  final double avatarSize;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
    final placeholder = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppBorders.borderRadiusL,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bar(.8, 14),
                if (showSubtitle) ...[const SizedBox(height: 8), bar(.5, 10)],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: trailingWidth,
            height: 12,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
    return animate ? AppLoadingShimmer(child: placeholder) : placeholder;
  }
}
