import 'package:key_budget/core/notifications/notification_gateway.dart';
import 'package:key_budget/core/notifications/notification_id_registry.dart';
import 'package:key_budget/core/notifications/notification_reconciler.dart';
import 'package:key_budget/core/time/app_clock.dart';

class NotificationService {
  static NotificationGateway _gateway = FlutterNotificationGateway();
  static NotificationIdRegistry _registry = NotificationIdRegistry();
  static NotificationReconciler _reconciler = NotificationReconciler(
    clock: const SystemAppClock(),
    gateway: _gateway,
    registry: _registry,
  );

  static Future<void>? _initFuture;

  static NotificationGateway get gateway => _gateway;
  static NotificationIdRegistry get registry => _registry;
  static NotificationReconciler get reconciler => _reconciler;

  static void setDependenciesForTesting({
    NotificationGateway? gateway,
    NotificationIdRegistry? registry,
    NotificationReconciler? reconciler,
  }) {
    if (gateway != null) _gateway = gateway;
    if (registry != null) _registry = registry;
    if (reconciler != null) {
      _reconciler = reconciler;
    } else {
      _reconciler = NotificationReconciler(
        clock: const SystemAppClock(),
        gateway: _gateway,
        registry: _registry,
      );
    }
  }

  static Future<void> initialize() {
    return _initFuture ??= _gateway.initialize();
  }

  static Future<bool> requestPermission() => _gateway.requestPermission();

  static Future<bool> hasPermission() => _gateway.hasPermission();

  static Future<void> scheduleExpenseNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    await _gateway.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9,
        0,
      ),
    );
  }
}
