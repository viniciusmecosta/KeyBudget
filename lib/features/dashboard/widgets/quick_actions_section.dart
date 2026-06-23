import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final navigationViewModel = ref.read(navigationViewModelProvider);

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Credenciais',
            subtitle: '${viewModel.credentialCount} cadastradas',
            icon: Icons.security_rounded,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => navigationViewModel.selectedIndex = 2,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Análise',
            subtitle: 'Ver relatórios',
            icon: Icons.bar_chart_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () {
              NavigationUtils.push(context, const AnalysisScreen());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.12).round()),
              borderRadius: AppBorders.borderRadiusM,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
