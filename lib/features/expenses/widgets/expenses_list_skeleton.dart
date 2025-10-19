import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';

class ExpensesListSkeleton extends StatelessWidget {
  const ExpensesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerHighlightColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
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
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.spaceS + 2),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
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
