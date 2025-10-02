import 'dart:io';

import 'package:flutter/material.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FileViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const FileViewerScreen(
      {super.key, required this.filePath, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final isPdf = filePath.toLowerCase().endsWith('.pdf');
    final isImage = filePath.toLowerCase().endsWith('.png') ||
        filePath.toLowerCase().endsWith('.jpg') ||
        filePath.toLowerCase().endsWith('.jpeg');

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar ou Salvar',
            onPressed: () async {
              try {
                await Share.shareXFiles([XFile(filePath)], text: fileName);
              } catch (e) {
                if (context.mounted) {
                  SnackbarService.showError(
                      context, "Não foi possível compartilhar o arquivo.");
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: isPdf
            ? SfPdfViewer.file(File(filePath))
            : isImage
            ? Image.file(File(filePath))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
                'Formato de arquivo não suportado para visualização.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir com...'),
              onPressed: () async {
                try {
                  await Share.shareXFiles([XFile(filePath)],
                      text: fileName);
                } catch (e) {
                  if (context.mounted) {
                    SnackbarService.showError(context,
                        "Não foi possível abrir o arquivo.");
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }
}