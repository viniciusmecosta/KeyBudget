import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';

import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';

import '../widgets/category_form.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final ExpenseCategory? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  IconData? _selectedIcon;
  Color? _selectedColor;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIcon = widget.category?.icon;
    _selectedColor = widget.category?.color;
  }

  void _deleteCategory() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final viewModel = ref.read(categoryViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;
    final scaffoldContext = context;
    final navigator = Navigator.of(context);
    
    await viewModel.deleteCategory(userId, widget.category!.id!);
    
    if (scaffoldContext.mounted) {
      SnackbarService.showUndoSnackbar(
        scaffoldContext,
        message: 'Categoria excluída.',
        onUndo: () async {
          await viewModel.restoreCategory(userId, widget.category!);
        },
      );
      navigator.pop();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcon == null || _selectedColor == null) {
      SnackbarService.showError(
        context,
        'Por favor, selecione um ícone e uma cor.',
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(categoryViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;
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
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Você tem alterações não salvas. Deseja sair sem salvar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          widget.category == null ? 'Nova Categoria' : 'Editar Categoria',
        ),
        actions: [
          if (widget.category != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCategory,
            ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: CategoryForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  onChanged: () {
                    if (!_hasUnsavedChanges) {
                      setState(() => _hasUnsavedChanges = true);
                    }
                  },
                  onIconChanged: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                      _hasUnsavedChanges = true;
                    });
                  },
                  onColorChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Salvar Categoria',
                  onPressed: _submit,
                  isLoading: _isSaving,
                  icon: Icons.check,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
