import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_category.dart';
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
  late TextEditingController _motivationController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  late ExpenseCategory? _selectedCategory;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _motivationController =
        TextEditingController(text: widget.expense.motivation);
    _locationController = TextEditingController(text: widget.expense.location);
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedExpense = Expense(
      id: widget.expense.id,
      userId: widget.expense.userId,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      date: _selectedDate,
      category: _selectedCategory,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
    );

    Provider.of<ExpenseViewModel>(context, listen: false)
        .updateExpense(updatedExpense)
        .whenComplete(() {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
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
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (value) => setState(() => _selectedCategory = value)
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivationController,
                decoration: const InputDecoration(labelText: 'Motivação'),
                enabled: _isEditing,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Local'),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.0))
                      : const Text('Salvar Alterações'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
