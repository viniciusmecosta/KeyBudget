import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/design_system/widgets/app_text_field.dart';
import 'package:passfin/core/models/document_model.dart';
import 'package:passfin/features/documents/view/edit_document_screen.dart';
import 'package:passfin/features/documents/widgets/document_form.dart';

void main() {
  testWidgets('removing an additional field preserves the next field values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EditDocumentScreen(
            document: Document(
              id: 'document',
              documentName: 'CNH',
              additionalFields: {
                'Órgão': 'Detran',
                'Observação': 'Valor preservado',
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover campo').first);
    await tester.pumpAndSettle();
    expect(find.text('Detran'), findsNothing);
    expect(find.text('Valor preservado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'document edit uses two columns on tablet and keeps input on resize',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditDocumentScreen(
              document: Document(id: 'document', documentName: 'CNH'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(AppTextField);
      expect(
        tester.getSize(find.byType(DocumentForm)).width,
        lessThanOrEqualTo(760),
      );
      expect(
        tester.getTopLeft(fields.at(0)).dy,
        tester.getTopLeft(fields.at(1)).dy,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'CNH atualizada',
      );

      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(fields.at(0)).dy,
        lessThan(tester.getTopLeft(fields.at(1)).dy),
      );
      expect(find.text('CNH atualizada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
