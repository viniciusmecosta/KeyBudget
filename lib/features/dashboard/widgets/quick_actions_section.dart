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
  final List<String>? actionIds;

  const QuickActionsSection({super.key, this.actionIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(dashboardViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final navigationViewModel = ref.read(navigationViewModelProvider);

    final user = authViewModel.currentUser;
    final enableIncomes = user?.enableIncomes ?? false;
    final enableSuppliers = user?.enableSuppliers ?? false;

    final availableActions = <String, _QuickActionItem>{
      'expense': _QuickActionItem(
        title: enableIncomes ? 'Novo lançamento' : 'Nova despesa',
        compactTitle: enableIncomes ? 'Lançar' : 'Despesa',
        subtitle: 'Registrar valor',
        icon: Icons.add_circle_outline_rounded,
        color: theme.colorScheme.primary,
        onTap: () => NavigationUtils.push(context, const AddExpenseScreen()),
      ),
      'credentials': _QuickActionItem(
        title: 'Credenciais',
        compactTitle: 'Cofre',
        subtitle: '${viewModel.credentialCount} salvas',
        icon: Icons.security_rounded,
        color: theme.colorScheme.secondary,
        onTap: () => navigationViewModel.navigateTo(AppDestination.credentials),
      ),
      'analysis': _QuickActionItem(
        title: 'Análise',
        compactTitle: 'Análise',
        subtitle: 'Ver relatórios',
        icon: Icons.bar_chart_rounded,
        color: theme.colorScheme.tertiary,
        onTap: () => NavigationUtils.push(context, const AnalysisScreen()),
      ),
      if (enableSuppliers)
        'suppliers': _QuickActionItem(
          title: 'Fornecedores',
          compactTitle: 'Fornecedores',
          subtitle: 'Gerenciar',
          icon: Icons.store_rounded,
          color: theme.colorScheme.secondary,
          onTap: () => navigationViewModel.navigateTo(AppDestination.suppliers),
        ),
    };
    final actions = (actionIds ?? availableActions.keys.toList())
        .map((id) => availableActions[id])
        .whereType<_QuickActionItem>()
        .toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = actions.length == 3
            ? 3
            : (constraints.maxWidth < 450 ? 2 : 4);
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * AppSpacing.md) /
            crossAxisCount;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildQuickActionCard(
                context,
                action: action,
                compact: crossAxisCount == 3,
                useCompactLabel:
                    crossAxisCount == 3 && constraints.maxWidth < 390,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required _QuickActionItem action,
    required bool compact,
    required bool useCompactLabel,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.md,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      onTap: action.onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 60 : 80),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
              decoration: BoxDecoration(
                color: action.color.withAlpha((255 * 0.12).round()),
                borderRadius: AppBorders.borderRadiusM,
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
            Text(
              useCompactLabel ? action.compactTitle : action.title,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (!compact)
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
  final String compactTitle;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.compactTitle,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
