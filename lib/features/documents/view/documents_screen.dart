import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/view/add_document_screen.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<DocumentViewModel>(context, listen: false)
            .listenToDocuments(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DocumentViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.documents.isEmpty
          ? EmptyStateWidget(
        icon: Icons.folder_off_outlined,
        message: 'Nenhum documento encontrado.',
        buttonText: 'Adicionar Documento',
        onButtonPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AddDocumentScreen())),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        itemCount: viewModel.documents.length,
        itemBuilder: (context, index) {
          final doc = viewModel.documents[index];
          return Card(
            child: ListTile(
              title: Text(doc.documentName),
              subtitle: doc.number != null ? Text(doc.number!) : null,
              trailing: doc.number != null
                  ? IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copiar número',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: doc.number!));
                  SnackbarService.showSuccess(
                      context, 'Número copiado!');
                },
              )
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DocumentDetailScreen(document: doc),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddDocumentScreen())),
        label: const Text('Adicionar Documento'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}