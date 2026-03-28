import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/expense_form.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
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
    _selectedCategory = Provider.of<CategoryViewModel>(context, listen: false)
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

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
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

    await Provider.of<ExpenseViewModel>(context, listen: false)
        .updateExpense(userId, updatedExpense);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  void _deleteExpense() {
    final hasInstallments = widget.expense.installmentGroupId != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(hasInstallments
            ? 'Esta despesa faz parte de um parcelamento. Deseja excluir apenas esta parcela ou todas as parcelas associadas?'
            : 'Você tem certeza que deseja excluir esta despesa?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          if (hasInstallments)
            TextButton(
              child: const Text('Excluir Todas'),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);
                final userId = authViewModel.currentUser!.id;

                await Provider.of<ExpenseViewModel>(context, listen: false)
                    .deleteInstallmentGroup(
                        userId, widget.expense.installmentGroupId!);

                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
            ),
          TextButton(
            child: Text(hasInstallments ? 'Excluir Apenas Esta' : 'Excluir'),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.of(ctx).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final userId = authViewModel.currentUser!.id;

              await Provider.of<ExpenseViewModel>(context, listen: false)
                  .deleteExpense(userId, widget.expense.id!);

              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final related = widget.expense.installmentGroupId != null
        ? Provider.of<ExpenseViewModel>(context)
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
