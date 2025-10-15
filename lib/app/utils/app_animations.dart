import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration duration = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeInOutCubic;

  static Animate fadeInFromBottom(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: duration,
          curve: curve,
        );
  }

  static Animate scaleIn(Widget child, {Duration? delay}) {
    return child.animate(delay: delay).scale(duration: duration, curve: curve);
  }

  static Animate fadeIn(Widget child, {Duration? delay}) {
    return child.animate(delay: delay).fadeIn(duration: duration, curve: curve);
  }

  static Animate listFadeIn(Widget child,
      {required int index, int delayStep = 50}) {
    return child
        .animate(delay: Duration(milliseconds: index * delayStep))
        .fadeIn(
          duration: duration,
          curve: curve,
        );
  }
}
