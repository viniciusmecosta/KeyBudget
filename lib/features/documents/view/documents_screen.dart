import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/view/add_document_screen.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/document_list_tile.dart';

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
              ? const EmptyStateWidget(
                  icon: Icons.folder_off_outlined,
                  message: 'Nenhum documento encontrado.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppTheme.defaultPadding,
                      AppTheme.defaultPadding, AppTheme.defaultPadding, 96.0),
                  itemCount: viewModel.documents.length,
                  itemBuilder: (context, index) {
                    final doc = viewModel.documents[index];
                    return DocumentListTile(doc: doc);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            NavigationUtils.push(context, const AddDocumentScreen()),
        label: const Text('Novo Documento'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
