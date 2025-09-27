import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:convert';

class DocumentForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController numeroController;
  final ValueNotifier<DateTime?> dataExpedicao;
  final ValueNotifier<DateTime?> validade;
  final ValueNotifier<List<Map<String, String>>> camposAdicionais;
  final ValueNotifier<List<Anexo>> anexos;
  final Document? documentoPai;
  final List<Document> allDocuments;
  final Function(Document?) onDocumentoPaiChanged;

  const DocumentForm({
    super.key,
    required this.formKey,
    required this.nomeController,
    required this.numeroController,
    required this.dataExpedicao,
    required this.validade,
    required this.camposAdicionais,
    required this.anexos,
    required this.allDocuments,
    this.documentoPai,
    required this.onDocumentoPaiChanged,
  });

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DocumentViewModel>(context, listen: false);

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: widget.nomeController,
            decoration: const InputDecoration(labelText: 'Nome do Documento *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.numeroController,
            decoration: const InputDecoration(labelText: 'Número *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildDatePicker(context, 'Data de Expedição', widget.dataExpedicao,
              isOptional: true),
          const SizedBox(height: 16),
          _buildDatePicker(context, 'Validade', widget.validade,
              isOptional: true),
          const SizedBox(height: 16),
          DropdownButtonFormField<Document>(
            value: widget.documentoPai,
            decoration:
            const InputDecoration(labelText: 'Documento Associado (Anterior)'),
            items: widget.allDocuments
                .map((doc) => DropdownMenuItem(
              value: doc,
              child: Text(doc.nomeDocumento),
            ))
                .toList(),
            onChanged: (value) {
              widget.onDocumentoPaiChanged(value);
            },
          ),
          const SizedBox(height: 24),
          Text('Campos Adicionais',
              style: Theme.of(context).textTheme.titleLarge),
          ...widget.camposAdicionais.value.map((campo) {
            final index = widget.camposAdicionais.value.indexOf(campo);
            return Row(
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
                const SizedBox(width: 8),
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
            );
          }).toList(),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Campo'),
            onPressed: () {
              setState(() {
                widget.camposAdicionais.value.add({'nome': '', 'valor': ''});
              });
            },
          ),
          const SizedBox(height: 24),
          Text('Anexos', style: Theme.of(context).textTheme.titleLarge),
          ...widget.anexos.value.map((anexo) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(anexo.nome),
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
                      Image.memory(base64Decode(anexo.base64),
                          height: 150, fit: BoxFit.cover),
                  ],
                ),
              ),
            );
          }).toList(),
          TextButton.icon(
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
        ],
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, String label, ValueNotifier<DateTime?> notifier,
      {bool isOptional = false}) {
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