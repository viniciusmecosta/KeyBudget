import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';

void main() {
  testWidgets('image removal exposes a 48-pixel accessible target', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ImagePickerWidget(
                initialImagePath: 'invalid-image',
                onImageSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );

    final remove = find.bySemanticsLabel('Remover imagem');
    expect(remove, findsOneWidget);
    expect(tester.getSize(remove), const Size(48, 48));
    await tester.tap(remove);
    await tester.pump();
    expect(selected, '');
  });
}
