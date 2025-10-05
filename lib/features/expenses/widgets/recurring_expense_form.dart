import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
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
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Valor'),
            keyboardType: TextInputType.number,
          ),
          CategoryPickerField(
            label: 'Categoria',
            categories: context.watch<CategoryViewModel>().categories,
            onChanged: onCategoryChanged,
            onManageCategories: () {},
          ),
          TextFormField(
            controller: motivationController,
            decoration: const InputDecoration(labelText: 'Motivação'),
          ),
          TextFormField(
            controller: locationController,
            decoration: const InputDecoration(labelText: 'Local'),
          ),
          DropdownButtonFormField<RecurrenceFrequency>(
            value: RecurrenceFrequency.monthly,
            items: RecurrenceFrequency.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (val) {
              if (val != null) onFrequencyChanged(val);
            },
            decoration: const InputDecoration(labelText: 'Frequência'),
          ),
          ListTile(
            title: const Text('Data de Início'),
            subtitle: Text(DateFormat.yMd().format(DateTime.now())),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) onStartDateChanged(date);
            },
          ),
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
