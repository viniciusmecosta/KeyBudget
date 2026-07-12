import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'add_document_screen.dart';
import 'edit_document_screen.dart';

class DocumentDetailScreen extends ConsumerWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(documentViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.documentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => NavigationUtils.push(
              context,
              EditDocumentScreen(document: document),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Nova Versão',
            onPressed: () => NavigationUtils.push(
              context,
              AddDocumentScreen(originalDocument: document, isNewVersion: true),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final navigator = Navigator.of(context);
              final scaffoldContext = context;
              final success = await viewModel.deleteDocument(userId, document);
              if (!scaffoldContext.mounted) return;
              if (success) {
                SnackbarService.showSuccess(
                  scaffoldContext,
                  'Documento excluído!',
                );
                navigator.pop();
              } else {
                SnackbarService.showError(
                  scaffoldContext,
                  viewModel.errorMessage ?? 'Erro ao excluir.',
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, Icons.description_outlined, 'DADOS DO DOCUMENTO'),
            const SizedBox(height: AppSpacing.md),
            if (document.number != null && document.number!.isNotEmpty) ...[
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  AppTextField(
                    controller: TextEditingController(text: document.number),
                    label: 'Número',
                    prefixIcon: Icons.numbers_outlined,
                    readOnly: true,
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.copy_outlined, color: theme.colorScheme.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: document.number!));
                        HapticFeedback.lightImpact();
                        SnackbarService.showSuccess(context, 'Número copiado!');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: TextEditingController(
                      text: document.issueDate != null
                          ? DateFormat('dd/MM/yyyy').format(document.issueDate!)
                          : 'Não informada',
                    ),
                    label: 'Data de Expedição',
                    prefixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: TextEditingController(
                      text: document.expiryDate != null
                          ? DateFormat('dd/MM/yyyy').format(document.expiryDate!)
                          : 'Não informada',
                    ),
                    label: 'Validade',
                    prefixIcon: Icons.event_busy_outlined,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            if (document.additionalFields.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, Icons.list_alt_outlined, 'CAMPOS ADICIONAIS'),
              const SizedBox(height: AppSpacing.md),
              ...document.additionalFields.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller: TextEditingController(text: e.value),
                  label: e.key,
                  prefixIcon: Icons.info_outline,
                  readOnly: true,
                ),
              )),
            ],
            if (document.attachments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, Icons.attachment_outlined, 'ANEXOS'),
              const SizedBox(height: AppSpacing.md),
              ...document.attachments.map((a) => _buildAttachmentItem(a, context, ref)),
            ],
            if (document.versions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, Icons.history_outlined, 'VERSÕES ANTERIORES'),
              const SizedBox(height: AppSpacing.md),
              _buildVersionsList(context, viewModel, userId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(Attachment attachment, BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPdf = attachment.type.contains('pdf');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    attachment.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: theme.colorScheme.primary),
                  onPressed: () async {
                    final viewModel = ref.read(documentViewModelProvider);
                    final scaffoldContext = context;
                    await viewModel.shareAttachment(attachment);
                    if (scaffoldContext.mounted && viewModel.errorMessage != null) {
                      SnackbarService.showError(scaffoldContext, viewModel.errorMessage!);
                    }
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final viewModel = ref.read(documentViewModelProvider);
              final scaffoldContext = context;
              if (isPdf) {
                final file = await viewModel.getAttachmentFile(attachment);
                if (file != null && scaffoldContext.mounted) {
                  await viewModel.openFile(attachment);
                  if (scaffoldContext.mounted && viewModel.errorMessage != null) {
                    SnackbarService.showError(scaffoldContext, viewModel.errorMessage ?? 'Erro ao abrir PDF');
                  }
                }
              } else {
                await viewModel.openFile(attachment);
                if (scaffoldContext.mounted && viewModel.errorMessage != null) {
                  SnackbarService.showError(scaffoldContext, viewModel.errorMessage ?? 'Erro ao abrir imagem');
                }
              }
            },
            child: SizedBox(
              height: 200,
              child: FutureBuilder<String?>(
                future: ref.read(documentViewModelProvider).getAttachmentAsBase64(attachment),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Icon(Icons.error_outline));
                  }
                  final base64 = snapshot.data!;
                  return isPdf
                      ? Stack(
                          children: [
                            SfPdfViewer.memory(
                              base64Decode(base64),
                              enableDoubleTapZooming: false,
                              interactionMode: PdfInteractionMode.pan,
                            ),
                            Container(color: Colors.transparent),
                          ],
                        )
                      : Image.memory(base64Decode(base64), fit: BoxFit.cover, width: double.infinity);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsList(BuildContext context, DocumentViewModel viewModel, String userId) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: document.versions.map((v) {
          final isLast = v == document.versions.last;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text(
                  v.issueDate != null ? DateFormat('dd/MM/yyyy').format(v.issueDate!) : 'Versão Antiga',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final allVersions = [document, ...document.versions];
                    final scaffoldContext = context;
                    final navigator = Navigator.of(context);
                    final success = await viewModel.setAsPrincipal(userId, v, allVersions);
                    if (!scaffoldContext.mounted) return;
                    if (success) {
                      SnackbarService.showSuccess(scaffoldContext, 'Versão restaurada!');
                      navigator.pop();
                    } else {
                      SnackbarService.showError(scaffoldContext, viewModel.errorMessage ?? 'Erro.');
                    }
                  },
                  child: const Text('Restaurar'),
                ),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: v)),
                ),
              ),
              if (!isLast) Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}
