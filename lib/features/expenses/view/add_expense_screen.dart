import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/category_autocomplete_field.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _motivationController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isSaving = false;

  static const String _manageCategoriesValue = '--manage-categories--';

  @override
  void dispose() {
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final theme = Theme.of(context);
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);

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

    String? finalCategoryId = _selectedCategoryId;
    if (finalCategoryId == null) {
      final otherCategory = categoryViewModel.categories
          .firstWhere((cat) => cat.name == 'Outros', orElse: () => null!);
      if (otherCategory != null) {
        finalCategoryId = otherCategory.id;
      }
    }

    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    final newExpense = Expense(
      amount: _amountController.numberValue,
      date: _selectedDate,
      categoryId: finalCategoryId,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
    );

    await expenseViewModel.addExpense(userId, newExpense);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Despesa salva com sucesso!'),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Despesa')),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  if (_amountController.numberValue <= 0) {
                    return 'O valor deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                isExpanded: false,
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: theme.cardColor,
                items: [
                  ...categoryViewModel.categories.map((category) {
                    return DropdownMenuItem<String?>(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 22, color: category.color),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }),
                  const DropdownMenuItem<String?>(
                    enabled: false,
                    child: Divider(height: 0),
                  ),
                  DropdownMenuItem<String?>(
                    value: _manageCategoriesValue,
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined,
                            color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Gerenciar Categorias',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == _manageCategoriesValue) {
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
                  } else {
                    setState(() {
                      _selectedCategoryId = value;
                      _motivationController.clear();
                      _locationController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              CategoryAutocompleteField(
                key: ValueKey('motivation_$_selectedCategoryId'),
                label: 'Motivação',
                controller: _motivationController,
                optionsBuilder: () => expenseViewModel
                    .getUniqueMotivationsForCategory(_selectedCategoryId),
                onSelected: (selection) {
                  _motivationController.text = selection;
                },
              ),
              const SizedBox(height: 16),
              CategoryAutocompleteField(
                key: ValueKey('location_$_selectedCategoryId'),
                label: 'Local',
                controller: _locationController,
                optionsBuilder: () => expenseViewModel
                    .getUniqueLocationsForCategory(_selectedCategoryId),
                onSelected: (selection) {
                  _locationController.text = selection;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Selecionar Data'),
                  )
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                            strokeWidth: 2.0))
                    : const Text('Salvar Despesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
