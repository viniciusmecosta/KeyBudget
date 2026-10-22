import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/utils/app_animations.dart';

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
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: value),
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
      final target = ColorScheme.fromSeed(seedColor: Colors.green).primary;
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
