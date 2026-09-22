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
