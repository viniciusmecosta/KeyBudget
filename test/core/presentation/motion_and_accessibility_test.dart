import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/presentation/state_view.dart';

void main() {
  group('AppAnimations Reduced Motion & Tokens', () {
    testWidgets('respects disableAnimations and returns child directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                return AppAnimations.fadeInFromBottom(
                  const Text('Test Child'),
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(Animate), findsNothing);
    });

    testWidgets('animates child when disableAnimations is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: Builder(
              builder: (context) {
                return AppAnimations.fadeInFromBottom(
                  const Text('Animated Child'),
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Animated Child'), findsOneWidget);
      expect(find.byType(Animate), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('StateView Presentation Matrix', () {
    testWidgets('renders initialLoading with semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StateView(state: ViewStateKind.initialLoading),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando informações'), findsOneWidget);
    });

    testWidgets('renders emptyAccount with custom action', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StateView(
              state: ViewStateKind.emptyAccount,
              emptyTitle: 'Nenhuma despesa',
              emptyActionLabel: 'Criar despesa',
              onEmptyAction: () => actionFired = true,
            ),
          ),
        ),
      );

      expect(find.text('Nenhuma despesa'), findsOneWidget);
      expect(find.text('Criar despesa'), findsOneWidget);
      await tester.tap(find.text('Criar despesa'));
      expect(actionFired, isTrue);
    });

    testWidgets('renders emptyFilter with clear filters action', (tester) async {
      bool cleared = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StateView(
              state: ViewStateKind.emptyFilter,
              onEmptyAction: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('Limpar filtros'), findsOneWidget);
      await tester.tap(find.text('Limpar filtros'));
      expect(cleared, isTrue);
    });

    testWidgets('renders errorWithData banner preserving existing content', (tester) async {
      bool reloaded = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StateView(
              state: ViewStateKind.errorWithData,
              content: const Text('Preserved Data List'),
              onRetry: () => reloaded = true,
            ),
          ),
        ),
      );

      expect(find.text('Preserved Data List'), findsOneWidget);
      expect(find.text('Dados desatualizados. Toque para recarregar.'), findsOneWidget);
      expect(find.text('Recarregar'), findsOneWidget);
      await tester.tap(find.text('Recarregar'));
      expect(reloaded, isTrue);
    });

    testWidgets('renders offline state with retry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StateView(state: ViewStateKind.offline),
          ),
        ),
      );

      expect(find.text('Sem conexão com a internet'), findsOneWidget);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('renders icon and message and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.search_off,
              message: 'Nada aqui',
              buttonText: 'Tentar de novo',
              onButtonPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Nada aqui'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      expect(tapped, isTrue);
    });
  });
}
