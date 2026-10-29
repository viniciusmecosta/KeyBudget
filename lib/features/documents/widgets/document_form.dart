import 'package:passfin/core/design_system/widgets/app_date_picker.dart';
import 'package:passfin/core/design_system/surfaces/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_text_field.dart';
import 'package:passfin/core/design_system/widgets/app_form_section_heading.dart';
import 'package:passfin/core/models/document_model.dart';
import 'package:passfin/core/services/app_lock_service.dart';
import 'package:passfin/features/documents/viewmodel/document_viewmodel.dart';

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
  Widget _pairedFields(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth >= 640 &&
            MediaQuery.textScalerOf(context).scale(14) <= 21
        ? Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: second),
            ],
          )
        : Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.md),
              second,
            ],
          ),
  );

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
          const AppFormSectionHeading(
            title: 'Informações principais',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _pairedFields(
            AppTextField(
              controller: widget.nameController,
              label: 'Nome do Documento *',
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value!.isEmpty ? 'Informe o nome do documento' : null,
            ),
            AppTextField(
              controller: widget.numberController,
              label: 'Número',
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _pairedFields(
            _buildDatePicker(context, 'Data de Expedição', widget.issueDate),
            _buildDatePicker(context, 'Validade', widget.expiryDate),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppFormSectionHeading(
            title: 'Campos adicionais',
            icon: Icons.list_alt_outlined,
          ),
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
                widget.onChanged?.call();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppFormSectionHeading(
            title: 'Anexos',
            icon: Icons.attach_file_outlined,
          ),
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
                      final appLock = ref.read(appLockServiceProvider);
                      appLock.beginExternalPick();
                      try {
                        final attachment = await viewModel.pickAndUploadFile();
                        if (mounted && attachment != null) {
                          setState(() {
                            widget.attachments.value.add(attachment);
                          });
                          widget.onChanged?.call();
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Não foi possível anexar o arquivo. Confira a conexão e tente novamente.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        appLock.endExternalPick();
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
      return Padding(
        key: ObjectKey(field),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pairedFields(
              TextFormField(
                initialValue: field['name'],
                decoration: const InputDecoration(labelText: 'Campo'),
                textInputAction: TextInputAction.next,
                onChanged: (value) => field['name'] = value,
              ),
              TextFormField(
                initialValue: field['value'],
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Valor'),
                onChanged: (value) => field['value'] = value,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => widget.additionalFields.value.remove(field));
                  widget.onChanged?.call();
                },
                child: const Text('Remover campo'),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAttachments(BuildContext context) {
    final theme = Theme.of(context);
    return widget.attachments.value.map((attachment) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: AppSurfaces.panel(context),
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
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          title: TextFormField(
            key: ValueKey(attachment.driveId),
            initialValue: attachment.name,
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
            tooltip: 'Remover anexo',
            icon: Icon(
              Icons.remove_circle_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                widget.attachments.value.remove(attachment);
              });
              widget.onChanged?.call();
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
        final date = await showAppDatePicker(
          context: context,
          initialDate: notifier.value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (mounted && date != null) {
          setState(() {
            notifier.value = date;
          });
          widget.onChanged?.call();
        }
      },
      borderRadius: AppBorders.borderRadiusM,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: notifier.value != null
              ? IconButton(
                  tooltip: 'Limpar $label',
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      notifier.value = null;
                    });
                    widget.onChanged?.call();
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
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
