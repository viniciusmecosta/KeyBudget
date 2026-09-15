
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money_parser.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

import '../widgets/expense_form.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );
  final _motivationController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;
  bool _isSaving = false;
  bool _isInstallment = false;
  int _installmentsValue = 2;
  bool _startNextMonth = false;
  bool _isIncome = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final money = MoneyParser.fromMaskedText(_amountController.text);
    if (money.isZero) {
      SnackbarService.showError(context, 'O valor não pode ser zero.');
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    final expenseViewModel = ref.read(expenseViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider);
    final navigator = Navigator.of(context);
    final scaffoldContext = context;
    final userId = authViewModel.currentUser!.id;
    final newExpense = Expense.withMoney(
      money: money,
      date: _selectedDate,
      categoryId: _selectedCategory?.id,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      isIncome: _isIncome,
    );

    if (!_isIncome && _isInstallment) {
      final result = await expenseViewModel.addInstallmentExpenses(
        userId,
        newExpense,
        _installmentsValue,
        _startNextMonth,
      );
      if (result.status == OperationStatus.failed) {
        if (!scaffoldContext.mounted) return;
        setState(() => _isSaving = false);
        SnackbarService.showError(
          scaffoldContext,
          result.safeError ?? 'Erro ao gerar parcelas.',
        );
        return;
      }
    } else {
      await expenseViewModel.addExpense(userId, newExpense);
    }

    if (!scaffoldContext.mounted) return;
    setState(() => _isSaving = false);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Você tem alterações não salvas. Deseja sair sem salvar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isIncome ? 'Adicionar Receita' : 'Adicionar Despesa'),
        ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              if (enableIncomes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isIncome) {
                                setState(() {
                                  _isIncome = false;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isIncome
                                    ? theme.colorScheme.error
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_circle_down_rounded,
                                    color: !_isIncome
                                        ? theme.colorScheme.onError
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Despesa',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: !_isIncome
                                          ? theme.colorScheme.onError
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      fontWeight: !_isIncome
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isIncome) {
                                setState(() {
                                  _isIncome = true;
                                  _selectedCategory = null;
                                  _isInstallment = false;
                                  _installmentsValue = 2;
                                  _startNextMonth = false;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isIncome
                                    ? Colors.green[700]!
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_circle_up_rounded,
                                    color: _isIncome
                                        ? Colors.white
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Receita',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: _isIncome
                                          ? Colors.white
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      fontWeight: _isIncome
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ExpenseForm(
                  formKey: _formKey,
                  amountController: _amountController,
                  motivationController: _motivationController,
                  locationController: _locationController,
                  selectedDate: _selectedDate,
                  selectedCategory: _selectedCategory,
                  onChanged: () {
                    if (!_hasUnsavedChanges) {
                      setState(() => _hasUnsavedChanges = true);
                    }
                  },
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  onCategoryChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  isEditing: true,
                  isIncome: _isIncome,
                  isInstallment: _isIncome ? false : _isInstallment,
                  onInstallmentChanged: _isIncome
                      ? null
                      : (val) => setState(() => _isInstallment = val),
                  installmentsValue: _installmentsValue,
                  onInstallmentsValueChanged: _isIncome
                      ? null
                      : (val) => setState(() => _installmentsValue = val),
                  startNextMonth: _startNextMonth,
                  onStartNextMonthChanged: _isIncome
                      ? null
                      : (val) => setState(() => _startNextMonth = val),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isIncome ? 'Salvar Receita' : 'Salvar Despesa',
                  onPressed: _submit,
                  isLoading: _isSaving,
                  backgroundColor: _isIncome ? Colors.green[700] : null,
                  foregroundColor: _isIncome ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
