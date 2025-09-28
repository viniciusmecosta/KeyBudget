import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';

class EmptyChartStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyChartStateWidget({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withAlpha((255 * 0.6).round()),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Suas transações aparecerão aqui assim que forem registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
            ),
          ),
        ],
      ),
    );
  }
}
