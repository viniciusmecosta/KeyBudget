import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfBase64;
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfBase64,
    required this.pdfName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfName),
      ),
      body: SfPdfViewer.memory(
        base64Decode(pdfBase64),
      ),
    );
  }
}
