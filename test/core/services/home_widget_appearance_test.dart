import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/design_system/colors/app_contrast.dart';
import 'package:key_budget/core/services/home_widget_appearance.dart';

void main() {
  const colors = [
    0xFF7C3AED,
    0xFFBE185D,
    0xFFB45309,
    0xFF475569,
    0xFF795548,
    0xFF0058D9,
    0xFF2563EB,
    0xFF15803D,
    0xFFB91C1C,
    0xFFC2410C,
    0xFF0E7490,
    0xFF4338CA,
    0xFF0F766E,
    0xFF9F1239,
    0xFFFFFFFF,
    0xFF000000,
    0x00000000,
  ];
  test('all theme palettes preserve opaque backgrounds and text contrast', () {
    for (final color in colors) {
      final appearance = HomeWidgetAppearance.toMap(colorValue: color);
      for (final mode in ['light', 'dark']) {
        final palette = appearance[mode]! as Map<String, int>;
        Color c(String key) => Color(palette[key]!);
        for (final value in palette.values) {
          expect(Color(value).a, 1, reason: '$color/$mode');
        }
        for (final text in ['foreground', 'secondary']) {
          expect(
            AppContrast.ratio(c(text), c('background')),
            greaterThanOrEqualTo(4.5),
            reason: '$color/$mode/$text',
          );
        }
        expect(
          AppContrast.ratio(c('on_button'), c('button')),
          greaterThanOrEqualTo(4.5),
          reason: '$color/$mode/button',
        );
      }
    }
  });

  test('mode validation and theme colors produce distinct palettes', () {
    expect(HomeWidgetAppearance.toMap(mode: 'invalid')['mode'], 'system');
    expect(HomeWidgetAppearance.toMap(mode: 'dark')['mode'], 'dark');
    expect(
      HomeWidgetAppearance.toMap(colorValue: colors.first),
      isNot(HomeWidgetAppearance.toMap(colorValue: colors.last)),
    );
  });

  test('native rendering fixtures use the production palette', () {
    final fixtures = {
      'violet': HomeWidgetAppearance.toMap(colorValue: 0xFF7C3AED),
      'teal': HomeWidgetAppearance.toMap(colorValue: 0xFF0F766E),
    };
    final file = File(
      'android/app/src/androidTest/assets/widget_palettes.json',
    );
    if (Platform.environment['UPDATE_WIDGET_PALETTES'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(fixtures)}\n',
      );
    }
    expect(jsonDecode(file.readAsStringSync()), fixtures);
  });
}
