import 'package:key_budget/core/design_system/widgets/app_status_badge.dart';

class DocumentExpiryInfo {
  final String label;
  final AppBadgeVariant variant;

  const DocumentExpiryInfo({
    required this.label,
    required this.variant,
  });
}

class DocumentExpiryHelper {
  static DocumentExpiryInfo calculate(DateTime? expiryDate, {DateTime? referenceDate}) {
    if (expiryDate == null) {
      return const DocumentExpiryInfo(
        label: 'Validade não informada',
        variant: AppBadgeVariant.neutral,
      );
    }

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final diff = expiryDay.difference(today).inDays;

    if (diff < 0) {
      return const DocumentExpiryInfo(
        label: 'Vencido',
        variant: AppBadgeVariant.error,
      );
    } else if (diff == 0) {
      return const DocumentExpiryInfo(
        label: 'Vence hoje',
        variant: AppBadgeVariant.warning,
      );
    } else if (diff <= 30) {
      return DocumentExpiryInfo(
        label: 'Vence em $diff ${diff == 1 ? "dia" : "dias"}',
        variant: AppBadgeVariant.warning,
      );
    } else {
      final day = expiryDate.day.toString().padLeft(2, '0');
      final month = expiryDate.month.toString().padLeft(2, '0');
      final year = expiryDate.year.toString();
      return DocumentExpiryInfo(
        label: 'Validade: $day/$month/$year',
        variant: AppBadgeVariant.neutral,
      );
    }
  }
}
