import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'add_document_screen.dart';
import 'edit_document_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();
    final userId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser!.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.nomeDocumento),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Documento',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EditDocumentScreen(document: document),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Adicionar Nova Versão',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddDocumentScreen(
                  originalDocument: document, isNewVersion: true),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final success =
                  await viewModel.deleteDocument(userId, document.id!);
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
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        children: [
          _buildInfoCard(context),
          if (document.camposAdicionais.isNotEmpty)
            _buildCamposAdicionaisCard(context),
          if (document.anexos.isNotEmpty) _buildAnexosCard(context),
          if (document.versoes.isNotEmpty)
            _buildVersoesCard(context, viewModel, userId),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações Principais', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spaceL),
            _buildDetailItem('Número', document.numero, context),
            if (document.dataExpedicao != null)
              _buildDetailItem(
                  'Data de Expedição',
                  DateFormat('dd/MM/yyyy').format(document.dataExpedicao!),
                  context),
            if (document.validade != null)
              _buildDetailItem('Validade',
                  DateFormat('dd/MM/yyyy').format(document.validade!), context),
          ],
        ),
      ),
    );
  }

  Widget _buildCamposAdicionaisCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceL),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Campos Adicionais', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppTheme.spaceL),
              ...document.camposAdicionais.entries
                  .map((e) => _buildDetailItem(e.key, e.value, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnexosCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceL),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anexos', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppTheme.spaceM),
              ...document.anexos
                  .map((anexo) => _buildAnexoItem(anexo, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersoesCard(
      BuildContext context, DocumentViewModel viewModel, String userId) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceL),
      child: Card(
        child: ExpansionTile(
          title: Text('Versões Anteriores', style: theme.textTheme.titleLarge),
          children: document.versoes
              .map((v) => ListTile(
                    title: Text(v.dataExpedicao != null
                        ? DateFormat('dd/MM/yyyy').format(v.dataExpedicao!)
                        : 'Sem data'),
                    trailing: TextButton(
                      child: const Text('Marcar como Principal'),
                      onPressed: () async {
                        final allVersions = [document, ...document.versoes];
                        final success = await viewModel.setAsPrincipal(
                            userId, v, allVersions);
                        if (success) {
                          SnackbarService.showSuccess(
                              context, 'Versão definida como principal!');
                          Navigator.pop(context);
                        } else {
                          SnackbarService.showError(context,
                              viewModel.errorMessage ?? 'Erro ao definir.');
                        }
                      },
                    ),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DocumentDetailScreen(document: v),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildAnexoItem(Anexo anexo, BuildContext context) {
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
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
                    SnackbarService.showError(context, viewModel.errorMessage!);
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
