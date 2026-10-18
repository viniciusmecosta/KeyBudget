import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_form_page_body.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

import '../widgets/document_form.dart';

class EditDocumentScreen extends ConsumerStatefulWidget {
  final Document document;

  const EditDocumentScreen({super.key, required this.document});

  @override
  ConsumerState<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends ConsumerState<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late ValueNotifier<DateTime?> _issueDate;
  late ValueNotifier<DateTime?> _expiryDate;
  late ValueNotifier<List<Map<String, String>>> _additionalFields;
  late ValueNotifier<List<Attachment>> _attachments;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.documentName);
    _numberController = TextEditingController(text: widget.document.number);
    _issueDate = ValueNotifier(widget.document.issueDate);
    _expiryDate = ValueNotifier(widget.document.expiryDate);
    _additionalFields = ValueNotifier(
      widget.document.additionalFields.entries
          .map((e) => {'name': e.key, 'value': e.value})
          .toList(),
    );
    _attachments = ValueNotifier(
      widget.document.attachments
          .map((attachment) => attachment.copy())
          .toList(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _issueDate.dispose();
    _expiryDate.dispose();
    _additionalFields.dispose();
    _attachments.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(documentViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;

    final updatedDocument = widget.document.copyWith(
      documentName: _nameController.text.trim(),
      number: _numberController.text.trim(),
      clearNumber: _numberController.text.trim().isEmpty,
      issueDate: _issueDate.value,
      clearIssueDate: _issueDate.value == null,
      expiryDate: _expiryDate.value,
      clearExpiryDate: _expiryDate.value == null,
      additionalFields: {
        for (var field in _additionalFields.value)
          if (field['name']!.trim().isNotEmpty)
            field['name']!.trim(): field['value']!.trim(),
      },
      attachments: _attachments.value,
    );

    try {
      final success = await viewModel.updateDocument(
        userId,
        updatedDocument,
        widget.document,
      );
      if (!mounted) return;
      if (success) {
        setState(() => _hasUnsavedChanges = false);
        SnackbarService.showSuccess(
          context,
          'Documento atualizado com sucesso!',
        );
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.of(context).pop();
      } else {
        SnackbarService.showError(
          context,
          viewModel.errorMessage ?? 'Não foi possível salvar o documento.',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível salvar o documento. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(documentViewModelProvider);
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
          animationStyle: AppAnimations.routeStyle(context),
        );
        if (shouldPop == true && mounted) {
          setState(() => _hasUnsavedChanges = false);
          await WidgetsBinding.instance.endOfFrame;
          if (mounted) Navigator.of(this.context).pop(result);
        }
      },
      child: AppPageScaffold(
        maxContentWidth: 760,
        appBar: AppBar(title: const Text('Editar Documento')),
        body: AppAnimations.fadeInFromBottom(
          AppFormPageBody(
            form: DocumentForm(
              formKey: _formKey,
              nameController: _nameController,
              numberController: _numberController,
              issueDate: _issueDate,
              expiryDate: _expiryDate,
              additionalFields: _additionalFields,
              attachments: _attachments,
              onChanged: _markChanged,
            ),
            action: AppButton(
              onPressed: _submit,
              isLoading: _isSaving || viewModel.isLoading,
              label: 'Salvar Alterações',
            ),
          ),

          context: context,
        ),
      ),
    );
  }
}
