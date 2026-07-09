import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/app/widgets/date_picker_field.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final MoneyMaskedTextController amountController;
  final TextEditingController motivationController;
  final TextEditingController locationController;
  final DateTime selectedDate;
  final ExpenseCategory? selectedCategory;
  final Function(DateTime) onDateChanged;
  final Function(ExpenseCategory?) onCategoryChanged;
  final bool isEditing;
  final bool isIncome;
  final Widget? imagePreviewWidget;

  final bool isInstallment;
  final Function(bool)? onInstallmentChanged;
  final int installmentsValue;
  final Function(int)? onInstallmentsValueChanged;
  final bool startNextMonth;
  final Function(bool)? onStartNextMonthChanged;
  final List<Widget>? bottomWidgets;

  const ExpenseForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.motivationController,
    required this.locationController,
    required this.selectedDate,
    required this.selectedCategory,
    required this.onDateChanged,
    required this.onCategoryChanged,
    this.isEditing = false,
    this.isIncome = false,
    this.imagePreviewWidget,
    this.isInstallment = false,
    this.onInstallmentChanged,
    this.installmentsValue = 2,
    this.onInstallmentsValueChanged,
    this.startNextMonth = false,
    this.onStartNextMonthChanged,
    this.bottomWidgets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseViewModel = ref.read(expenseViewModelProvider);
    final categoryViewModel = ref.watch(categoryViewModelProvider);
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: amountController,
            label: 'Valor *',
            readOnly: !isEditing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              if (amountController.numberValue <= 0) {
                return 'O valor deve ser maior que zero';
              }
              return null;
            },
          ),
          if (!isIncome) ...[
            const SizedBox(height: AppSpacing.md),
            CategoryPickerField(
              label: 'Categoria',
              value: selectedCategory,
              categories: categoryViewModel.categories,
              isEnabled: isEditing,
              onChanged: onCategoryChanged,
              onManageCategories: () async {
                final userId = ref.read(authViewModelProvider).currentUser?.id;
                await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                if (userId != null && context.mounted) {
                  await ref
                      .read(categoryViewModelProvider)
                      .fetchCategories(userId);
                }
              },
              validator: (value) =>
                  value == null ? 'Selecione uma categoria' : null,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('location_field'),
            label: 'Título *',
            controller: locationController,
            readOnly: !isEditing,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AbsorbPointer(
            absorbing: !isEditing,
            child: CategoryAutocompleteField(
              key: ValueKey('motivation_${selectedCategory?.id}'),
              label: 'Descrição',
              controller: motivationController,
              textCapitalization: TextCapitalization.sentences,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return expenseViewModel.getUniqueMotivationsForCategory(
                    selectedCategory?.id, textEditingValue.text);
              },
              onSelected: (selection) {
                motivationController.text = selection;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DatePickerField(
            label: 'Data',
            selectedDate: selectedDate,
            isEditing: isEditing,
            onDateSelected: onDateChanged,
          ),
          if (onInstallmentChanged != null) ...[
            const SizedBox(height: AppSpacing.md),
            AbsorbPointer(
              absorbing: !isEditing,
              child: SwitchListTile(
                title: const Text('Parcelar Despesa'),
                value: isInstallment,
                onChanged: onInstallmentChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isInstallment && onInstallmentsValueChanged != null) ...[
              AbsorbPointer(
                absorbing: !isEditing,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantidade de Parcelas',
                        style: theme.textTheme.bodyLarge),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: theme.colorScheme.primary),
                          onPressed: installmentsValue > 2
                              ? () => onInstallmentsValueChanged!(
                                  installmentsValue - 1)
                              : null,
                        ),
                        Text('$installmentsValue',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: theme.colorScheme.primary),
                          onPressed: installmentsValue < 120
                              ? () => onInstallmentsValueChanged!(
                                  installmentsValue + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AbsorbPointer(
                absorbing: !isEditing,
                child: SwitchListTile(
                  title: const Text('Começar no próximo mês'),
                  value: startNextMonth,
                  onChanged: onStartNextMonthChanged,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]
          ],
          ?imagePreviewWidget,
          ...?bottomWidgets,
        ],
      ),
    );
  }
}
