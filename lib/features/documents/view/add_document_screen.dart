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
  late TextEditingController _nomeController;
  late TextEditingController _numeroController;
  final _dataExpedicao = ValueNotifier<DateTime?>(null);
  final _validade = ValueNotifier<DateTime?>(null);
  final _camposAdicionais = ValueNotifier<List<Map<String, String>>>([]);
  final _anexos = ValueNotifier<List<Anexo>>([]);

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
        text: widget.originalDocument?.nomeDocumento ?? '');
    _numeroController =
        TextEditingController(text: widget.originalDocument?.numero ?? '');
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;

    final newDocument = Document(
      nomeDocumento: _nomeController.text,
      numero: _numeroController.text,
      dataExpedicao: _dataExpedicao.value,
      validade: _validade.value,
      camposAdicionais: {
        for (var campo in _camposAdicionais.value)
          if (campo['nome']!.isNotEmpty) campo['nome']!: campo['valor']!
      },
      anexos: _anexos.value,
      isPrincipal: widget.isNewVersion ? true : false,
      originalDocumentId: widget.originalDocument?.originalDocumentId ??
          widget.originalDocument?.id,
    );

    final success = await viewModel.addDocument(userId, newDocument);

    if (mounted) {
      if (success) {
        if (widget.isNewVersion && widget.originalDocument != null) {
          final allVersions = [
            widget.originalDocument!,
            ...widget.originalDocument!.versoes,
            newDocument
          ];
          await viewModel.setAsPrincipal(userId, newDocument, allVersions);
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
        nomeController: _nomeController,
        numeroController: _numeroController,
        dataExpedicao: _dataExpedicao,
        validade: _validade,
        camposAdicionais: _camposAdicionais,
        anexos: _anexos,
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
