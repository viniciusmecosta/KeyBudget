import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerHighlightColor = theme.colorScheme.surface;

    return AbsorbPointer(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceM,
              AppTheme.spaceS,
              AppTheme.spaceM,
              AppTheme.spaceL,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildBalanceCardSkeleton(context),
                  const SizedBox(height: AppTheme.spaceL),
                  _buildQuickActionsSkeleton(context),
                  const SizedBox(height: AppTheme.spaceXL),
                  _buildRecentActivitySkeleton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1500.ms,
          color: shimmerHighlightColor,
        );
  }

  Widget _buildContainer(
      {required BuildContext context,
      required double height,
      double? width,
      double radius = AppTheme.radiusM,
      EdgeInsets margin = EdgeInsets.zero}) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: width ?? double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildBalanceCardSkeleton(BuildContext context) {
    return _buildContainer(
      context: context,
      height: 150,
      radius: AppTheme.radiusXL,
    );
  }

  Widget _buildQuickActionsSkeleton(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _buildContainer(
                context: context, height: 140, radius: AppTheme.radiusL)),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
            child: _buildContainer(
                context: context, height: 140, radius: AppTheme.radiusL)),
      ],
    );
  }

  Widget _buildRecentActivitySkeleton(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildContainer(context: context, height: 24, width: 180),
            _buildContainer(context: context, height: 16, width: 80),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        ...List.generate(
          3,
          (index) => _buildContainer(
            context: context,
            height: 70,
            radius: AppTheme.radiusM,
            margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
          ),
        ),
      ],
    );
  }
}
