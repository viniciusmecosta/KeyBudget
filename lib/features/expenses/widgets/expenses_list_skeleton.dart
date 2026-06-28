import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

class ExpensesListSkeleton extends ConsumerWidget {
  const ExpensesListSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerHighlightColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSkeletonTile(context)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: shimmerHighlightColor,
              ),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildSkeletonTile(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppBorders.borderRadiusMD,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppBorders.borderRadiusS,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  color: theme.colorScheme.surface,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 80,
                  color: theme.colorScheme.surface,
                ),
              ],
            ),
          ),
          Container(
            height: 16,
            width: 60,
            color: theme.colorScheme.surface,
          ),
        ],
      ),
    );
  }
}
