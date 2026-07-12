import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

import '../widgets/document_form.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  final Document? originalDocument;
  final bool isNewVersion;

  const AddDocumentScreen({
    super.key,
    this.originalDocument,
    this.isNewVersion = false,
  });

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  final _issueDate = ValueNotifier<DateTime?>(null);
  final _expiryDate = ValueNotifier<DateTime?>(null);
  final _additionalFields = ValueNotifier<List<Map<String, String>>>([]);
  final _attachments = ValueNotifier<List<Attachment>>([]);
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.originalDocument?.documentName ?? '',
    );
    _numberController = TextEditingController(
      text: widget.originalDocument?.number ?? '',
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(documentViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;

    final newDocumentData = Document(
      documentName: _nameController.text,
      number: _numberController.text,
      issueDate: _issueDate.value,
      expiryDate: _expiryDate.value,
      additionalFields: {
        for (var field in _additionalFields.value)
          if (field['name']!.isNotEmpty) field['name']!: field['value']!,
      },
      attachments: _attachments.value,
      isPrincipal: widget.isNewVersion ? true : false,
      originalDocumentId:
          widget.originalDocument?.originalDocumentId ??
          widget.originalDocument?.id,
    );

    final newId = await viewModel.addDocument(userId, newDocumentData);

    if (mounted) {
      if (newId != null) {
        if (widget.isNewVersion && widget.originalDocument != null) {
          final newDocumentWithId = newDocumentData.copyWith(id: newId);
          final allVersions = [
            widget.originalDocument!,
            ...widget.originalDocument!.versions,
            newDocumentWithId,
          ];
          await viewModel.setAsPrincipal(
            userId,
            newDocumentWithId,
            allVersions,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        SnackbarService.showError(
          context,
          viewModel.errorMessage ?? 'Ocorreu um erro.',
        );
      }
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
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
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
            widget.isNewVersion ? 'Nova Versão' : 'Adicionar Documento',
          ),
        ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: DocumentForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  numberController: _numberController,
                  issueDate: _issueDate,
                  expiryDate: _expiryDate,
                  additionalFields: _additionalFields,
                  attachments: _attachments,
                  onChanged: () {
                    if (!_hasUnsavedChanges) {
                      setState(() => _hasUnsavedChanges = true);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: _submit,
                  isLoading: viewModel.isLoading,
                  label: 'Salvar',
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
