import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
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

  @override
  void initState() {
    super.initState();
    _amountController = MoneyMaskedTextController(
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ ',
        initialValue: widget.expense.amount);
    _motivationController =
        TextEditingController(text: widget.expense.motivation);
    _locationController = TextEditingController(text: widget.expense.location);
    _selectedDate = widget.expense.date;
    _selectedCategory = ref
        .read(categoryViewModelProvider)
        .getCategoryById(widget.expense.categoryId);
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
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
      installmentGroupId: widget.expense.installmentGroupId,
      currentInstallment: widget.expense.currentInstallment,
      totalInstallments: widget.expense.totalInstallments,
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
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Opções de Exclusão',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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

    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser!.id;
    final expenseViewModel = ref.read(expenseViewModelProvider);

    final deletedExpense = widget.expense;
    final currentContext = context;

    if (deleteGroup && deletedExpense.installmentGroupId != null) {
      await expenseViewModel.deleteInstallmentGroup(
          userId, deletedExpense.installmentGroupId!);
      if (currentContext.mounted) {
        SnackbarService.showSuccess(
            currentContext, 'Parcelamento excluído com sucesso!');
        Navigator.of(currentContext).pop();
      }
    } else {
      await expenseViewModel.deleteExpense(userId, deletedExpense.id!);
      if (currentContext.mounted) {
        SnackbarService.showSuccess(
          currentContext,
          'Despesa excluída.',
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Colors.white,
            onPressed: () async {
              await expenseViewModel.restoreExpense(userId, deletedExpense);
            },
          ),
        );
        Navigator.of(currentContext).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final related = widget.expense.installmentGroupId != null
        ? ref
            .watch(expenseViewModelProvider)
            .getRelatedInstallments(widget.expense.installmentGroupId!)
        : <Expense>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Editar Despesa'
            : (_locationController.text.isNotEmpty
                ? _locationController.text
                : 'Detalhes da Despesa')),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteExpense,
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
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
                bottomWidgets: related.isEmpty
                    ? null
                    : [
                        const SizedBox(height: 24),
                        Text('Parcelas Relacionadas',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...related.map((e) {
                          final isCurrent = e.id == widget.expense.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
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
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).dividerColor,
                                    width: isCurrent ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  title: Text(e.motivation ??
                                      'Parcela ${e.currentInstallment}/${e.totalInstallments}'),
                                  subtitle: Text(
                                      DateFormat('dd/MM/yyyy').format(e.date)),
                                  trailing: Text(
                                      'R\$ ${e.amount.toStringAsFixed(2).replaceAll('.', ',')}'),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2.0))
                    : const Text('Salvar Alterações'),
              )
            ]
          ],
        ),
      )),
    );
  }
}
