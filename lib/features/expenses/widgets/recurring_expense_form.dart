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
  final ValueNotifier<ExpenseCategory?> selectedCategory;
  final ValueNotifier<RecurrenceFrequency> frequency;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<DateTime?> endDate;
  final ValueNotifier<int> dayOfMonth;

  const RecurringExpenseForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.motivationController,
    required this.locationController,
    required this.selectedCategory,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.dayOfMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Valor *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => amountController.numberValue <= 0
                        ? 'Valor inválido'
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  CategoryPickerField(
                    label: 'Categoria',
                    value: selectedCategory.value,
                    categories: context.watch<CategoryViewModel>().categories,
                    onChanged: (category) => selectedCategory.value = category,
                    onManageCategories: () {},
                    validator: (v) => v == null ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  TextFormField(
                    controller: motivationController,
                    decoration: const InputDecoration(labelText: 'Motivação'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Local'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recorrência', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spaceL),
                  _buildFrequencySelector(),
                  const SizedBox(height: AppTheme.spaceM),
                  ValueListenableBuilder<RecurrenceFrequency>(
                    valueListenable: frequency,
                    builder: (context, value, child) {
                      if (value == RecurrenceFrequency.monthly) {
                        return _buildDayOfMonthSelector(context);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  DatePickerField(
                    label: 'Data de Início',
                    selectedDate: startDate.value,
                    isEditing: true,
                    onDateSelected: (date) => startDate.value = date,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return ValueListenableBuilder<RecurrenceFrequency>(
      valueListenable: frequency,
      builder: (context, currentFrequency, child) {
        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<RecurrenceFrequency>(
            segments: RecurrenceFrequency.values
                .map((e) => ButtonSegment(
                      value: e,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(e.nameInPortuguese),
                      ),
                    ))
                .toList(),
            selected: {currentFrequency},
            onSelectionChanged: (newSelection) {
              frequency.value = newSelection.first;
            },
          ),
        );
      },
    );
  }

  Widget _buildDayOfMonthSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dia do Mês',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.spaceS),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 31,
            itemBuilder: (context, index) {
              final day = index + 1;
              return ValueListenableBuilder(
                valueListenable: dayOfMonth,
                builder: (context, selectedDay, child) {
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () => dayOfMonth.value = day,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      margin: const EdgeInsets.only(right: AppTheme.spaceS),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withAlpha(50),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
