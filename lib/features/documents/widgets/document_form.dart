import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController numeroController;
  final ValueNotifier<DateTime?> dataExpedicao;
  final ValueNotifier<DateTime?> validade;
  final ValueNotifier<List<Map<String, String>>> camposAdicionais;
  final ValueNotifier<List<Anexo>> anexos;

  const DocumentForm({
    super.key,
    required this.formKey,
    required this.nomeController,
    required this.numeroController,
    required this.dataExpedicao,
    required this.validade,
    required this.camposAdicionais,
    required this.anexos,
  });

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);
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
                    controller: widget.nomeController,
                    decoration:
                        const InputDecoration(labelText: 'Nome do Documento *'),
                    validator: (value) =>
                        value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  TextFormField(
                    controller: widget.numeroController,
                    decoration: const InputDecoration(labelText: 'Número *'),
                    validator: (value) =>
                        value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _buildDatePicker(
                      context, 'Data de Expedição', widget.dataExpedicao, true),
                  const SizedBox(height: AppTheme.spaceM),
                  _buildDatePicker(context, 'Validade', widget.validade, true),
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
                  ..._buildCamposAdicionais(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Campo'),
                      onPressed: () {
                        setState(() {
                          widget.camposAdicionais.value
                              .add({'nome': '', 'valor': ''});
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
                  ..._buildAnexos(viewModel),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Adicionar Anexo'),
                      onPressed: () async {
                        final anexo = await viewModel.pickAndConvertFile();
                        if (anexo != null) {
                          setState(() {
                            widget.anexos.value.add(anexo);
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

  List<Widget> _buildCamposAdicionais() {
    return widget.camposAdicionais.value.map((campo) {
      final index = widget.camposAdicionais.value.indexOf(campo);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: campo['nome'],
                decoration: const InputDecoration(labelText: 'Nome'),
                onChanged: (value) {
                  widget.camposAdicionais.value[index]['nome'] = value;
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: TextFormField(
                initialValue: campo['valor'],
                decoration: const InputDecoration(labelText: 'Valor'),
                onChanged: (value) {
                  widget.camposAdicionais.value[index]['valor'] = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  widget.camposAdicionais.value.removeAt(index);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAnexos(DocumentViewModel viewModel) {
    return widget.anexos.value.map((anexo) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceS),
          child: Column(
            children: [
              ListTile(
                title: Text(anexo.nome, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      widget.anexos.value.remove(anexo);
                    });
                  },
                ),
              ),
              if (anexo.tipo.contains('pdf'))
                SizedBox(
                  height: 200,
                  child: SfPdfViewer.memory(base64Decode(anexo.base64)),
                )
              else
                Image.memory(
                  base64Decode(anexo.base64),
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
            ],
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
