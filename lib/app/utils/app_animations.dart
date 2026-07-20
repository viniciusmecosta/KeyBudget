import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration duration = Duration(milliseconds: 400);

  static const Duration durationSlow = Duration(milliseconds: 1200);

  static const Duration durationFast = Duration(milliseconds: 200);

  static const Curve curve = Curves.easeOutCubic;

  static Animate fadeInFromBottom(Widget child, {Key? key, Duration? delay}) {
    return child
        .animate(key: key, delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .slideY(begin: 0.1, end: 0, duration: duration, curve: curve);
  }

  static Animate scaleIn(Widget child, {Key? key, Duration? delay}) {
    return child
        .animate(key: key, delay: delay)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: curve,
        )
        .fadeIn(duration: duration, curve: curve);
  }

  static Animate fadeIn(Widget child, {Key? key, Duration? delay}) {
    return child.animate(key: key, delay: delay).fadeIn(duration: duration, curve: curve);
  }

  static Animate listFadeIn(
    Widget child, {
    Key? key,
    required int index,
    int delayStep = 40,
  }) {
    return child
        .animate(key: key, delay: Duration(milliseconds: index * delayStep))
        .fadeIn(duration: duration, curve: curve)
        .slideY(begin: 0.05, end: 0, duration: duration, curve: curve);
  }
}
