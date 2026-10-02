import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_section_header.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
    final recentExpenses = viewModel.getRecentExpenses(enableIncomes);

    if (viewModel.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader(context, ref, 'Atividades Recentes'),
        const SizedBox(height: AppSpacing.md),
        if (recentExpenses.isEmpty)
          _buildEmptyState(context, ref, viewModel, enableIncomes)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentExpenses.length > 5 ? 5 : recentExpenses.length,
            itemBuilder: (context, index) {
              return AppAnimations.listFadeIn(
                ActivityTile(expense: recentExpenses[index], index: index),
                index: index,

                context: context,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    return AppSectionHeader(
      title: title,
      action: TextButton.icon(
        onPressed: () {
          ref
              .read(navigationViewModelProvider)
              .navigateTo(AppDestination.expenses);
        },
        label: const Text('Ver todas'),
        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    DashboardViewModel viewModel,
    bool enableIncomes,
  ) {
    final theme = Theme.of(context);
    final isCompletelyEmpty = viewModel.allExpenses.isEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((255 * 0.12).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompletelyEmpty
                  ? Icons.receipt_long_rounded
                  : Icons.history_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isCompletelyEmpty
                ? 'Nenhuma transação registrada'
                : 'Sem lançamentos neste mês',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCompletelyEmpty
                ? 'Comece adicionando seu primeiro registro para acompanhar suas finanças.'
                : 'Você possui lançamentos em outros períodos. Acesse o histórico completo para visualizar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isCompletelyEmpty)
            AppButton(
              label: enableIncomes
                  ? 'Adicionar lançamento'
                  : 'Adicionar despesa',
              onPressed: () {
                NavigationUtils.push(context, const AddExpenseScreen());
              },
            )
          else
            AppButton(
              label: 'Ver histórico completo',
              variant: AppButtonVariant.outline,
              onPressed: () {
                ref
                    .read(navigationViewModelProvider)
                    .navigateTo(AppDestination.expenses);
              },
            ),
        ],
      ),
    );
  }
}
