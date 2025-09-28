import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/document_form.dart';

class AddDocumentScreen extends StatefulWidget {
  final Document? originalDocument;
  final bool isNewVersion;

  const AddDocumentScreen(
      {super.key, this.originalDocument, this.isNewVersion = false});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  final _issueDate = ValueNotifier<DateTime?>(null);
  final _expiryDate = ValueNotifier<DateTime?>(null);
  final _additionalFields = ValueNotifier<List<Map<String, String>>>([]);
  final _attachments = ValueNotifier<List<Attachment>>([]);

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.originalDocument?.documentName ?? '');
    _numberController =
        TextEditingController(text: widget.originalDocument?.number ?? '');
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;

    final newDocumentData = Document(
      documentName: _nameController.text,
      number: _numberController.text,
      issueDate: _issueDate.value,
      expiryDate: _expiryDate.value,
      additionalFields: {
        for (var field in _additionalFields.value)
          if (field['name']!.isNotEmpty) field['name']!: field['value']!
      },
      attachments: _attachments.value,
      isPrincipal: widget.isNewVersion ? true : false,
      originalDocumentId:
      widget.originalDocument?.originalDocumentId ?? widget.originalDocument?.id,
    );

    final newId = await viewModel.addDocument(userId, newDocumentData);

    if (mounted) {
      if (newId != null) {
        if (widget.isNewVersion && widget.originalDocument != null) {
          final newDocumentWithId = newDocumentData.copyWith(id: newId);
          final allVersions = [
            widget.originalDocument!,
            ...widget.originalDocument!.versions,
            newDocumentWithId
          ];
          await viewModel.setAsPrincipal(
              userId, newDocumentWithId, allVersions);
        }
        SnackbarService.showSuccess(context, 'Documento salvo com sucesso!');
        Navigator.of(context).pop();
      } else {
        SnackbarService.showError(
            context, viewModel.errorMessage ?? 'Ocorreu um erro.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.isNewVersion ? 'Nova Versão' : 'Adicionar Documento'),
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
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: ElevatedButton(
          onPressed: viewModel.isLoading ? null : _submit,
          child: viewModel.isLoading
              ? const CircularProgressIndicator()
              : const Text('Salvar'),
        ),
      ),
    );
  }
}