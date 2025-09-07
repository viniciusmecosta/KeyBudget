import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final bool isEditing;
  final Function(DateTime) onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.isEditing,
    required this.onDateSelected,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hoje';
    } else if (dateToCompare == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEditing ? () => _pickDate(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isEditing ? const Icon(Icons.calendar_today) : null,
        ),
        child: Text(
          _formatDate(selectedDate),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}
