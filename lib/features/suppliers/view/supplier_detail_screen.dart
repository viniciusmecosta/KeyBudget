import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
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
  bool _hasUnsavedChanges = false;

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
    for (final controller in [
      _nameController,
      _repNameController,
      _emailController,
      _phoneController,
      _notesController,
    ]) {
      controller.addListener(_markChanged);
    }
  }

  void _markChanged() {
    if (_isEditing && !_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
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
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final authViewModel = ref.read(authViewModelProvider);
    final viewModel = ref.read(supplierViewModelProvider);
    final scaffoldContext = context;
    final navigator = Navigator.of(context);
    final userId = authViewModel.currentUser!.id;

    try {
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
        _isEditing = false;
        _hasUnsavedChanges = false;
      });
      SnackbarService.showSuccess(
        scaffoldContext,
        'Fornecedor atualizado com sucesso!',
      );
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) navigator.pop();
    } catch (_) {
      if (scaffoldContext.mounted) {
        SnackbarService.showError(
          scaffoldContext,
          'Não foi possível salvar o fornecedor. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _deleteSupplier() async {
    HapticFeedback.mediumImpact();
    final authViewModel = ref.read(authViewModelProvider);
    final viewModel = ref.read(supplierViewModelProvider);
    final currentContext = context;
    final screenNavigator = Navigator.of(context);
    final deletedSupplier = widget.supplier;

    final userId = authViewModel.currentUser!.id;
    try {
      await viewModel.deleteSupplier(userId, deletedSupplier.id!);
    } catch (_) {
      if (currentContext.mounted) {
        SnackbarService.showError(
          currentContext,
          'Não foi possível mover o fornecedor para a lixeira.',
        );
      }
      return;
    }

    if (!currentContext.mounted) return;
    SnackbarService.showSuccess(
      currentContext,
      'Fornecedor movido para a lixeira.',
    );
    screenNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text(
              'Você tem alterações não salvas. Deseja sair sem salvar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (shouldPop == true && mounted) {
          setState(() => _hasUnsavedChanges = false);
          await WidgetsBinding.instance.endOfFrame;
          if (mounted) Navigator.of(this.context).pop(result);
        }
      },
      child: AppPageScaffold(
        maxContentWidth: 960,
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
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
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
                          _hasUnsavedChanges = true;
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

          context: context,
        ),
      ),
    );
  }
}
