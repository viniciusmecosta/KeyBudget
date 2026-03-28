import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/utils/date_utils.dart' as app_date_utils;

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isAllPeriods;
  final ValueChanged<bool> onAllPeriodsChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.isAllPeriods,
    required this.onAllPeriodsChanged,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => _MonthPickerModal(
        initialMonth: selectedMonth,
        isAllPeriods: isAllPeriods,
        onMonthSelected: (month) {
          onAllPeriodsChanged(false);
          onMonthChanged(month);
        },
        onAllPeriodsSelected: () {
          onAllPeriodsChanged(true);
        },
      ),
    );
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
          color: theme.colorScheme.outline.withAlpha((255 * 0.08).round()),
        ),
      ),
      child: isAllPeriods
          ? InkWell(
              onTap: () => _showPicker(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Todo o Período',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme.primary),
                  ],
                ),
              ),
            )
          : Row(
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
                Expanded(
                  child: InkWell(
                    onTap: () => _showPicker(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            app_date_utils.DateUtils.formatMonthYear(
                                selectedMonth),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: theme.colorScheme.onSurface
                                .withAlpha((255 * 0.6).round()),
                          ),
                        ],
                      ),
                    ),
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

class _MonthPickerModal extends StatefulWidget {
  final DateTime initialMonth;
  final bool isAllPeriods;
  final ValueChanged<DateTime> onMonthSelected;
  final VoidCallback onAllPeriodsSelected;

  const _MonthPickerModal({
    required this.initialMonth,
    required this.isAllPeriods,
    required this.onMonthSelected,
    required this.onAllPeriodsSelected,
  });

  @override
  State<_MonthPickerModal> createState() => _MonthPickerModalState();
}

class _MonthPickerModalState extends State<_MonthPickerModal> {
  late int _selectedYear;
  late bool _isAllPeriods;

  final List<String> _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _isAllPeriods = widget.isAllPeriods;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Selecione o Período',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spaceL),
          InkWell(
            onTap: () {
              widget.onAllPeriodsSelected();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
              decoration: BoxDecoration(
                color: _isAllPeriods
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: _isAllPeriods
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline
                          .withAlpha((255 * 0.2).round()),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Todo o Período',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _isAllPeriods
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          const Divider(),
          const SizedBox(height: AppTheme.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _selectedYear--;
                  _isAllPeriods = false;
                }),
              ),
              Text(
                '$_selectedYear',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  _selectedYear++;
                  _isAllPeriods = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isSelected = !_isAllPeriods &&
                  _selectedYear == widget.initialMonth.year &&
                  index + 1 == widget.initialMonth.month;

              return InkWell(
                onTap: () {
                  widget.onMonthSelected(DateTime(_selectedYear, index + 1));
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline
                              .withAlpha((255 * 0.2).round()),
                    ),
                  ),
                  child: Text(
                    _months[index],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceL),
        ],
      ),
    );
  }
}
