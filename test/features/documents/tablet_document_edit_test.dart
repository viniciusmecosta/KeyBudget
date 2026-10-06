import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/view/edit_document_screen.dart';
import 'package:key_budget/features/documents/widgets/document_form.dart';

void main() {
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
