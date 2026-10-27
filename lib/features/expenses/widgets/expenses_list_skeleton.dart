import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/widgets/app_loading_shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';

class ExpensesListSkeleton extends ConsumerWidget {
  const ExpensesListSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              AppLoadingShimmer(child: _buildSkeletonTile(context)),
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
        borderRadius: AppBorders.borderRadiusL,
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
          Container(height: 16, width: 60, color: theme.colorScheme.surface),
        ],
      ),
    );
  }
}
