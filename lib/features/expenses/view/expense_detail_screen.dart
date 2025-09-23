import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
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
    final theme = Theme.of(context);

    if (_amountController.numberValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('O valor não pode ser zero.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

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
    );

    await Provider.of<ExpenseViewModel>(context, listen: false)
        .updateExpense(userId, updatedExpense);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            const Text('Você tem certeza que deseja excluir esta despesa?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Excluir'),
            onPressed: () async {
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              final userId = authViewModel.currentUser!.id;

              Navigator.of(ctx).pop();

              await Provider.of<ExpenseViewModel>(context, listen: false)
                  .deleteExpense(userId, widget.expense.id!);

              if (mounted) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Despesa' : 'Detalhes da Despesa'),
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
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: !_isEditing,
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
                ),
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
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
