import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_status_badge.dart';
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
  late List<String> _tempCategoryIds;
  late bool? _tempFilterIsIncome;

  @override
  void initState() {
    super.initState();
    final expenseViewModel = ref.read(expenseViewModelProvider);
    _tempCategoryIds = List<String>.from(expenseViewModel.selectedCategoryIds);
    _tempFilterIsIncome = expenseViewModel.filterIsIncome;
  }

  int get _activeCount =>
      _tempCategoryIds.length + (_tempFilterIsIncome != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = ref.watch(categoryViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 48,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha((255 * 0.2).round()),
                  borderRadius: AppBorders.borderRadiusS,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_activeCount > 0)
                  AppStatusBadge(
                    label: '$_activeCount ${_activeCount == 1 ? "selecionado" : "selecionados"}',
                    variant: AppBadgeVariant.info,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (enableIncomes) ...[
              Text(
                'Tipo',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeFilterChip('Todos', null),
                    const SizedBox(width: AppSpacing.sm),
                    _buildTypeFilterChip('Receitas', true),
                    const SizedBox(width: AppSpacing.sm),
                    _buildTypeFilterChip('Despesas', false),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Categorias',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: categoryViewModel.categories.map((category) {
                  final isSelected = _tempCategoryIds.contains(category.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withAlpha(
                              (255 * 0.08).round(),
                            )
                          : Colors.transparent,
                      borderRadius: AppBorders.borderRadiusMD,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withAlpha(
                                (255 * 0.3).round(),
                              )
                            : theme.colorScheme.outline.withAlpha(
                                (255 * 0.1).round(),
                              ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        title: Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (category.id != null) {
                                _tempCategoryIds.add(category.id!);
                              }
                            } else {
                              _tempCategoryIds.remove(category.id);
                            }
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      setState(() {
                        _tempCategoryIds.clear();
                        _tempFilterIsIncome = null;
                      });
                    },
                    variant: AppButtonVariant.outline,
                    label: 'Limpar',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      ref.read(expenseViewModelProvider).setFilters(
                            categories: _tempCategoryIds,
                            type: _tempFilterIsIncome,
                          );
                      Navigator.of(context).pop();
                    },
                    label: _activeCount > 0
                        ? 'Aplicar ($_activeCount)'
                        : 'Aplicar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, bool? typeValue) {
    final theme = Theme.of(context);
    final isSelected = typeValue == _tempFilterIsIncome;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _tempFilterIsIncome = typeValue;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusL,
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : theme.colorScheme.outline.withAlpha((255 * 0.5).round()),
        ),
      ),
    );
  }
}
