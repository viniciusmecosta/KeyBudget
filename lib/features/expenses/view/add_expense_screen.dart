import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
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
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = ref.read(authViewModelProvider).currentUser?.id;
      final categories = ref.read(categoryViewModelProvider);
      if (userId != null &&
          categories.categories.isEmpty &&
          !categories.isLoading) {
        categories.fetchCategories(userId);
      }
    });
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
    if (_isSaving) return;
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

    try {
      if (!_isIncome && _isInstallment) {
        final result = await expenseViewModel.addInstallmentExpenses(
          userId,
          newExpense,
          _installmentsValue,
          _startNextMonth,
        );
        if (!result.isSuccess) {
          if (scaffoldContext.mounted) {
            SnackbarService.showError(
              scaffoldContext,
              result.safeError ??
                  result.message ??
                  'Não foi possível gerar as parcelas.',
            );
          }
          return;
        }
      } else {
        await expenseViewModel.addExpense(userId, newExpense);
      }

      if (!scaffoldContext.mounted) return;
      _hasUnsavedChanges = false;
      navigator.pop();
    } catch (_) {
      if (scaffoldContext.mounted) {
        SnackbarService.showError(
          scaffoldContext,
          'Não foi possível salvar o lançamento. Confira sua conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            content: const Text(
              'Você tem alterações não salvas. Deseja sair sem salvar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) {
            setState(() => _hasUnsavedChanges = false);
            Navigator.of(context).pop(result);
          }
        }
      },
      child: AppPageScaffold(
        maxContentWidth: 760,
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
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon:
                                MediaQuery.textScalerOf(context).scale(14) <= 18
                                ? const Icon(Icons.arrow_circle_down_rounded)
                                : null,
                            label: const Text('Despesa'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon:
                                MediaQuery.textScalerOf(context).scale(14) <= 18
                                ? const Icon(Icons.arrow_circle_up_rounded)
                                : null,
                            label: const Text('Receita'),
                          ),
                        ],
                        selected: {_isIncome},
                        onSelectionChanged: (selection) {
                          setState(() => _isIncome = selection.single);
                        },
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
                        _hasUnsavedChanges = true;
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                        _hasUnsavedChanges = true;
                      });
                    },
                    isEditing: true,
                    isIncome: _isIncome,
                    isInstallment: _isIncome ? false : _isInstallment,
                    onInstallmentChanged: _isIncome
                        ? null
                        : (val) => setState(() {
                            _isInstallment = val;
                            _hasUnsavedChanges = true;
                          }),
                    installmentsValue: _installmentsValue,
                    onInstallmentsValueChanged: _isIncome
                        ? null
                        : (val) => setState(() {
                            _installmentsValue = val;
                            _hasUnsavedChanges = true;
                          }),
                    startNextMonth: _startNextMonth,
                    onStartNextMonthChanged: _isIncome
                        ? null
                        : (val) => setState(() {
                            _startNextMonth = val;
                            _hasUnsavedChanges = true;
                          }),
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

          context: context,
        ),
      ),
    );
  }
}
