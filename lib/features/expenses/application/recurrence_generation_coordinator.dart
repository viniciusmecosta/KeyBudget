import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/notification_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_service.dart';

class RecurrenceGenerationCoordinator {
  final RecurrenceService recurrenceService;
  final Future<void> Function(String, List<RecurringExpense>)
  reconcileNotifications;
  final Set<String> _running = {};

  RecurrenceGenerationCoordinator({
    required this.recurrenceService,
    Future<void> Function(String, List<RecurringExpense>)?
    reconcileNotifications,
  }) : reconcileNotifications = reconcileNotifications ?? _reconcile;

  static Future<void> _reconcile(String userId, List<RecurringExpense> rules) =>
      NotificationService.reconciler.reconcile(uid: userId, activeRules: rules);

  Future<void> synchronize(String userId, List<RecurringExpense> rules) async {
    if (!_running.add(userId)) return;
    try {
      final result = await recurrenceService.generatePendingOccurrences(
        userId,
        rulesToProcess: List.of(rules),
      );
      if (result.isSuccess) {
        await reconcileNotifications(userId, List.of(rules));
      }
    } finally {
      _running.remove(userId);
    }
  }
}
