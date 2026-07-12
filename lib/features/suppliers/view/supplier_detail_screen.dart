import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../widgets/supplier_form.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _repNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  String? _photoPath;
  bool _isEditing = false;
  bool _isSaving = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier.name);
    _repNameController = TextEditingController(
      text: widget.supplier.representativeName,
    );
    _emailController = TextEditingController(text: widget.supplier.email);
    _phoneController = TextEditingController(
      text: _phoneMaskFormatter.maskText(widget.supplier.phoneNumber ?? ''),
    );
    _notesController = TextEditingController(text: widget.supplier.notes);
    _photoPath = widget.supplier.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final authViewModel = ref.read(authViewModelProvider);
    final viewModel = ref.read(supplierViewModelProvider);
    final scaffoldContext = context;
    final navigator = Navigator.of(context);
    final userId = authViewModel.currentUser!.id;

    await viewModel.updateSupplier(
      userId: userId,
      originalSupplier: widget.supplier,
      name: _nameController.text,
      representativeName: _repNameController.text.isNotEmpty
          ? _repNameController.text
          : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phoneNumber: _phoneMaskFormatter.unmaskText(_phoneController.text),
      photoPath: _photoPath,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!scaffoldContext.mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    SnackbarService.showSuccess(
      scaffoldContext,
      'Fornecedor atualizado com sucesso!',
    );
    navigator.pop();
  }

  void _deleteSupplier() async {
    HapticFeedback.mediumImpact();
    final authViewModel = ref.read(authViewModelProvider);
    final viewModel = ref.read(supplierViewModelProvider);
    final currentContext = context;
    final screenNavigator = Navigator.of(context);
    final deletedSupplier = widget.supplier;

    final userId = authViewModel.currentUser!.id;
    await viewModel.deleteSupplier(userId, deletedSupplier.id!);

    if (!currentContext.mounted) return;
    SnackbarService.showUndoSnackbar(
      currentContext,
      message: 'Fornecedor excluído.',
      onUndo: () async {
        await viewModel.restoreSupplier(userId, deletedSupplier);
      },
    );
    screenNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Fornecedor' : 'Detalhes'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Excluir',
              onPressed: _deleteSupplier,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Salvar',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: SupplierForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    repNameController: _repNameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    notesController: _notesController,
                    photoPath: _photoPath,
                    onPhotoChanged: (path) {
                      setState(() {
                        _photoPath = path;
                      });
                    },
                    isEditing: _isEditing,
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Salvar Alterações',
                    onPressed: _saveChanges,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
