import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_category_model.dart';

class CategoryPickerField extends StatelessWidget {
  final String label;
  final ExpenseCategory? value;
  final List<ExpenseCategory> categories;
  final ValueChanged<ExpenseCategory?> onChanged;
  final VoidCallback onManageCategories;
  final FormFieldValidator<ExpenseCategory>? validator;
  final bool isEnabled;

  const CategoryPickerField({
    super.key,
    required this.label,
    this.value,
    required this.categories,
    required this.onChanged,
    required this.onManageCategories,
    this.validator,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<ExpenseCategory>(
      validator: validator,
      initialValue: value,
      builder: (FormFieldState<ExpenseCategory> state) {
        return InkWell(
          onTap: !isEnabled
              ? null
              : () async {
                  final selected = await _showCategoryPicker(context);
                  if (selected != null) {
                    state.didChange(selected);
                    onChanged(selected);
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
            ),
            isEmpty: value == null,
            child: value == null
                ? const Text('')
                : Row(
                    children: [
                      Icon(value!.icon, size: 24, color: value!.color),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                        value!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isEnabled
                              ? null
                              : theme.textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<ExpenseCategory?> _showCategoryPicker(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecione uma Categoria',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == categories.length) {
                          return ListTile(
                            leading: Icon(Icons.settings_outlined,
                                color: theme.colorScheme.primary),
                            title: Text(
                              'Gerenciar Categorias',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              onManageCategories();
                            },
                          );
                        }
                        final category = categories[index];
                        return ListTile(
                          leading: Icon(category.icon, color: category.color),
                          title: Text(category.name),
                          onTap: () => Navigator.of(context).pop(category),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
