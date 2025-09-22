import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  String _formatMonthYear(DateTime date) {
    final now = DateTime.now();
    String formattedDate;

    if (date.year == now.year) {
      formattedDate = DateFormat.MMMM('pt_BR').format(date);
    } else {
      formattedDate = DateFormat.yMMMM('pt_BR').format(date);
    }
    return formattedDate.isNotEmpty
        ? formattedDate[0].toUpperCase() + formattedDate.substring(1)
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.defaultPadding, vertical: AppTheme.spaceS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceS, vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              onMonthChanged(
                  DateTime(selectedMonth.year, selectedMonth.month - 1));
            },
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            _formatMonthYear(selectedMonth),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              onMonthChanged(
                  DateTime(selectedMonth.year, selectedMonth.month + 1));
            },
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
