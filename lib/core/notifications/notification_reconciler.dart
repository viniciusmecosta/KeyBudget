import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/features/expenses/domain/recurrence_schedule.dart';
import 'notification_gateway.dart';
import 'notification_id_registry.dart';

class DesiredNotification {
  final String logicalKey;
  final String uid;
  final String ruleId;
  final String scheduledDateKey;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
  final String fingerprint;

  const DesiredNotification({
    required this.logicalKey,
    required this.uid,
    required this.ruleId,
    required this.scheduledDateKey,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.fingerprint,
  });
}

class NotificationReconciler {
  final AppClock _clock;
  final NotificationGateway _gateway;
  final NotificationIdRegistry _registry;

  int _reconciliationGeneration = 0;
  String? _activeSessionUid;

  NotificationReconciler({
    required this._clock,
    required this._gateway,
    required this._registry,
  });

  AppClock get clock => _clock;
  NotificationGateway get gateway => _gateway;
  NotificationIdRegistry get registry => _registry;

  DateTime? findNextNotificationTime(RecurringExpense rule) {
    final now = _clock.now();
    DateTime? candidate = rule.startDate;

    while (candidate != null) {
      if (rule.endDate != null && candidate.isAfter(rule.endDate!)) {
        return null;
      }

      final notificationTime = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        9,
        0,
      );

      if (notificationTime.isAfter(now)) {
        return notificationTime;
      }

      candidate = RecurrenceSchedule.getNextCandidateDate(
        rule: rule,
        cursor: candidate,
      );
    }
    return null;
  }

  List<DesiredNotification> computeDesiredNotifications({
    required String uid,
    required List<RecurringExpense> activeRules,
  }) {
    final List<DesiredNotification> desired = [];
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final rule in activeRules) {
      if (rule.id == null || rule.id!.isEmpty) continue;

      if (rule.generationState == 'paused' ||
          rule.generationState == 'completed') {
        continue;
      }

      final scheduledAt = findNextNotificationTime(rule);
      if (scheduledAt == null) continue;

      final dateKey = dateFormat.format(scheduledAt);
      final logicalKey = '${uid}__${rule.id}__${dateKey}__expense_reminder';
      final title = 'Lembrete de Despesa';
      const body = 'Você tem uma despesa programada para hoje.';
      final payload = json.encode({
        'ruleId': rule.id,
        'version': 1,
        'action': 'open_recurring',
      });

      final fingerprint = '${rule.id}||${scheduledAt.toIso8601String()}';

      desired.add(
        DesiredNotification(
          logicalKey: logicalKey,
          uid: uid,
          ruleId: rule.id!,
          scheduledDateKey: dateKey,
          scheduledAt: scheduledAt,
          title: title,
          body: body,
          payload: payload,
          fingerprint: fingerprint,
        ),
      );
    }

    return desired;
  }

  Future<void> reconcile({
    required String uid,
    required List<RecurringExpense> activeRules,
  }) async {
    final int generation = ++_reconciliationGeneration;
    _activeSessionUid = uid;

    try {
      final desiredList = computeDesiredNotifications(
        uid: uid,
        activeRules: activeRules,
      );
      final Map<String, DesiredNotification> desiredMap = {
        for (final d in desiredList) d.logicalKey: d,
      };

      final existingEntries = _registry.getEntriesForUid(uid);

      for (final entry in existingEntries) {
        if (!desiredMap.containsKey(entry.logicalKey)) {
          await _gateway.cancelNotification(entry.nativeId);
          await _registry.removeByLogicalKey(entry.logicalKey);
        }
      }

      if (generation != _reconciliationGeneration || _activeSessionUid != uid) {
        return;
      }

      final pendingNative = await _gateway.getPendingNotifications();
      final pendingNativeIds = pendingNative.map((p) => p.id).toSet();

      for (final desired in desiredList) {
        if (generation != _reconciliationGeneration ||
            _activeSessionUid != uid) {
          return;
        }

        final existing = _registry.getEntry(desired.logicalKey);

        if (existing != null) {
          final bool fingerprintChanged =
              existing.fingerprint != desired.fingerprint;
          final bool missingFromNative = !pendingNativeIds.contains(
            existing.nativeId,
          );

          if (fingerprintChanged || missingFromNative) {
            await _gateway.scheduleNotification(
              id: existing.nativeId,
              title: desired.title,
              body: desired.body,
              scheduledDate: desired.scheduledAt,
              payload: desired.payload,
            );
            await _registry.getOrAllocate(
              logicalKey: desired.logicalKey,
              uid: uid,
              ruleId: desired.ruleId,
              scheduledDateKey: desired.scheduledDateKey,
              fingerprint: desired.fingerprint,
              scheduledAt: desired.scheduledAt,
            );
          }
        } else {
          final newEntry = await _registry.getOrAllocate(
            logicalKey: desired.logicalKey,
            uid: uid,
            ruleId: desired.ruleId,
            scheduledDateKey: desired.scheduledDateKey,
            fingerprint: desired.fingerprint,
            scheduledAt: desired.scheduledAt,
          );

          await _gateway.scheduleNotification(
            id: newEntry.nativeId,
            title: desired.title,
            body: desired.body,
            scheduledDate: desired.scheduledAt,
            payload: desired.payload,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro durante reconciliação de notificações: $e');
      }
    }
  }

  Future<void> cancelAllForSession(String uid) async {
    _reconciliationGeneration++;
    _activeSessionUid = null;
    try {
      final entries = _registry.getEntriesForUid(uid);
      for (final entry in entries) {
        await _gateway.cancelNotification(entry.nativeId);
      }
      await _registry.removeEntriesForUid(uid);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao cancelar notificações da sessão $uid: $e');
      }
    }
  }
}
