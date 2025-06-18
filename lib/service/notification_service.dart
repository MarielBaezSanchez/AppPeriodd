import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _service = NotificationService._internal();
  factory NotificationService() => _service;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init(Function(String?)? onNotificationClick) async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationClick?.call(response.payload);
      },
    );
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'period_channel',
      'Periodo',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleAt(DateTime dt, int id, String title, String body, {String? payload}) async {
    final tzDt = tz.TZDateTime.from(dt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDt,
      _details(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ requerido ahora
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> scheduleDaily(TimeOfDay time, int id, String title, String body, {String? payload}) async {
    final now = tz.TZDateTime.now(tz.local);
    var dt = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      dt,
      _details(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ requerido ahora
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
