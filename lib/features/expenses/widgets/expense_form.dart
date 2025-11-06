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
          TextFormField(
            controller: amountController,
            readOnly: !isEditing,
            style: isEditing
                ? null
                : theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurface),
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
          CategoryAutocompleteField(
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
          const SizedBox(height: AppTheme.spaceM),
          CategoryAutocompleteField(
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
          const SizedBox(height: AppTheme.spaceM),
          DatePickerField(
            label: 'Data',
            selectedDate: selectedDate,
            isEditing: isEditing,
            onDateSelected: onDateChanged,
          ),
          if (imagePreviewWidget != null) imagePreviewWidget!,
        ],
      ),
    );
  }
}
