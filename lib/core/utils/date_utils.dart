import 'package:intl/intl.dart';

class DateUtils {
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));
    final expenseDate = DateTime(date.year, date.month, date.day);

    final daysDifference = today.difference(expenseDate).inDays;

    if (daysDifference < 0) {
      return DateFormat('dd').format(date);
    }

    if (expenseDate == today) {
      return 'Hoje';
    } else if (expenseDate == yesterday) {
      return 'Ontem';
    } else if (expenseDate == dayBeforeYesterday) {
      return 'Anteontem';
    } else if (daysDifference <= 30) {
      final day = DateFormat('dd').format(date);
      return '$daysDifference dias atrás • $day';
    } else {
      return DateFormat('dd').format(date);
    }
  }

  static String formatMonthYear(DateTime date) {
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
}
