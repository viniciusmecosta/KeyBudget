import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/category_form.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final ExpenseCategory? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  IconData? _selectedIcon;
  Color? _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIcon = widget.category?.icon;
    _selectedColor = widget.category?.color;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcon == null || _selectedColor == null) {
      SnackbarService.showError(
          context, 'Por favor, selecione um ícone e uma cor.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = Provider.of<CategoryViewModel>(context, listen: false);
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;
    final navigator = Navigator.of(context);

    final category = ExpenseCategory(
      id: widget.category?.id,
      name: _nameController.text,
      iconCodePoint: _selectedIcon!.codePoint,
      colorValue: _selectedColor!.toARGB32(),
    );

    final future = widget.category == null
        ? viewModel.addCategory(userId, category)
        : viewModel.updateCategory(userId, category);

    future.whenComplete(() {
      if (mounted) {
        setState(() => _isSaving = false);
        navigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.category == null ? 'Nova Categoria' : 'Editar Categoria'),
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: CategoryForm(
                formKey: _formKey,
                nameController: _nameController,
                selectedIcon: _selectedIcon,
                selectedColor: _selectedColor,
                onIconChanged: (icon) {
                  setState(() => _selectedIcon = icon);
                },
                onColorChanged: (color) {
                  setState(() => _selectedColor = color);
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0))
                  : const Text('Salvar Categoria'),
            ),
          ],
        ),
      )),
    );
  }
}
