import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
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
  late MoneyMaskedTextController _amountController;
  late TextEditingController _motivationController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  ExpenseCategory? _selectedCategory;
  bool _isEditing = false;
  bool _isSaving = false;
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final categoryViewModel = Provider.of<CategoryViewModel>(context);

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
                controller: _isEditing
                    ? _amountController
                    : TextEditingController(
                        text: _currencyFormatter.format(widget.expense.amount)),
                decoration: const InputDecoration(labelText: 'Valor *'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: _isEditing,
                validator: (value) {
                  if (_isEditing) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (_amountController.numberValue <= 0) {
                      return 'O valor deve ser maior que zero';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                CategoryPickerField(
                  label: 'Categoria',
                  value: _selectedCategory,
                  categories: categoryViewModel.categories,
                  onChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  onManageCategories: () async {
                    final userId =
                        Provider.of<AuthViewModel>(context, listen: false)
                            .currentUser
                            ?.id;
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CategoriesScreen(),
                    ));
                    if (userId != null && mounted) {
                      await Provider.of<CategoryViewModel>(context,
                              listen: false)
                          .fetchCategories(userId);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Selecione uma categoria' : null,
                )
              else
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    enabled: false,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: _selectedCategory == null
                      ? const Text('Não especificada')
                      : Row(
                          children: [
                            Icon(_selectedCategory!.icon,
                                size: 22, color: _selectedCategory!.color),
                            const SizedBox(width: 12),
                            Text(_selectedCategory!.name),
                          ],
                        ),
                ),
              const SizedBox(height: 16),
              if (_isEditing)
                CategoryAutocompleteField(
                  key: ValueKey('motivation_${_selectedCategory?.id}'),
                  label: 'Motivação',
                  controller: _motivationController,
                  optionsBuilder: () => expenseViewModel
                      .getUniqueMotivationsForCategory(_selectedCategory?.id),
                  onSelected: (selection) {
                    _motivationController.text = selection;
                  },
                  maxLines: 3,
                )
              else
                TextFormField(
                  controller: _motivationController,
                  decoration: const InputDecoration(labelText: 'Motivação'),
                  enabled: false,
                  maxLines: 3,
                ),
              const SizedBox(height: 16),
              if (_isEditing)
                CategoryAutocompleteField(
                  key: ValueKey('location_${_selectedCategory?.id}'),
                  label: 'Local',
                  controller: _locationController,
                  optionsBuilder: () => expenseViewModel
                      .getUniqueLocationsForCategory(_selectedCategory?.id),
                  onSelected: (selection) {
                    _locationController.text = selection;
                  },
                )
              else
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Local'),
                  enabled: false,
                ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: _isEditing ? const Icon(Icons.calendar_today) : null,
                onTap: !_isEditing
                    ? null
                    : () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (pickedDate != null && pickedDate != _selectedDate) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
              ),
              const SizedBox(height: 24),
              if (_isEditing)
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
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
