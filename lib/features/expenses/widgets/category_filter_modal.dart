import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class CategoryFilterModal extends ConsumerStatefulWidget {
  const CategoryFilterModal({super.key});

  @override
  ConsumerState<CategoryFilterModal> createState() =>
      _CategoryFilterModalState();
}

class _CategoryFilterModalState extends ConsumerState<CategoryFilterModal> {
  @override
  Widget build(BuildContext context) {
    final expenseViewModel = ref.watch(expenseViewModelProvider);
    final categoryViewModel = ref.watch(categoryViewModelProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 48,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.2).round()),
              borderRadius: AppBorders.borderRadiusS,
            ),
          ),
          Text(
            'Filtros',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeFilterChip(context, 'Todos', null, expenseViewModel.filterIsIncome),
                  const SizedBox(width: AppSpacing.sm),
                  _buildTypeFilterChip(context, 'Receitas', true, expenseViewModel.filterIsIncome),
                  const SizedBox(width: AppSpacing.sm),
                  _buildTypeFilterChip(context, 'Despesas', false, expenseViewModel.filterIsIncome),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Categorias',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: categoryViewModel.categories.map((category) {
                final isSelected =
                    expenseViewModel.selectedCategoryIds.contains(category.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                            .withAlpha((255 * 0.08).round())
                        : Colors.transparent,
                    borderRadius: AppBorders.borderRadiusMD,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withAlpha((255 * 0.2).round())
                          : theme.colorScheme.outline
                              .withAlpha((255 * 0.1).round()),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      category.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    value: isSelected,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      final currentSelection = List<String>.from(
                          expenseViewModel.selectedCategoryIds);
                      if (value == true) {
                        currentSelection.add(category.id!);
                      } else {
                        currentSelection.remove(category.id);
                      }
                      expenseViewModel.setCategoryFilter(currentSelection);
                      setState(() {});
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: () {
                expenseViewModel.clearFilters();
                Navigator.of(context).pop();
              },
              variant: AppButtonVariant.outline,
              label: 'Limpar Filtros',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(BuildContext context, String label, bool? typeValue, bool? currentValue) {
    final theme = Theme.of(context);
    final expenseViewModel = ref.read(expenseViewModelProvider);
    final isSelected = typeValue == currentValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        expenseViewModel.setTypeFilter(typeValue);
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusL,
        side: BorderSide(
          color: isSelected ? Colors.transparent : theme.colorScheme.outline.withAlpha((255 * 0.5).round()),
        ),
      ),
    );
  }
}
