import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final recentExpenses = viewModel.recentExpenses;

    if (viewModel.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader(context, ref, 'Atividades Recentes'),
        const SizedBox(height: AppSpacing.md),
        if (recentExpenses.isEmpty)
          _buildEmptyState(context, ref)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentExpenses.length > 5 ? 5 : recentExpenses.length,
            itemBuilder: (context, index) {
              return AppAnimations.listFadeIn(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ActivityTile(
                    expense: recentExpenses[index],
                    index: index,
                  ),
                ),
                index: index,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, WidgetRef ref, String title) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
        TextButton(
          onPressed: () {
            ref.read(navigationViewModelProvider).selectedIndex = 1;
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todas',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: theme.colorScheme.primary.withAlpha((255 * 0.7).round()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nenhuma atividade recente',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Suas transações aparecerão aqui assim que forem registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
