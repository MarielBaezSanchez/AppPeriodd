import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PeriodService {
  static final PeriodService _instance = PeriodService._internal();
  factory PeriodService() => _instance;
  PeriodService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _prefsCycleLengthsKey = 'cycleLengths';
  static const String _prefsLastPeriodDateKey = 'lastPeriodDate';

  /// Inicializa el plugin de notificaciones locales
  Future<void> initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Inicializa zonas horarias
    tz.initializeTimeZones();
  }

  /// Guarda la fecha del último periodo localmente (en formato ISO 8601)
  Future<void> saveLastPeriodDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastPeriodDateKey, date.toIso8601String());
  }

  /// Obtiene la fecha del último periodo guardada localmente
  Future<DateTime?> getLastPeriodDate() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_prefsLastPeriodDateKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Guarda la lista de duraciones de ciclo (en días) para cálculo de promedio
  Future<void> saveCycleLengths(List<int> lengths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsCycleLengthsKey, lengths.map((e) => e.toString()).toList());
  }

  /// Obtiene la lista de duraciones de ciclo guardadas localmente
  Future<List<int>> getCycleLengths() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsCycleLengthsKey);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 28).toList();
  }

  /// Calcula la duración promedio del ciclo menstrual
  double getAverageCycleLength(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 28.0; // Valor por defecto comúnmente usado
    return cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
  }

  /// Calcula la fecha estimada para el próximo periodo según fecha última y duración promedio
  DateTime? predictNextPeriodDate(DateTime? lastPeriodDate, double averageCycleLength) {
    if (lastPeriodDate == null) return null;
    return lastPeriodDate.add(Duration(days: averageCycleLength.round()));
  }

  /// Programa notificaciones locales para días previos y día estimado del próximo periodo
  Future<void> schedulePeriodNotifications(DateTime predictedPeriodDate) async {
    // Cancelar notificaciones previas para evitar duplicados
    await _notificationsPlugin.cancelAll();

    // Notificación 3 días antes
    DateTime notifyDay3 = predictedPeriodDate.subtract(Duration(days: 3));
    if (notifyDay3.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 1,
        scheduledDate: notifyDay3,
        title: 'Tu periodo se acerca',
        body: 'Tu periodo estimado comienza en 3 días. Prepárate.',
      );
    }

    // Notificación el día estimado del periodo
    if (predictedPeriodDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 2,
        scheduledDate: predictedPeriodDate,
        title: 'Tu periodo ha comenzado',
        body: 'Es posible que tu periodo comience hoy.',
      );
    }
  }

  /// Método privado para agendar una notificación puntual
  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'period_channel',
      'Período',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
