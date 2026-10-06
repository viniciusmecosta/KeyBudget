import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/constants/app_icons.dart';
import 'package:key_budget/features/category/widgets/icon_picker_widget.dart';

void main() {
  test('every category icon has a descriptive accessible name', () {
    expect(AppIcons.labels, hasLength(AppIcons.all.length));
    expect(AppIcons.labels.every((label) => label.trim().isNotEmpty), isTrue);
  });

  testWidgets('icon picker exposes name and selected state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: IconPickerWidget(selectedIcon: Icons.restaurant)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Ícone de Restaurante'), findsOneWidget);
    final selected = tester.getSemantics(
      find.bySemanticsLabel('Ícone de Restaurante'),
    );
    expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(
      selected.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
}
