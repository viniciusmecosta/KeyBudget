import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class DashboardSkeleton extends ConsumerWidget {
  final bool? enableIncomesOverride;

  const DashboardSkeleton({super.key, this.enableIncomesOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerHighlightColor = theme.colorScheme.surface;
    final bool enableIncomes;
    if (enableIncomesOverride != null) {
      enableIncomes = enableIncomesOverride!;
    } else {
      enableIncomes =
          ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false;
    }

    return AbsorbPointer(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBalanceCardSkeleton(context, enableIncomes),
                    const SizedBox(height: AppSpacing.md),
                    _buildContainer(
                      context: context,
                      height: enableIncomes ? 260 : 230,
                      radius: AppBorders.borderRadiusL,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildQuickActionsSkeleton(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildRecentActivitySkeleton(context),
                  ]),
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: shimmerHighlightColor);
  }

  Widget _buildContainer({
    required BuildContext context,
    required double height,
    double? width,
    BorderRadiusGeometry? radius,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: width ?? double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: radius ?? AppBorders.borderRadiusM,
      ),
    );
  }

  Widget _buildBalanceCardSkeleton(BuildContext context, bool enableIncomes) {
    return _buildContainer(
      context: context,
      height: enableIncomes ? 180 : 150,
      radius: AppBorders.borderRadiusXL,
    );
  }

  Widget _buildQuickActionsSkeleton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildContainer(
            context: context,
            height: 140,
            radius: AppBorders.borderRadiusL,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildContainer(
            context: context,
            height: 140,
            radius: AppBorders.borderRadiusL,
          ),
        ),
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
        const SizedBox(height: AppSpacing.md),
        ...List.generate(
          3,
          (index) => _buildContainer(
            context: context,
            height: 70,
            radius: AppBorders.borderRadiusM,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}
