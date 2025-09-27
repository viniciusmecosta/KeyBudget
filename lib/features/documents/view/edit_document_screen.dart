import 'package:flutter/material.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/documents_form.dart';

class EditDocumentScreen extends StatefulWidget {
  final Document document;

  const EditDocumentScreen({super.key, required this.document});

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _numeroController;
  late ValueNotifier<DateTime?> _dataExpedicao;
  late ValueNotifier<DateTime?> _validade;
  late ValueNotifier<List<Map<String, String>>> _camposAdicionais;
  late ValueNotifier<List<Anexo>> _anexos;
  Document? _documentoPai;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.document.nomeDocumento);
    _numeroController = TextEditingController(text: widget.document.numero);
    _dataExpedicao = ValueNotifier(widget.document.dataExpedicao);
    _validade = ValueNotifier(widget.document.validade);
    _camposAdicionais = ValueNotifier(widget.document.camposAdicionais.entries
        .map((e) => {'nome': e.key, 'valor': e.value})
        .toList());
    _anexos = ValueNotifier(List<Anexo>.from(widget.document.anexos));
    _documentoPai = widget.document.documentoPai;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;

    final updatedDocument = widget.document.copyWith(
      nomeDocumento: _nomeController.text,
      numero: _numeroController.text,
      dataExpedicao: _dataExpedicao.value,
      validade: _validade.value,
      camposAdicionais: {
        for (var campo in _camposAdicionais.value)
          campo['nome']!: campo['valor']!
      },
      anexos: _anexos.value,
      documentoPaiId: _documentoPai?.id,
    );

    final success = await viewModel.updateDocument(userId, updatedDocument);

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
    final viewModel = context.watch<DocumentViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Documento'),
      ),
      body: DocumentForm(
        formKey: _formKey,
        nomeController: _nomeController,
        numeroController: _numeroController,
        dataExpedicao: _dataExpedicao,
        validade: _validade,
        camposAdicionais: _camposAdicionais,
        anexos: _anexos,
        documentoPai: _documentoPai,
        allDocuments: viewModel.documents
            .where((d) => d.id != widget.document.id)
            .toList(),
        onDocumentoPaiChanged: (doc) {
          setState(() {
            _documentoPai = doc;
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: viewModel.isLoading ? null : _submit,
          child: viewModel.isLoading
              ? const CircularProgressIndicator()
              : const Text('Salvar Alterações'),
        ),
      ),
    );
  }
}