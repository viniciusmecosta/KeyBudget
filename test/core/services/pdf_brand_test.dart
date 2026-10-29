import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/credential_model.dart';
import 'package:passfin/core/services/pdf_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  testWidgets(
    'credential report contains its heading and data after branding',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold();
            },
          ),
        ),
      );
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const share = MethodChannel('dev.fluttercommunity.plus/share');
      final messenger = tester.binding.defaultBinaryMessenger;
      final directory = Directory.systemTemp.createTempSync('passfin-pdf-');
      messenger.setMockMethodCallHandler(paths, (_) async => directory.path);
      messenger.setMockMethodCallHandler(share, (_) async => 'test');
      addTearDown(() {
        messenger.setMockMethodCallHandler(paths, null);
        messenger.setMockMethodCallHandler(share, null);
        directory.deleteSync(recursive: true);
      });
      await tester.runAsync(() async {
        await PdfService().exportCredentialsPdf(context, [
          Credential(
            id: 'example',
            location: 'Servico demonstrativo',
            login: 'usuario.exemplo',
            encryptedPassword: 'unused-test-data',
          ),
        ], (_) => 'senha-ficticia');
        final files = directory.listSync().whereType<File>().toList();
        expect(files, hasLength(1));
        final document = PdfDocument(
          inputBytes: files.single.readAsBytesSync(),
        );
        try {
          expect(document.pages.count, 1);
          final text = PdfTextExtractor(
            document,
          ).extractText().replaceAll(RegExp(r'\s+'), ' ');
          expect(text, contains('Relatório de Credenciais'));
          expect(text, contains('Servico demonstrativo'));
          expect(text, contains('usuario.exemplo'));
        } finally {
          document.dispose();
        }
      });
      await tester.pump();
      expect(find.text('Erro Exportação PDF'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
