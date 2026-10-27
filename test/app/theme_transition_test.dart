import 'package:flutter/material.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/utils/app_animations.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('theme transition respects reduced motion: $reduced', (
      tester,
    ) async {
      final color = ValueNotifier<Color>(Colors.blue);
      addTearDown(color.dispose);
      Color? rendered;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Builder(
            builder: (context) => ValueListenableBuilder<Color>(
              valueListenable: color,
              builder: (_, value, _) => MaterialApp(
                themeAnimationStyle: AppAnimations.themeStyle(context),
                theme: AppTheme.getTheme(
                  isDark: false,
                  colorValue: value.toARGB32(),
                ),
                home: Builder(
                  builder: (context) {
                    rendered = Theme.of(context).colorScheme.primary;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final before = rendered;
      final target = AppTheme.getTheme(
        isDark: false,
        colorValue: Colors.green.toARGB32(),
      ).colorScheme.primary;
      color.value = Colors.green;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 275));
      if (reduced) {
        expect(rendered, target);
      } else {
        expect(rendered, isNot(before));
        expect(rendered, isNot(target));
      }
      await tester.pumpAndSettle();
      expect(rendered, target);
    });
  }
}
