import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:passfin/app/utils/app_animations.dart';

class AppLoadingShimmer extends StatelessWidget {
  final Widget child;

  const AppLoadingShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) return child;
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: Theme.of(context).colorScheme.surface,
        );
  }
}
