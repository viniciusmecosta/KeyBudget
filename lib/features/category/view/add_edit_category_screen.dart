import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/widgets/color_picker_widget.dart';
import 'package:key_budget/features/category/view/widgets/icon_picker_widget.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
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
        Provider.of<DashboardViewModel>(context, listen: false)
            .loadDashboardData(userId);
        Provider.of<AnalysisViewModel>(context, listen: false)
            .loadAnalysisData(userId);
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_selectedIcon ?? Icons.category, size: 32),
                title: const Text('Ícone'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final icon = await showDialog<IconData>(
                    context: context,
                    builder: (_) => const IconPickerWidget(),
                  );
                  if (icon != null) {
                    setState(() => _selectedIcon = icon);
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: _selectedColor ?? Colors.grey, radius: 16),
                title: const Text('Cor'),
                trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }
}
