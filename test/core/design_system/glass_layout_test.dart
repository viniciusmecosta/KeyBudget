import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../../app/navigation/navigation_test.dart' show FakeAuthVM;

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets(
        'glass navigation preserves six accessible targets $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final handle = tester.ensureSemantics();
          final navigation = NavigationViewModel()
            ..updateSuppliersAvailability(true);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authViewModelProvider.overrideWith(
                  (ref) => FakeAuthVM(suppliersEnabled: true),
                ),
                navigationViewModelProvider.overrideWith((ref) => navigation),
              ],
              child: MaterialApp(
                theme: AppTheme.getTheme(isDark: dark),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: const Scaffold(
                  bottomNavigationBar: MainBottomNavigationBar(),
                ),
              ),
            ),
          );
          final tops = <double>[];
          for (final destination in AppDestination.values) {
            final label = destination == AppDestination.expenses
                ? 'Despesas'
                : destination.label;
            final finder = find.bySemanticsLabel(label);
            expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
            tops.add(tester.getTopLeft(finder).dy);
            final node = tester.getSemantics(finder);
            expect(
              node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
              isTrue,
            );
          }
          expect(tops.toSet(), hasLength(1));
          tester.binding.performSemanticsAction(
            ui.SemanticsActionEvent(
              nodeId: tester
                  .getSemantics(find.bySemanticsLabel('Fornecedores'))
                  .id,
              type: ui.SemanticsAction.tap,
              viewId: tester.view.viewId,
            ),
          );
          await tester.pump();
          expect(navigation.currentDestination, AppDestination.suppliers);
          expect(tester.takeException(), isNull);
          handle.dispose();
        },
      );
    }
  }
}
