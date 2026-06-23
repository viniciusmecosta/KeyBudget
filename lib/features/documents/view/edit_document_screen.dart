import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.documentName);
    _numberController = TextEditingController(text: widget.document.number);
    _issueDate = ValueNotifier(widget.document.issueDate);
    _expiryDate = ValueNotifier(widget.document.expiryDate);
    _additionalFields = ValueNotifier(widget.document.additionalFields.entries
        .map((e) => {'name': e.key, 'value': e.value})
        .toList());
    _attachments =
        ValueNotifier(List<Attachment>.from(widget.document.attachments));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(documentViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;

    final updatedDocument = widget.document.copyWith(
      documentName: _nameController.text,
      number: _numberController.text,
      issueDate: _issueDate.value,
      expiryDate: _expiryDate.value,
      additionalFields: {
        for (var field in _additionalFields.value)
          if (field['name']!.isNotEmpty) field['name']!: field['value']!
      },
      attachments: _attachments.value,
    );

    final success = await viewModel.updateDocument(
        userId, updatedDocument, widget.document);

    if (mounted) {
      if (success) {
        SnackbarService.showSuccess(
            context, 'Documento atualizado com sucesso!');
        Navigator.of(context).pop();
      } else {
        SnackbarService.showError(
            context, viewModel.errorMessage ?? 'Ocorreu um erro.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(documentViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Documento'),
      ),
      body: DocumentForm(
        formKey: _formKey,
        nameController: _nameController,
        numberController: _numberController,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        additionalFields: _additionalFields,
        attachments: _attachments,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppButton(
          onPressed: _submit,
          isLoading: viewModel.isLoading,
          label: 'Salvar Alterações',
        ),
      ),
    );
  }
}
