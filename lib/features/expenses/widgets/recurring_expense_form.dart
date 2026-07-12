import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/app/widgets/date_picker_field.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class RecurringExpenseForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final MoneyMaskedTextController amountController;
  final TextEditingController motivationController;
  final TextEditingController locationController;
  final ValueNotifier<ExpenseCategory?> selectedCategory;
  final ValueNotifier<RecurrenceFrequency> frequency;
  final ValueNotifier<DateTime> startDate;
  final ValueNotifier<DateTime?> endDate;
  final ValueNotifier<int> dayOfMonth;
  final ValueNotifier<int> advanceGenerationCount;

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
    required this.advanceGenerationCount,
  });

  Widget _buildAmountWidget(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.10),
            accentColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Valor da Despesa',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accentColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o valor';
              }
              if (amountController.numberValue <= 0) {
                return 'O valor deve ser maior que zero';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurface, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _buildAmountWidget(context),
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader(context, Icons.info_outline, 'DADOS DA DESPESA'),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<ExpenseCategory?>(
            valueListenable: selectedCategory,
            builder: (context, currentCategory, child) {
              return CategoryPickerField(
                label: 'Categoria',
                prefixIcon: Icons.category_outlined,
                value: currentCategory,
                categories: ref.watch(categoryViewModelProvider).categories,
                onChanged: (category) => selectedCategory.value = category,
                onManageCategories: () {},
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<ExpenseCategory?>(
            valueListenable: selectedCategory,
            builder: (context, currentCategory, child) {
              return CategoryAutocompleteField(
                key: ValueKey('location_recurring_${currentCategory?.id}'),
                label: 'Título',
                prefixIcon: Icons.title_outlined,
                controller: locationController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return ref.read(expenseViewModelProvider).getUniqueLocationsForCategory(
                        currentCategory?.id,
                        textEditingValue.text,
                      );
                },
                onSelected: (selection) {
                  locationController.text = selection;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<ExpenseCategory?>(
            valueListenable: selectedCategory,
            builder: (context, currentCategory, child) {
              return CategoryAutocompleteField(
                key: ValueKey('motivation_recurring_${currentCategory?.id}'),
                label: 'Descrição',
                prefixIcon: Icons.notes_outlined,
                controller: motivationController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return ref.read(expenseViewModelProvider).getUniqueMotivationsForCategory(
                        currentCategory?.id,
                        textEditingValue.text,
                      );
                },
                onSelected: (selection) {
                  motivationController.text = selection;
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader(context, Icons.repeat_outlined, 'RECORRÊNCIA'),
          const SizedBox(height: AppSpacing.sm),
          _buildFrequencySelector(context),
          ValueListenableBuilder<RecurrenceFrequency>(
            valueListenable: frequency,
            builder: (context, value, child) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: value == RecurrenceFrequency.monthly
                    ? Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _buildDayOfMonthSelector(context),
                        ],
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildAdvanceGenerationSelector(context),
          const SizedBox(height: AppSpacing.lg),
          DatePickerField(
            label: 'Data de Início',
            selectedDate: startDate.value,
            isEditing: true,
            onDateSelected: (date) => startDate.value = date,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildEndDateToggle(context),
          ValueListenableBuilder<DateTime?>(
            valueListenable: endDate,
            builder: (context, date, child) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: date != null
                    ? Column(
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          DatePickerField(
                            label: 'Data de Término',
                            selectedDate: date,
                            isEditing: true,
                            onDateSelected: (newDate) => endDate.value = newDate,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    return ValueListenableBuilder<RecurrenceFrequency>(
      valueListenable: frequency,
      builder: (context, currentFrequency, child) {
        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<RecurrenceFrequency>(
            segments: RecurrenceFrequency.values
                .map(
                  (e) => ButtonSegment(
                    value: e,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(e.nameInPortuguese),
                    ),
                  ),
                )
                .toList(),
            selected: {currentFrequency},
            onSelectionChanged: (newSelection) {
              frequency.value = newSelection.first;
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
              selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              visualDensity: VisualDensity.comfortable,
            ),
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
          'Dia do Vencimento',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.md),
        ValueListenableBuilder<int>(
          valueListenable: dayOfMonth,
          builder: (context, selectedDay, child) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(31, (index) => index + 1).map((day) {
                final isSelected = selectedDay == day;
                return InkWell(
                  onTap: () => dayOfMonth.value = day,
                  borderRadius: AppBorders.borderRadiusMD,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: AppBorders.borderRadiusMD,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvanceGenerationSelector(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: advanceGenerationCount,
      builder: (context, count, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gerar antecipadamente',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Cria as próximas recorrências antes da data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: count > 0,
                  onChanged: (value) {
                    advanceGenerationCount.value = value ? 3 : 0;
                  },
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: count > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Manter cadastradas: $count vezes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: count.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          label: count.toString(),
                          onChanged: (value) {
                            advanceGenerationCount.value = value.toInt();
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndDateToggle(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: endDate,
      builder: (context, date, child) {
        return Row(
          children: [
            Expanded(
              child: Text(
                'Data de Término',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              'Opcional',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: date != null,
              onChanged: (value) {
                endDate.value = value ? startDate.value.add(const Duration(days: 365)) : null;
              },
            ),
          ],
        );
      },
    );
  }
}
