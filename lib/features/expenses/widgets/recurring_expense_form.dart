import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/app/widgets/date_picker_field.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:provider/provider.dart';

class RecurringExpenseForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MoneyMaskedTextController amountController;
  final TextEditingController motivationController;
  final TextEditingController locationController;
  final Function(ExpenseCategory?) onCategoryChanged;
  final Function(RecurrenceFrequency) onFrequencyChanged;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(int) onDayOfMonthChanged;

  const RecurringExpenseForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.motivationController,
    required this.locationController,
    required this.onCategoryChanged,
    required this.onFrequencyChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onDayOfMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Valor'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppTheme.spaceM),
          CategoryPickerField(
            label: 'Categoria',
            categories: context.watch<CategoryViewModel>().categories,
            onChanged: onCategoryChanged,
            onManageCategories: () {},
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextFormField(
            controller: motivationController,
            decoration: const InputDecoration(labelText: 'Motivação'),
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextFormField(
            controller: locationController,
            decoration: const InputDecoration(labelText: 'Local'),
          ),
          const SizedBox(height: AppTheme.spaceM),
          DropdownButtonFormField<RecurrenceFrequency>(
            value: RecurrenceFrequency.monthly,
            items: RecurrenceFrequency.values
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e.nameInPortuguese)))
                .toList(),
            onChanged: (val) {
              if (val != null) onFrequencyChanged(val);
            },
            decoration: const InputDecoration(labelText: 'Frequência'),
          ),
          const SizedBox(height: AppTheme.spaceM),
          DatePickerField(
            label: 'Data de Início',
            selectedDate: DateTime.now(),
            isEditing: true,
            onDateSelected: onStartDateChanged,
          ),
          const SizedBox(height: AppTheme.spaceM),
          DropdownButtonFormField<int>(
            value: DateTime.now().day,
            items: List.generate(31, (i) => i + 1)
                .map((day) =>
                    DropdownMenuItem(value: day, child: Text(day.toString())))
                .toList(),
            onChanged: (val) {
              if (val != null) onDayOfMonthChanged(val);
            },
            decoration: const InputDecoration(labelText: 'Dia do Mês'),
          ),
        ],
      ),
    );
  }
}
