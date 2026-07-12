import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

class DocumentForm extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final ValueNotifier<DateTime?> issueDate;
  final ValueNotifier<DateTime?> expiryDate;
  final ValueNotifier<List<Map<String, String>>> additionalFields;
  final ValueNotifier<List<Attachment>> attachments;
  final VoidCallback? onChanged;

  const DocumentForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.numberController,
    required this.issueDate,
    required this.expiryDate,
    required this.additionalFields,
    required this.attachments,
    this.onChanged,
  });

  @override
  ConsumerState<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends ConsumerState<DocumentForm> {
  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
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
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(documentViewModelProvider);
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      onChanged: widget.onChanged,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionHeader(context, 'INFORMAÇÕES PRINCIPAIS', Icons.description_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: widget.nameController,
            label: 'Nome do Documento *',
            prefixIcon: Icons.article_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value!.isEmpty ? 'Informe o nome do documento' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.numberController,
            label: 'Número',
            prefixIcon: Icons.tag_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(context, 'Data de Expedição', widget.issueDate),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(context, 'Validade', widget.expiryDate),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'CAMPOS ADICIONAIS', Icons.list_alt_outlined),
          const SizedBox(height: AppSpacing.sm),
          ..._buildAdditionalFields(theme),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Adicionar Campo'),
              onPressed: () {
                setState(() {
                  widget.additionalFields.value.add({'name': '', 'value': ''});
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'ANEXOS', Icons.attach_file_outlined),
          ..._buildAttachments(context),
          if (viewModel.isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: viewModel.uploadProgress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Enviando arquivo...', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Adicionar Anexo'),
              onPressed: viewModel.isUploading
                  ? null
                  : () async {
                      final attachment = await viewModel.pickAndUploadFile();
                      if (attachment != null) {
                        setState(() {
                          widget.attachments.value.add(attachment);
                        });
                      }
                    },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<Widget> _buildAdditionalFields(ThemeData theme) {
    return widget.additionalFields.value.map((field) {
      final index = widget.additionalFields.value.indexOf(field);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: field['name'],
                decoration: const InputDecoration(
                  labelText: 'Campo',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onChanged: (value) {
                  widget.additionalFields.value[index]['name'] = value;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                initialValue: field['value'],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixIcon: Icon(Icons.short_text),
                ),
                onChanged: (value) {
                  widget.additionalFields.value[index]['value'] = value;
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
              onPressed: () {
                setState(() {
                  widget.additionalFields.value.removeAt(index);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAttachments(BuildContext context) {
    final theme = Theme.of(context);
    return widget.attachments.value.map((attachment) {
      final nameController = TextEditingController(text: attachment.name);
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppBorders.borderRadiusM,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.insert_drive_file_outlined, color: theme.colorScheme.primary),
          ),
          title: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Nome do anexo',
              border: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              attachment.name = value;
            },
          ),
          trailing: IconButton(
            icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
            onPressed: () {
              setState(() {
                widget.attachments.value.remove(attachment);
              });
            },
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    ValueNotifier<DateTime?> notifier,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: notifier.value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          locale: const Locale('pt', 'BR'),
        );
        if (date != null) {
          setState(() {
            notifier.value = date;
          });
        }
      },
      borderRadius: AppBorders.borderRadiusM,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: notifier.value != null
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () {
                    setState(() {
                      notifier.value = null;
                    });
                  },
                )
              : const Icon(Icons.chevron_right),
        ),
        child: Text(
          notifier.value == null
              ? 'Não definida'
              : DateFormat('dd/MM/yyyy').format(notifier.value!),
          style: notifier.value == null
              ? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                )
              : theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
