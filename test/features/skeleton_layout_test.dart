import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:passfin/features/analysis/view/analysis_screen.dart';
import 'package:passfin/features/category/view/categories_screen.dart';
import 'package:passfin/features/credentials/widgets/credentials_list_skeleton.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_skeleton.dart';
import 'package:passfin/features/documents/view/documents_screen.dart';
import 'package:passfin/features/expenses/widgets/expenses_list_skeleton.dart';
import 'package:passfin/features/suppliers/view/suppliers_screen.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'loading layouts fit a small phone and follow the chosen cards dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> show(Widget child) async {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.getTheme(isDark: dark),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: child!,
                ),
                home: Scaffold(body: child),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await show(
          const DashboardSkeleton(
            enableIncomesOverride: false,
            layout: DashboardLayout(cards: ['balance', 'recent'], actions: []),
          ),
        );
        expect(find.byKey(const ValueKey('skeleton_balance')), findsOneWidget);
        expect(find.byKey(const ValueKey('skeleton_recent')), findsOneWidget);
        expect(find.byKey(const ValueKey('skeleton_chart')), findsNothing);
        expect(
          find.byKey(const ValueKey('skeleton_quick_actions')),
          findsNothing,
        );
        for (final sliver in <Widget>[
          const ExpensesListSkeleton(),
          const CredentialsListSkeleton(),
          const DocumentsListSkeleton(),
          const SuppliersSkeleton(),
          const CategoriesSkeleton(),
        ]) {
          await show(CustomScrollView(slivers: [sliver]));
        }
        await show(const AnalysisSkeleton(enableIncomes: true));
        await show(const AnalysisSkeleton(enableIncomes: false));
      },
    );
  }
}
