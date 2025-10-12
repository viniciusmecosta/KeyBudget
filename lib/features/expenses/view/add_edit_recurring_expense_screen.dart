import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
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
  late ValueNotifier<ExpenseCategory?> _selectedCategory;
  late ValueNotifier<RecurrenceFrequency> _frequency;
  late ValueNotifier<DateTime> _startDate;
  late ValueNotifier<DateTime?> _endDate;
  late ValueNotifier<int> _dayOfMonth;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categoryViewModel = context.read<CategoryViewModel>();

    _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: widget.expense?.amount ?? 0,
    );
    _motivationController =
        TextEditingController(text: widget.expense?.motivation);
    _locationController = TextEditingController(text: widget.expense?.location);
    _selectedCategory = ValueNotifier(
        categoryViewModel.getCategoryById(widget.expense?.categoryId));
    _frequency =
        ValueNotifier(widget.expense?.frequency ?? RecurrenceFrequency.monthly);
    _startDate = ValueNotifier(widget.expense?.startDate ?? DateTime.now());
    _endDate = ValueNotifier(widget.expense?.endDate);
    _dayOfMonth =
        ValueNotifier(widget.expense?.dayOfMonth ?? DateTime.now().day);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = context.read<ExpenseViewModel>();
    final userId = context.read<AuthViewModel>().currentUser!.id;

    final recurringExpense = RecurringExpense(
      id: widget.expense?.id,
      amount: _amountController.numberValue,
      categoryId: _selectedCategory.value?.id,
      motivation: _motivationController.text,
      location: _locationController.text,
      frequency: _frequency.value,
      startDate: _startDate.value,
      endDate: _endDate.value,
      dayOfMonth: _dayOfMonth.value,
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
            'Tem certeza que deseja excluir esta despesa recorrente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.expense != null) {
      HapticFeedback.mediumImpact();
      final viewModel = context.read<ExpenseViewModel>();
      final userId = context.read<AuthViewModel>().currentUser!.id;
      try {
        await viewModel.deleteRecurringExpense(userId, widget.expense!.id!);
        if (mounted) {
          SnackbarService.showSuccess(context, 'Despesa recorrente excluída!');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(context, 'Erro ao excluir despesa.');
        }
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
        actions: [
          if (widget.expense != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: RecurringExpenseForm(
                formKey: _formKey,
                amountController: _amountController,
                motivationController: _motivationController,
                locationController: _locationController,
                selectedCategory: _selectedCategory,
                frequency: _frequency,
                startDate: _startDate,
                endDate: _endDate,
                dayOfMonth: _dayOfMonth,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2.0))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
