import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/design_system/colors/app_contrast.dart';
import 'package:key_budget/core/design_system/theme/app_semantic_colors.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/design_system/widgets/app_section_header.dart';
import 'package:key_budget/core/design_system/widgets/app_status_badge.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';

void main() {
  group('AppTheme & Semantic Colors', () {
    test('keeps custom accents and their labels readable in both themes', () {
      for (final isDark in [false, true]) {
        for (final seed in <int?>[null, 0xFF0D47A1, 0xFFFFEB3B, 0xFF9F1239, 0xFF0F766E]) {
          final scheme = AppTheme.getTheme(isDark: isDark, colorValue: seed).colorScheme;
          expect(AppContrast.ratio(scheme.primary, scheme.surface), greaterThanOrEqualTo(4.5));
          expect(AppContrast.ratio(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('theme swatches match the effective accent in both modes', () {
      for (final isDark in [false, true]) {
        for (final color in [0xFF1E40AF, 0xFF15803D, 0xFF9F1239]) {
          expect(
            AppTheme.effectivePrimary(isDark: isDark, colorValue: color),
            AppTheme.getTheme(isDark: isDark, colorValue: color).colorScheme.primary,
          );
        }
      }
    });

    test('primary filled surfaces keep white labels legible', () {
      for (final isDark in [false, true]) {
        for (final seed in <int?>[null, 0xFF0D47A1, 0xFFFFEB3B, 0xFF9F1239, 0xFF0F766E, 0xFFB3A2F0]) {
          final theme = AppTheme.getTheme(isDark: isDark, colorValue: seed);
          final background = AppContrast.primaryWithWhiteText(theme.colorScheme.primary);
          expect(AppContrast.ratio(Colors.white, background), greaterThanOrEqualTo(4.5));
          expect(theme.floatingActionButtonTheme.backgroundColor, background);
          expect(theme.floatingActionButtonTheme.foregroundColor, Colors.white);
        }
      }
    });

    test('exposes AppSemanticColors via ThemeExtension', () {
      final lightTheme = AppTheme.lightTheme;
      final semanticLight = lightTheme.extension<AppSemanticColors>();
      expect(semanticLight, isNotNull);
      expect(semanticLight!.success, isNotNull);

      final darkTheme = AppTheme.darkTheme;
      final semanticDark = darkTheme.extension<AppSemanticColors>();
      expect(semanticDark, isNotNull);
    });
  });

  group('AppButton', () {
    testWidgets('uses white text on a light custom primary color', (tester) async {
      final theme = AppTheme.getTheme(isDark: true, colorValue: 0xFFB3A2F0);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(body: AppButton(label: 'Salvar', onPressed: () {})),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style!.foregroundColor!.resolve({}), Colors.white);
      expect(AppContrast.ratio(
        Colors.white,
        button.style!.backgroundColor!.resolve({})!,
      ), greaterThanOrEqualTo(4.5));
    });

    testWidgets('renders primary button and fires onPressed', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Salvar',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Salvar'), findsOneWidget);
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('shows spinner with appropriate variant color on loading and disables tap', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Excluir',
              variant: AppButtonVariant.outline,
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, AppTheme.lightTheme.colorScheme.primary);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(pressed, isFalse);
    });
  });

  group('AppTextField', () {
    testWidgets('renders with autofillHints and label', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'E-mail',
              autofillHints: const [AutofillHints.email],
            ),
          ),
        ),
      );

      expect(find.text('E-mail'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });
  });

  group('AppStatusBadge & AppSectionHeader', () {
    testWidgets('renders status badge with variant colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppStatusBadge(
              label: 'Agendado',
              icon: Icons.calendar_today,
              variant: AppBadgeVariant.info,
            ),
          ),
        ),
      );

      expect(find.text('Agendado'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renders section header with responsive action', (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Resumo Mensal',
              subtitle: 'Valores consolidados',
              action: TextButton(
                onPressed: () => actionTapped = true,
                child: const Text('Ver tudo'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Resumo Mensal'), findsOneWidget);
      expect(find.text('Valores consolidados'), findsOneWidget);
      expect(find.text('Ver tudo'), findsOneWidget);
      await tester.tap(find.text('Ver tudo'));
      expect(actionTapped, isTrue);
    });

    testWidgets('keeps the analysis action inline at dashboard card width', (tester) async {
      tester.view.physicalSize = const Size(329, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Gastos Mensais',
              subtitle: 'Últimos 4 meses',
              keepActionInline: true,
              action: TextButton(
                onPressed: () {},
                child: const Text('Ver análise', maxLines: 1, softWrap: false),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Gastos Mensais'), findsOneWidget);
      expect(find.text('Ver análise'), findsOneWidget);
      final action = tester.getRect(find.text('Ver análise'));
      final title = tester.getRect(find.text('Gastos Mensais'));
      expect(action.center.dy, lessThan(title.bottom + 8));
    });
  });

  group('AppFeedbackPanel', () {
    testWidgets('renders empty feedback panel with optional action', (tester) async {
      bool retryClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppFeedbackPanel(
              title: 'Nenhum item',
              message: 'Não há registros cadastrados.',
              type: AppFeedbackType.empty,
              actionLabel: 'Criar registro',
              onAction: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Nenhum item'), findsOneWidget);
      expect(find.text('Não há registros cadastrados.'), findsOneWidget);
      expect(find.text('Criar registro'), findsOneWidget);
      await tester.tap(find.text('Criar registro'));
      expect(retryClicked, isTrue);
    });
  });
}
