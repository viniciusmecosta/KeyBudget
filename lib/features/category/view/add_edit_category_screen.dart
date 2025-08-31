import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/widgets/color_picker_widget.dart';
import 'package:key_budget/features/category/view/widgets/icon_picker_widget.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:provider/provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione um ícone e uma cor.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final viewModel = Provider.of<CategoryViewModel>(context, listen: false);
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;

    final category = ExpenseCategory(
      id: widget.category?.id,
      name: _nameController.text,
      iconCodePoint: _selectedIcon!.codePoint,
      colorValue: _selectedColor!.value,
    );

    final future = widget.category == null
        ? viewModel.addCategory(userId, category)
        : viewModel.updateCategory(userId, category);

    future.whenComplete(() {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.category == null ? 'Nova Categoria' : 'Editar Categoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nome da Categoria *'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final icon = await showModalBottomSheet<IconData>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const IconPickerWidget(),
                        );
                        if (icon != null) {
                          setState(() => _selectedIcon = icon);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ícone',
                          contentPadding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: Center(
                          child: Icon(
                            _selectedIcon ?? Icons.category,
                            size: 36,
                            color: _selectedColor ??
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final color = await showDialog<Color>(
                          context: context,
                          builder: (_) =>
                              ColorPickerWidget(initialColor: _selectedColor),
                        );
                        if (color != null) {
                          setState(() => _selectedColor = color);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Cor',
                          contentPadding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            backgroundColor: _selectedColor ?? Colors.grey,
                            radius: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('Salvar Categoria'),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
