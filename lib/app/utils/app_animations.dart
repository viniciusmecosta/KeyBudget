import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const Duration feedback = Duration(milliseconds: 120);
  static const Duration transition = Duration(milliseconds: 180);
  static const Duration major = Duration(milliseconds: 240);

  static const Duration duration = transition;
  static const Duration durationSlow = major;
  static const Duration durationFast = feedback;

  static const Curve curve = Curves.easeOutCubic;

  static bool isReducedMotion(BuildContext? context) {
    if (context == null) return false;
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  static Widget fadeInFromBottom(
    Widget child, {
    Key? key,
    Duration? delay,
    BuildContext? context,
  }) {
    if (isReducedMotion(context)) return child;
    return child
        .animate(key: key, delay: delay)
        .fadeIn(duration: transition, curve: curve)
        .slideY(begin: 0.05, end: 0, duration: transition, curve: curve);
  }

  static Widget scaleIn(
    Widget child, {
    Key? key,
    Duration? delay,
    BuildContext? context,
  }) {
    if (isReducedMotion(context)) return child;
    return child
        .animate(key: key, delay: delay)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: transition,
          curve: curve,
        )
        .fadeIn(duration: transition, curve: curve);
  }

  static Widget fadeIn(
    Widget child, {
    Key? key,
    Duration? delay,
    BuildContext? context,
  }) {
    if (isReducedMotion(context)) return child;
    return child
        .animate(key: key, delay: delay)
        .fadeIn(duration: transition, curve: curve);
  }

  static Widget listFadeIn(
    Widget child, {
    Key? key,
    required int index,
    int delayStep = 20,
    BuildContext? context,
  }) {
    if (isReducedMotion(context)) return child;
    final cappedDelay = Duration(milliseconds: (index.clamp(0, 10)) * delayStep);
    return child
        .animate(key: key, delay: cappedDelay)
        .fadeIn(duration: transition, curve: curve)
        .slideY(begin: 0.03, end: 0, duration: transition, curve: curve);
  }
}
