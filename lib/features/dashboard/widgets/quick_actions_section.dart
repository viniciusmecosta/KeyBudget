import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(dashboardViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final navigationViewModel = ref.read(navigationViewModelProvider);

    final user = authViewModel.currentUser;
    final enableIncomes = user?.enableIncomes ?? false;
    final enableSuppliers = user?.enableSuppliers ?? false;

    final actions = <_QuickActionItem>[
      _QuickActionItem(
        title: enableIncomes ? 'Novo lançamento' : 'Nova despesa',
        subtitle: 'Registrar valor',
        icon: Icons.add_circle_outline_rounded,
        color: theme.colorScheme.primary,
        onTap: () => NavigationUtils.push(context, const AddExpenseScreen()),
      ),
      _QuickActionItem(
        title: 'Credenciais',
        subtitle: '${viewModel.credentialCount} salvas',
        icon: Icons.security_rounded,
        color: theme.colorScheme.secondary,
        onTap: () => navigationViewModel.navigateTo(AppDestination.credentials),
      ),
      _QuickActionItem(
        title: 'Análise',
        subtitle: 'Ver relatórios',
        icon: Icons.bar_chart_rounded,
        color: theme.colorScheme.tertiary,
        onTap: () => NavigationUtils.push(context, const AnalysisScreen()),
      ),
      if (enableSuppliers)
        _QuickActionItem(
          title: 'Fornecedores',
          subtitle: 'Gerenciar',
          icon: Icons.store_rounded,
          color: theme.colorScheme.secondary,
          onTap: () => navigationViewModel.navigateTo(AppDestination.suppliers),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 450
            ? 2
            : (actions.length == 4 ? 4 : 3);
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * AppSpacing.md) /
                crossAxisCount;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildQuickActionCard(context, action: action),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required _QuickActionItem action,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: action.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: action.color.withAlpha((255 * 0.12).round()),
                borderRadius: AppBorders.borderRadiusM,
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              action.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
