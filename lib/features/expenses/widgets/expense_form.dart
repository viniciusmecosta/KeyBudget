import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/app/widgets/date_picker_field.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExpenseForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MoneyMaskedTextController amountController;
  final TextEditingController motivationController;
  final TextEditingController locationController;
  final DateTime selectedDate;
  final ExpenseCategory? selectedCategory;
  final Function(DateTime) onDateChanged;
  final Function(ExpenseCategory?) onCategoryChanged;
  final bool isEditing;
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
  Widget build(BuildContext context) {
    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: 12),
          TextFormField(
            controller: amountController,
            readOnly: !isEditing,
            decoration: const InputDecoration(labelText: 'Valor *'),
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
          const SizedBox(height: AppTheme.spaceM),
          CategoryPickerField(
            label: 'Categoria',
            value: selectedCategory,
            categories: categoryViewModel.categories,
            isEnabled: isEditing,
            onChanged: onCategoryChanged,
            onManageCategories: () async {
              final userId = Provider.of<AuthViewModel>(context, listen: false)
                  .currentUser
                  ?.id;
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              if (userId != null && context.mounted) {
                await Provider.of<CategoryViewModel>(context, listen: false)
                    .fetchCategories(userId);
              }
            },
            validator: (value) =>
                value == null ? 'Selecione uma categoria' : null,
          ),
          const SizedBox(height: AppTheme.spaceM),
          AbsorbPointer(
            absorbing: !isEditing,
            child: CategoryAutocompleteField(
              key: ValueKey('motivation_${selectedCategory?.id}'),
              label: 'Motivação',
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
          const SizedBox(height: AppTheme.spaceM),
          AbsorbPointer(
            absorbing: !isEditing,
            child: CategoryAutocompleteField(
              key: ValueKey('location_${selectedCategory?.id}'),
              label: 'Local',
              controller: locationController,
              textCapitalization: TextCapitalization.sentences,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return expenseViewModel.getUniqueLocationsForCategory(
                    selectedCategory?.id, textEditingValue.text);
              },
              onSelected: (selection) {
                locationController.text = selection;
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          DatePickerField(
            label: 'Data',
            selectedDate: selectedDate,
            isEditing: isEditing,
            onDateSelected: onDateChanged,
          ),
          if (onInstallmentChanged != null) ...[
            const SizedBox(height: AppTheme.spaceM),
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
              const SizedBox(height: AppTheme.spaceS),
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
          if (imagePreviewWidget != null) imagePreviewWidget!,
          if (bottomWidgets != null) ...bottomWidgets!,
        ],
      ),
    );
  }
}
