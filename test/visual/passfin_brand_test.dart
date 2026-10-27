import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/design_system/widgets/passfin_brand.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../features/auth/auth_test.dart' show FakeAuthRepository;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
          'packages/font_awesome_flutter/FontAwesomeBrands',
        )..addFont(
          rootBundle.load(
            'packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf',
          ),
        ))
        .load();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf')))
        .load();
  });

  for (final dark in [false, true]) {
    testWidgets('PassFin login assets and mobile layout, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final boundary = GlobalKey();
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
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.getTheme(isDark: dark),
                home: const LoginScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final brandContext = tester.element(find.byType(PassFinBrand));
        await tester.runAsync(
          () => precacheImage(
            AssetImage(
              'assets/brand/passfin-signature-${dark ? "dark" : "light"}.png',
            ),
            brandContext,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PassFinBrand), findsOneWidget);
        final rawImage = tester.widget<RawImage>(find.byType(RawImage).first);
        expect(rawImage.image, isNotNull);
        expect(find.bySemanticsLabel('PassFin'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, dark ? Colors.black : Colors.white);
        if (const bool.fromEnvironment('CAPTURE_BRAND')) {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              'docs/branding/login-${dark ? "dark" : "light"}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      } finally {
        semantics.dispose();
      }
    });
  }
}
