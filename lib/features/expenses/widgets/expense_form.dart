import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/app/widgets/date_picker_field.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

const _kInstallmentOptions = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 18, 24, 36, 48, 60];

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
  final VoidCallback? onChanged;
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
    this.onChanged,
    this.imagePreviewWidget,
    this.isInstallment = false,
    this.onInstallmentChanged,
    this.installmentsValue = 2,
    this.onInstallmentsValueChanged,
    this.startNextMonth = false,
    this.onStartNextMonthChanged,
    this.bottomWidgets,
  });

  Widget _buildAmountWidget(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isIncome ? Colors.green[700]! : Colors.red;

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
            isIncome ? 'Valor da Receita' : 'Valor da Despesa',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accentColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: amountController,
            readOnly: !isEditing,
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
          if (!isEditing) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Toque em editar para alterar',
              style: theme.textTheme.labelSmall?.copyWith(
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallmentDropdown(BuildContext context) {
    final theme = Theme.of(context);

    final options = List<int>.from(_kInstallmentOptions);
    if (!options.contains(installmentsValue)) {
      options.add(installmentsValue);
      options.sort();
    }

    return AbsorbPointer(
      absorbing: !isEditing,
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        menuMaxHeight: 300,
        initialValue: installmentsValue,
        decoration: InputDecoration(
          labelText: 'Número de Parcelas',
          prefixIcon: const Icon(Icons.credit_card_outlined),
          helperText:
              'Valor por parcela: ${_calcInstallmentAmount(amountController.numberValue, installmentsValue)}',
        ),
        items: options.map((n) {
          return DropdownMenuItem(
            value: n,
            child: Text('$n× parcelas', style: theme.textTheme.bodyMedium),
          );
        }).toList(),
        onChanged: isEditing && onInstallmentsValueChanged != null
            ? (v) => onInstallmentsValueChanged!(v!)
            : null,
      ),
    );
  }

  String _calcInstallmentAmount(double total, int count) {
    if (count <= 0) return 'R\$ 0,00';
    final perInstallment = total / count;
    return 'R\$ ${perInstallment.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseViewModel = ref.read(expenseViewModelProvider);
    final categoryViewModel = ref.watch(categoryViewModelProvider);
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      onChanged: onChanged,
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _buildAmountWidget(context),
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader(context, Icons.info_outline, isIncome ? 'DADOS DA RECEITA' : 'DADOS DA DESPESA'),
          const SizedBox(height: AppSpacing.sm),
          if (!isIncome) ...[
            const SizedBox(height: AppSpacing.md),
            CategoryPickerField(
              label: 'Categoria',
              prefixIcon: Icons.category_outlined,
              value: selectedCategory,
              categories: categoryViewModel.categories,
              isEnabled: isEditing,
              onChanged: onCategoryChanged,
              onManageCategories: () async {
                final userId = ref.read(authViewModelProvider).currentUser?.id;
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
                if (userId != null && context.mounted) {
                  await ref.read(categoryViewModelProvider).fetchCategories(userId);
                }
              },
              validator: (value) => value == null ? 'Selecione uma categoria' : null,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AbsorbPointer(
            absorbing: !isEditing,
            child: CategoryAutocompleteField(
              key: ValueKey('location_${isIncome ? "income" : selectedCategory?.id}'),
              label: 'Título *',
              prefixIcon: Icons.title_outlined,
              controller: locationController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                if (isIncome) {
                  return expenseViewModel.getUniqueLocationsForIncome(textEditingValue.text);
                } else {
                  return expenseViewModel.getUniqueLocationsForCategory(
                    selectedCategory?.id,
                    textEditingValue.text,
                  );
                }
              },
              onSelected: (selection) {
                locationController.text = selection;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o título da ${isIncome ? "receita" : "despesa"}';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AbsorbPointer(
            absorbing: !isEditing,
            child: CategoryAutocompleteField(
              key: ValueKey('motivation_${selectedCategory?.id}'),
              label: 'Descrição',
              prefixIcon: Icons.notes_outlined,
              controller: motivationController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                if (isIncome) {
                  return expenseViewModel.getUniqueMotivationsForIncome(textEditingValue.text);
                } else {
                  return expenseViewModel.getUniqueMotivationsForCategory(
                    selectedCategory?.id,
                    textEditingValue.text,
                  );
                }
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
            _buildSectionHeader(context, Icons.credit_card_outlined, 'PARCELAMENTO'),
            const SizedBox(height: AppSpacing.sm),
            AbsorbPointer(
              absorbing: !isEditing,
              child: SwitchListTile(
                title: const Text('Parcelar Despesa'),
                subtitle: const Text('O valor será dividido em parcelas mensais'),
                secondary: Icon(Icons.credit_card_outlined, color: theme.colorScheme.primary),
                value: isInstallment,
                onChanged: onInstallmentChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isInstallment && onInstallmentsValueChanged != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildInstallmentDropdown(context),
              const SizedBox(height: AppSpacing.sm),
              AbsorbPointer(
                absorbing: !isEditing,
                child: SwitchListTile(
                  title: const Text('Começar no próximo mês'),
                  subtitle: const Text('A primeira parcela será gerada no próximo mês'),
                  secondary: Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                  value: startNextMonth,
                  onChanged: onStartNextMonthChanged,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
          ?imagePreviewWidget,
          ...?bottomWidgets,
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

}

