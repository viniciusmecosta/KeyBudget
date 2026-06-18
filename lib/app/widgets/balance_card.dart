import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';

class BalanceCard extends ConsumerWidget {
  final String title;
  final double totalValue;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;

  const BalanceCard({
    super.key,
    required this.title,
    required this.totalValue,
    this.subtitle,
    this.onTap,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final bgColor = backgroundColor ??
        (gradient == null ? theme.colorScheme.surface : null);
    final textColor =
        (gradient != null || backgroundColor == theme.colorScheme.primary)
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        gradient: gradient,
        color: bgColor,
        border: bgColor == theme.colorScheme.surface
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: textColor.withAlpha((255 * 0.7).round()),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                          Text(
                            currencyFormatter.format(totalValue),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (gradient != null || backgroundColor != null)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceS),
                        decoration: BoxDecoration(
                          color: textColor.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  subtitle!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
