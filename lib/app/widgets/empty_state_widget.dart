import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';

class EmptyStateWidget extends ConsumerWidget {
  final IconData icon;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppFeedbackPanel(
      title: message,
      message: '',
      icon: icon,
      type: AppFeedbackType.empty,
      actionLabel: buttonText,
      onAction: onButtonPressed,
    );
  }
}
