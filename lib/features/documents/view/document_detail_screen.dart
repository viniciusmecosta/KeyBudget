import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/view/image_viewer_screen.dart';
import 'package:key_budget/features/documents/view/pdf_viewer_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(document.documentName),
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
              if (!context.mounted) return;
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
          if (document.additionalFields.isNotEmpty)
            _buildAdditionalFieldsCard(context),
          if (document.attachments.isNotEmpty) _buildAttachmentsCard(context),
          if (document.versions.isNotEmpty)
            _buildVersionsCard(context, viewModel, userId),
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
            if (document.number != null && document.number!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child:
                        _buildDetailItem('Número', document.number!, context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all_outlined),
                    tooltip: 'Copiar número',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: document.number!));
                      SnackbarService.showSuccess(context, 'Número copiado!');
                    },
                  ),
                ],
              ),
            if (document.issueDate != null)
              _buildDetailItem(
                  'Data de Expedição',
                  DateFormat('dd/MM/yyyy').format(document.issueDate!),
                  context),
            if (document.expiryDate != null)
              _buildDetailItem(
                  'Validade',
                  DateFormat('dd/MM/yyyy').format(document.expiryDate!),
                  context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFieldsCard(BuildContext context) {
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
              ...document.additionalFields.entries
                  .map((e) => _buildDetailItem(e.key, e.value, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(BuildContext context) {
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
              ...document.attachments.map(
                  (attachment) => _buildAttachmentItem(attachment, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionsCard(
      BuildContext context, DocumentViewModel viewModel, String userId) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceL),
      child: Card(
        child: ExpansionTile(
          title: Text('Versões Anteriores', style: theme.textTheme.titleLarge),
          children: document.versions
              .map((v) => ListTile(
                    title: Text(v.issueDate != null
                        ? DateFormat('dd/MM/yyyy').format(v.issueDate!)
                        : 'Sem data'),
                    trailing: TextButton(
                      child: const Text('Marcar como Principal'),
                      onPressed: () async {
                        final allVersions = [document, ...document.versions];
                        final success = await viewModel.setAsPrincipal(
                            userId, v, allVersions);
                        if (!context.mounted) return;
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

  Widget _buildAttachmentItem(Attachment attachment, BuildContext context) {
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    final theme = Theme.of(context);
    final isPdf = attachment.type.contains('pdf');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
        ),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: Column(
        children: [
          ListTile(
            title: Text(attachment.name, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartilhar',
              onPressed: () async {
                await viewModel.shareAttachment(attachment);
                if (context.mounted && viewModel.errorMessage != null) {
                  SnackbarService.showError(context, viewModel.errorMessage!);
                }
              },
            ),
          ),
          InkWell(
            onTap: () async {
              final base64 =
                  await viewModel.downloadAttachmentAsBase64(attachment);
              if (base64 != null && context.mounted) {
                if (isPdf) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      pdfBase64: base64,
                      pdfName: attachment.name,
                    ),
                  ));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ImageViewerScreen(
                      imageBase64: base64,
                      imageName: attachment.name,
                    ),
                  ));
                }
              }
            },
            child: Container(
              height: 200,
              color: theme.colorScheme.surfaceContainerHighest,
              child: FutureBuilder<String?>(
                future: viewModel.downloadAttachmentAsBase64(attachment),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Icon(Icons.error_outline));
                  }
                  final base64 = snapshot.data!;
                  return isPdf
                      ? SfPdfViewer.memory(
                          base64Decode(base64),
                          enableDoubleTapZooming: false,
                        )
                      : Image.memory(
                          base64Decode(base64),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
