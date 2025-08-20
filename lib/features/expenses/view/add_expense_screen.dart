import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _motivationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final newExpense = Expense(
      userId: authViewModel.currentUser!.id!,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category:
          _categoryController.text.isNotEmpty ? _categoryController.text : null,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
    );

    expenseViewModel.addExpense(newExpense).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Despesa salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState?.reset();
      _amountController.clear();
      _categoryController.clear();
      _motivationController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration:
                    const InputDecoration(labelText: 'Valor (ex: 50.99) *'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration:
                    const InputDecoration(labelText: 'Categoria (opcional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivationController,
                decoration:
                    const InputDecoration(labelText: 'Motivação (opcional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Data: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Selecionar Data'),
                  )
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Salvar Despesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
