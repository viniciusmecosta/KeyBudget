import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'add_document_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(document.nomeDocumento),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Nova Versão',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  AddDocumentScreen(documentoPai: document, isNewVersion: true),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final success = await viewModel.deleteDocument(userId, document.id!);
              if (success) {
                SnackbarService.showSuccess(
                    context, 'Documento excluído com sucesso!');
                Navigator.of(context).pop();
              } else {
                SnackbarService.showError(
                    context, viewModel.errorMessage ?? 'Erro ao excluir.');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Número', document.numero, context),
            _buildDetailItem('Data de Expedição',
                DateFormat('dd/MM/yyyy').format(document.dataExpedicao), context),
            if (document.validade != null)
              _buildDetailItem('Validade',
                  DateFormat('dd/MM/yyyy').format(document.validade!), context),
            ...document.camposAdicionais.entries
                .map((e) => _buildDetailItem(e.key, e.value, context)),
            if (document.anexos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Anexos', style: Theme.of(context).textTheme.titleLarge),
              ...document.anexos.map((anexo) => _buildAnexoItem(anexo, context)),
            ],
            if (document.versoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text('Versões Anteriores',
                    style: Theme.of(context).textTheme.titleLarge),
                children: document.versoes
                    .map((v) => ListTile(
                  title: Text(DateFormat('dd/MM/yyyy')
                      .format(v.dataExpedicao)),
                  trailing: TextButton(
                    child: const Text('Marcar como Principal'),
                    onPressed: () async {
                      final allVersions = [document, ...document.versoes];
                      final success = await viewModel.setAsPrincipal(
                          userId, v, allVersions);
                      if (success) {
                        SnackbarService.showSuccess(context,
                            'Versão definida como principal!');
                      } else {
                        SnackbarService.showError(context,
                            viewModel.errorMessage ?? 'Erro ao definir.');
                      }
                    },
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentDetailScreen(document: v),
                    ),
                  ),
                ))
                    .toList(),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildAnexoItem(Anexo anexo, BuildContext context) {
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    return Card(
      child: Column(
        children: [
          if (anexo.tipo.contains('pdf'))
            SizedBox(
              height: 200,
              child: SfPdfViewer.memory(base64Decode(anexo.base64)),
            )
          else
            Image.memory(base64Decode(anexo.base64)),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Baixar'),
                onPressed: () async {
                  await viewModel.downloadAndOpenFile(anexo);
                  if (viewModel.errorMessage != null) {
                    SnackbarService.showError(
                        context, viewModel.errorMessage!);
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}