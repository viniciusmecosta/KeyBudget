import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_loading_shimmer.dart';
import 'package:passfin/core/design_system/widgets/app_skeleton_tile.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';

class DashboardSkeleton extends ConsumerWidget {
  const DashboardSkeleton({
    super.key,
    this.enableIncomesOverride,
    this.layout = const DashboardLayout(),
  });

  final bool? enableIncomesOverride;
  final DashboardLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final enableIncomes =
        enableIncomesOverride ??
        (ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false);
    final integrated =
        layout.integratedSummary && layout.cards.contains('balance');
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    Widget card(String id) {
      if (id == 'recent') {
        return Column(
          key: const ValueKey('skeleton_recent'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(150, 16),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < 3; i++)
              const AppSkeletonTile(trailingWidth: 56, animate: false),
          ],
        );
      }
      if (id == 'quick_actions') {
        final count = layout.actions.length.clamp(0, 4);
        if (count == 0) return const SizedBox.shrink();
        return Container(
          key: const ValueKey('skeleton_quick_actions'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppBorders.borderRadiusL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(130, 14),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: bar(double.infinity, 44)),
                  ],
                ],
              ),
            ],
          ),
        );
      }
      final isBalance = id == 'balance';
      return Container(
        key: ValueKey('skeleton_$id'),
        height: isBalance
            ? (enableIncomes ? 180 : 150)
            : layout.sizeFor(id).chartHeight + 80,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: integrated && isBalance
              ? AppBorders.borderRadiusVerticalXL
              : AppBorders.borderRadiusL,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(130, 14),
            const SizedBox(height: AppSpacing.md),
            bar(isBalance ? 180 : 90, isBalance ? 28 : 12),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: AppBorders.borderRadiusM,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ids = [
      if (integrated) 'balance',
      ...layout.cards.where((id) => !integrated || id != 'balance'),
    ];
    return Semantics(
      label: 'Carregando painel',
      child: ExcludeSemantics(
        child: AppLoadingShimmer(
          child: AbsorbPointer(
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
                  sliver: SliverList.builder(
                    itemCount: ids.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: card(ids[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
