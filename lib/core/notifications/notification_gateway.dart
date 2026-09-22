import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PendingNotificationInfo {
  final int id;
  final String? title;
  final String? body;
  final String? payload;

  const PendingNotificationInfo({
    required this.id,
    this.title,
    this.body,
    this.payload,
  });
}

abstract class NotificationGateway {
  bool get isReady;
  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<List<PendingNotificationInfo>> getPendingNotifications();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAll();
}

class FlutterNotificationGateway implements NotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  FlutterNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  bool get isReady => _initialized;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final success = await _plugin.initialize(settings: initSettings);
      _initialized = success ?? false;
      return _initialized;
    } catch (e) {
      if (kDebugMode) {
        print('Degradação segura: Falha ao inicializar NotificationGateway: $e');
      }
      _initialized = false;
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PendingNotificationInfo>> getPendingNotifications() async {
    try {
      final list = await _plugin.pendingNotificationRequests();
      return list
          .map((req) => PendingNotificationInfo(
                id: req.id,
                title: req.title,
                body: req.body,
                payload: req.payload,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'recorrentes_channel',
        'Despesas Recorrentes',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao agendar notificação id=$id: $e');
      }
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

class FakeNotificationGateway implements NotificationGateway {
  bool initialized = true;
  bool permissionGranted = true;
  final Map<int, PendingNotificationInfo> pending = {};
  final List<String> callLog = [];

  @override
  bool get isReady => initialized;

  @override
  Future<bool> initialize() async {
    callLog.add('initialize');
    return initialized;
  }

  @override
  Future<bool> requestPermission() async {
    callLog.add('requestPermission');
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async {
    return permissionGranted;
  }

  @override
  Future<List<PendingNotificationInfo>> getPendingNotifications() async {
    callLog.add('getPendingNotifications');
    return pending.values.toList();
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    callLog.add('scheduleNotification:$id');
    pending[id] = PendingNotificationInfo(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    callLog.add('cancelNotification:$id');
    pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    callLog.add('cancelAll');
    pending.clear();
  }
}
