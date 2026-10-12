import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

class AppFormPageBody extends StatelessWidget {
  final Widget form;
  final Widget action;

  const AppFormPageBody({super.key, required this.form, required this.action});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(child: form),
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: action),
            ],
          ),
        ),
      ),
    ),
  );
}
