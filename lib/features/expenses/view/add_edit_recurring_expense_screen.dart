import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/recurring_expense_form.dart';
import 'package:provider/provider.dart';

class AddEditRecurringExpenseScreen extends StatefulWidget {
  final RecurringExpense? expense;

  const AddEditRecurringExpenseScreen({super.key, this.expense});

  @override
  State<AddEditRecurringExpenseScreen> createState() =>
      _AddEditRecurringExpenseScreenState();
}

class _AddEditRecurringExpenseScreenState
    extends State<AddEditRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late MoneyMaskedTextController _amountController;
  late TextEditingController _motivationController;
  late TextEditingController _locationController;
  ExpenseCategory? _selectedCategory;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _dayOfMonth = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: widget.expense?.amount ?? 0,
    );
    _motivationController =
        TextEditingController(text: widget.expense?.motivation);
    _locationController = TextEditingController(text: widget.expense?.location);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<ExpenseViewModel>();
    final userId = context.read<AuthViewModel>().currentUser!.id;

    final recurringExpense = RecurringExpense(
      id: widget.expense?.id,
      amount: _amountController.numberValue,
      categoryId: _selectedCategory?.id,
      motivation: _motivationController.text,
      location: _locationController.text,
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      dayOfMonth: _dayOfMonth,
    );

    try {
      if (widget.expense == null) {
        await viewModel.addRecurringExpense(userId, recurringExpense);
      } else {
        await viewModel.updateRecurringExpense(userId, recurringExpense);
      }
      if (mounted) {
        SnackbarService.showSuccess(context, 'Despesa recorrente salva!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Erro ao salvar despesa.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null
            ? 'Nova Despesa Recorrente'
            : 'Editar Despesa Recorrente'),
      ),
      body: RecurringExpenseForm(
        formKey: _formKey,
        amountController: _amountController,
        motivationController: _motivationController,
        locationController: _locationController,
        onCategoryChanged: (category) =>
            setState(() => _selectedCategory = category),
        onFrequencyChanged: (freq) => setState(() => _frequency = freq),
        onStartDateChanged: (date) => setState(() => _startDate = date),
        onEndDateChanged: (date) => setState(() => _endDate = date),
        onDayOfMonthChanged: (day) => setState(() => _dayOfMonth = day),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: ElevatedButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ),
    );
  }
}
