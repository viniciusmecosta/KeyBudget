import 'package:flutter/material.dart';

class AppContrast {
  static double ratio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance < secondLuminance
        ? firstLuminance
        : secondLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color foregroundOn(Color background) {
    return ratio(Colors.black, background) >= ratio(Colors.white, background)
        ? Colors.black
        : Colors.white;
  }

  static Color primaryWithWhiteText(Color primary) {
    var adjusted = primary.withAlpha(255);
    for (
      var step = 0;
      step < 24 && ratio(Colors.white, adjusted) < 4.5;
      step++
    ) {
      adjusted = Color.lerp(adjusted, Colors.black, 0.08)!;
    }
    return adjusted;
  }

  static Color accentOnSurface(
    Color accent,
    Color surface, {
    required bool isDark,
  }) {
    final target = isDark ? Colors.white : Colors.black;
    var adjusted = accent.withAlpha(255);
    for (var step = 0; step < 20 && ratio(adjusted, surface) < 4.5; step++) {
      adjusted = Color.lerp(adjusted, target, 0.1)!;
    }
    return adjusted;
  }
}
