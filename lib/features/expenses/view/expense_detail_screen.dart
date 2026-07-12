import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

import '../widgets/expense_form.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late MoneyMaskedTextController _amountController;
  late TextEditingController _motivationController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  ExpenseCategory? _selectedCategory;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: widget.expense.amount,
    );
    _motivationController = TextEditingController(
      text: widget.expense.motivation,
    );
    _locationController = TextEditingController(text: widget.expense.location);
    _selectedDate = widget.expense.date;
    _selectedCategory = ref
        .read(categoryViewModelProvider)
        .getCategoryById(widget.expense.categoryId);
    _isIncome = widget.expense.isIncome ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_amountController.numberValue == 0) {
      SnackbarService.showError(context, 'O valor não pode ser zero.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser!.id;

    final updatedExpense = Expense(
      id: widget.expense.id,
      amount: _amountController.numberValue,
      date: _selectedDate,
      categoryId: _selectedCategory?.id,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      installmentGroupId: widget.expense.installmentGroupId,
      currentInstallment: widget.expense.currentInstallment,
      totalInstallments: widget.expense.totalInstallments,
      isIncome: _isIncome,
    );

    await ref
        .read(expenseViewModelProvider)
        .updateExpense(userId, updatedExpense);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  void _deleteExpense() {
    final hasInstallments = widget.expense.installmentGroupId != null;

    if (hasInstallments) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusVerticalL,
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Opções de Exclusão',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Esta despesa faz parte de um parcelamento.'),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Excluir Apenas Esta Parcela'),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelete(deleteGroup: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Excluir Todas as Parcelas'),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelete(deleteGroup: true);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _executeDelete(deleteGroup: false);
    }
  }

  void _executeDelete({required bool deleteGroup}) async {
    HapticFeedback.mediumImpact();
    setState(() => _isDeleting = true);

    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser!.id;
    final expenseViewModel = ref.read(expenseViewModelProvider);

    final deletedExpense = widget.expense;
    final currentContext = context;

    if (deleteGroup && deletedExpense.installmentGroupId != null) {
      await expenseViewModel.deleteInstallmentGroup(
        userId,
        deletedExpense.installmentGroupId!,
      );
      if (currentContext.mounted) {
        SnackbarService.showSuccess(
          currentContext,
          'Parcelamento excluído com sucesso!',
        );
        Navigator.of(currentContext).pop();
      }
    } else {
      await expenseViewModel.deleteExpense(userId, deletedExpense.id!);
      if (currentContext.mounted) {
        SnackbarService.showUndoSnackbar(
          currentContext,
          message: _isIncome ? 'Receita excluída.' : 'Despesa excluída.',
          onUndo: () async {
            await expenseViewModel.restoreExpense(userId, deletedExpense);
          },
        );
        Navigator.of(currentContext).pop();
      }
    }

    if (mounted) {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final related = widget.expense.installmentGroupId != null
        ? ref
              .watch(expenseViewModelProvider)
              .getRelatedInstallments(widget.expense.installmentGroupId!)
        : <Expense>[];

    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? (_isIncome ? 'Editar Receita' : 'Editar Despesa')
              : (_locationController.text.isNotEmpty
                    ? _locationController.text
                    : (_isIncome
                          ? 'Detalhes da Receita'
                          : 'Detalhes da Despesa')),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    tooltip: 'Excluir',
                    onPressed: _deleteExpense,
                  ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Salvar',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              if (_isEditing && enableIncomes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _isIncome
                            ? Colors.greenAccent[400]
                            : Theme.of(context).colorScheme.error,
                        selectedForegroundColor: Colors.white,
                      ),
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Despesa'),
                          icon: Icon(Icons.arrow_circle_down_rounded),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Receita'),
                          icon: Icon(Icons.monetization_on_rounded),
                        ),
                      ],
                      selected: {_isIncome},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isIncome = newSelection.first;
                          if (_isIncome) {
                            _selectedCategory = null;
                          }
                        });
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
                  isEditing: _isEditing,
                  isIncome: _isIncome,
                  bottomWidgets: related.isEmpty
                      ? null
                      : [
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Parcelas Relacionadas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...related.map((e) {
                            final isCurrent = e.id == widget.expense.id;
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (!isCurrent) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ExpenseDetailScreen(expense: e),
                                      ),
                                    );
                                  }
                                },
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: isCurrent ? 2 : 0,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: isCurrent
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      e.motivation ??
                                          'Parcela ${e.currentInstallment}/${e.totalInstallments}',
                                    ),
                                    subtitle: Text(
                                      DateFormat('dd/MM/yyyy').format(e.date),
                                    ),
                                    trailing: Text(
                                      'R\$ ${e.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: _saveChanges,
                    isLoading: _isSaving,
                    label: 'Salvar Alterações',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
