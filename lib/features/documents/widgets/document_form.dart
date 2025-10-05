import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

class DocumentForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final ValueNotifier<DateTime?> issueDate;
  final ValueNotifier<DateTime?> expiryDate;
  final ValueNotifier<List<Map<String, String>>> additionalFields;
  final ValueNotifier<List<Attachment>> attachments;

  const DocumentForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.numberController,
    required this.issueDate,
    required this.expiryDate,
    required this.additionalFields,
    required this.attachments,
  });

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações Principais',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spaceL),
                  TextFormField(
                    controller: widget.nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nome do Documento *'),
                    validator: (value) =>
                        value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  TextFormField(
                    controller: widget.numberController,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _buildDatePicker(
                      context, 'Data de Expedição', widget.issueDate, true),
                  const SizedBox(height: AppTheme.spaceM),
                  _buildDatePicker(
                      context, 'Validade', widget.expiryDate, true),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campos Adicionais', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spaceS),
                  ..._buildAdditionalFields(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Campo'),
                      onPressed: () {
                        setState(() {
                          widget.additionalFields.value
                              .add({'name': '', 'value': ''});
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anexos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spaceM),
                  ..._buildAttachments(context),
                  if (viewModel.isUploading)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spaceS),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: viewModel.uploadProgress,
                            minHeight: 6,
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          Text(
                            'Enviando arquivo...',
                            style: theme.textTheme.bodySmall,
                          )
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Adicionar Anexo'),
                      onPressed: viewModel.isUploading
                          ? null
                          : () async {
                              final attachment =
                                  await viewModel.pickAndUploadFile();
                              if (attachment != null) {
                                setState(() {
                                  widget.attachments.value.add(attachment);
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdditionalFields() {
    return widget.additionalFields.value.map((field) {
      final index = widget.additionalFields.value.indexOf(field);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: field['name'],
                decoration: const InputDecoration(labelText: 'Nome'),
                onChanged: (value) {
                  widget.additionalFields.value[index]['name'] = value;
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: TextFormField(
                initialValue: field['value'],
                decoration: const InputDecoration(labelText: 'Valor'),
                onChanged: (value) {
                  widget.additionalFields.value[index]['value'] = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
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
    return widget.attachments.value.map((attachment) {
      final nameController = TextEditingController(text: attachment.name);
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withAlpha((255 * 0.2).round()),
          ),
        ),
        margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
        child: ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do anexo',
              border: InputBorder.none,
              filled: false,
            ),
            onChanged: (value) {
              attachment.name = value;
            },
          ),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
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
      BuildContext context, String label, ValueNotifier<DateTime?> notifier,
      [bool isOptional = false]) {
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
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isOptional && notifier.value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      notifier.value = null;
                    });
                  },
                )
              : null,
        ),
        child: Text(
          notifier.value == null
              ? 'Não definida'
              : DateFormat('dd/MM/yyyy').format(notifier.value!),
        ),
      ),
    );
  }
}
