import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/view/file_viewer_screen.dart';
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
            if (document.number != null)
              _buildDetailItem('Número', document.number!, context),
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
                      (attachment) => AttachmentPreviewWidget(attachment: attachment)),
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
}

class AttachmentPreviewWidget extends StatefulWidget {
  final Attachment attachment;

  const AttachmentPreviewWidget({super.key, required this.attachment});

  @override
  State<AttachmentPreviewWidget> createState() =>
      _AttachmentPreviewWidgetState();
}

class _AttachmentPreviewWidgetState extends State<AttachmentPreviewWidget> {
  Future<File?>? _downloadFuture;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
    _downloadFuture = viewModel.downloadFileForViewing(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = widget.attachment.type.toLowerCase() == 'pdf';
    final isImage = ['png', 'jpg', 'jpeg', 'webp']
        .contains(widget.attachment.type.toLowerCase());

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
      child: InkWell(
        onTap: () async {
          final file = await _downloadFuture;
          if (file != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FileViewerScreen(
                  filePath: file.path,
                  fileName: widget.attachment.name,
                ),
              ),
            );
          } else if (mounted) {
            SnackbarService.showError(
                context, "Não foi possível abrir o anexo.");
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              ),
              title:
              Text(widget.attachment.name, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.open_in_new),
            ),
            if (isPdf || isImage)
              Container(
                height: 200,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: FutureBuilder<File?>(
                  future: _downloadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(height: 8),
                            Text("Falha ao carregar pré-visualização"),
                          ],
                        ),
                      );
                    }
                    final file = snapshot.data!;
                    if (isPdf) {
                      return SfPdfViewer.file(file);
                    }
                    if (isImage) {
                      return Image.file(file, fit: BoxFit.cover);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}