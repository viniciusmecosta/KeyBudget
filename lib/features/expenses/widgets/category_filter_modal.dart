import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class CategoryFilterModal extends StatefulWidget {
  const CategoryFilterModal({super.key});

  @override
  State<CategoryFilterModal> createState() => _CategoryFilterModalState();
}

class _CategoryFilterModalState extends State<CategoryFilterModal> {
  @override
  Widget build(BuildContext context) {
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 48,
            margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
          ),
          Text(
            'Filtrar por Categoria',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: categoryViewModel.categories.map((category) {
                final isSelected =
                    expenseViewModel.selectedCategoryIds.contains(category.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceXS),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.outline.withOpacity(0.1),
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
          const SizedBox(height: AppTheme.spaceL),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                expenseViewModel.clearFilters();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: const Text('Limpar Filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
