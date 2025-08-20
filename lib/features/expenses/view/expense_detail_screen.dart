import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _motivationController;
  late DateTime _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _categoryController = TextEditingController(text: widget.expense.category);
    _motivationController =
        TextEditingController(text: widget.expense.motivation);
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final updatedExpense = Expense(
      id: widget.expense.id,
      userId: widget.expense.userId,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category:
          _categoryController.text.isNotEmpty ? _categoryController.text : null,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
    );

    Provider.of<ExpenseViewModel>(context, listen: false)
        .updateExpense(updatedExpense)
        .then((_) {
      if (mounted) Navigator.of(context).pop();
    });
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
            onPressed: () {
              Provider.of<ExpenseViewModel>(context, listen: false)
                  .deleteExpense(widget.expense.id!, widget.expense.userId)
                  .then((_) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                }
              });
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
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Valor *'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: _isEditing,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivationController,
                decoration: const InputDecoration(labelText: 'Motivação'),
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
