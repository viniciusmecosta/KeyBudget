import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/widgets/app_loading_shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';

class CredentialsListSkeleton extends ConsumerWidget {
  const CredentialsListSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              AppLoadingShimmer(child: _buildSkeletonTile(context)),
          childCount: 7,
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
          CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.surface),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 150,
                  color: theme.colorScheme.surface,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  color: theme.colorScheme.surface,
                ),
              ],
            ),
          ),
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppBorders.borderRadiusS,
            ),
          ),
        ],
      ),
    );
  }
}
