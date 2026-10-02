import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../widgets/supplier_form.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _photoPath;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _repNameController,
      _emailController,
      _phoneController,
      _notesController,
    ]) {
      controller.addListener(_markUnsaved);
    }
  }

  void _markUnsaved() {
    if (!_hasUnsavedChanges) {
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(supplierViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser!.id;
    final phoneMaskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

    try {
      await viewModel.addSupplier(
        userId: userId,
        name: _nameController.text,
        representativeName: _repNameController.text.isNotEmpty
            ? _repNameController.text
            : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phoneNumber: phoneMaskFormatter.unmaskText(_phoneController.text),
        photoPath: _photoPath,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarService.showError(
          context,
          'Não foi possível salvar o fornecedor. Tente novamente.',
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      SnackbarService.showSuccess(context, 'Fornecedor salvo com sucesso!');
      _hasUnsavedChanges = false;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          setState(() => _hasUnsavedChanges = false);
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Adicionar Fornecedor')),
        body: AppAnimations.fadeInFromBottom(
          Padding(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            child: Column(
              children: [
                Expanded(
                  child: SupplierForm(
                    isEditing: true,
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
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Salvar Fornecedor',
                    onPressed: _submit,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),

          context: context,
        ),
      ),
    );
  }
}
