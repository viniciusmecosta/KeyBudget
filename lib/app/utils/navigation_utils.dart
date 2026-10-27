import 'package:flutter/material.dart';
import 'package:passfin/app/utils/app_animations.dart';

class NavigationUtils {
  static Route<T> _buildRoute<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    final duration = AppAnimations.durationFor(context, AppAnimations.duration);

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final position = animation.drive(
          Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: AppAnimations.curve)),
        );
        return SlideTransition(position: position, child: child);
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_buildRoute<T>(context, page));
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(
      context,
    ).pushReplacement<T, TO>(_buildRoute<T>(context, page), result: result);
  }
}
