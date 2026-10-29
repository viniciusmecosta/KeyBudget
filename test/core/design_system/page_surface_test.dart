import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:passfin/core/design_system/widgets/app_feedback_panel.dart';
import 'package:passfin/core/design_system/widgets/app_loading_shimmer.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:passfin/features/auth/view/login_screen.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';

import '../../features/auth/auth_test.dart' show FakeAuthRepository;

void main() {
  testWidgets(
    'page retains editing state across tablet resize and theme changes',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> render(Size size, bool dark) async {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme(isDark: dark),
            home: AppPageScaffold(
              maxContentWidth: 760,
              body: ListView(children: [TextField(controller: controller)]),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(const Size(390, 844), false);
      await tester.enterText(find.byType(TextField), 'Rascunho preservado');
      final state = tester.state(find.byType(TextField));
      await render(const Size(1024, 768), true);
      expect(identical(state, tester.state(find.byType(TextField))), isTrue);
      expect(controller.text, 'Rascunho preservado');
      expect(tester.getSize(find.byType(TextField)).width, 760);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'login remains scrollable with large text and keyboard dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authViewModelProvider.overrideWith(
                (ref) => AuthViewModel(
                  authRepository: FakeAuthRepository(),
                  listenToAuthChanges: false,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.getTheme(isDark: dark),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final password = find.byType(TextFormField).last;
        await tester.ensureVisible(password);
        await tester.enterText(password, 'senha de teste');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<TextFormField>(password).controller!.text,
          'senha de teste',
        );
      },
    );
  }

  testWidgets('feedback fits landscape and loading respects reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppPageScaffold(
          body: AppFeedbackPanel(
            title: 'Não foi possível carregar os dados',
            message: 'Confira sua conexão e tente novamente.',
            actionLabel: 'Tentar novamente',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const AppLoadingShimmer(
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
