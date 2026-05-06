import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('No se pudo obtener zona horaria local, usando UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleMedicamentoReminders({
    required String uid,
    required String medicamentoId,
    required String nombre,
    required String dosis,
    required DateTime fechaHora,
  }) async {
    await _cancelGroup(_baseId(uid, 'med', medicamentoId));

    final reminders = <Duration>[
      const Duration(days: 1),
      const Duration(hours: 1),
      const Duration(minutes: 5),
      Duration.zero,
    ];
    final labels = <String>[
      'en 1 día',
      'en 1 hora',
      'en 5 minutos',
      'ahora',
    ];

    for (var i = 0; i < reminders.length; i++) {
      final scheduleAt = fechaHora.subtract(reminders[i]);
      await _scheduleIfFuture(
        id: _baseId(uid, 'med', medicamentoId) + i,
        title: 'Recordatorio de medicamento',
        body: labels[i] == 'ahora'
            ? 'Es hora de tomar $nombre ($dosis).'
            : 'Debes tomar $nombre ($dosis) ${labels[i]}.',
        when: scheduleAt,
      );
    }
  }

  Future<void> scheduleCitaReminders({
    required String uid,
    required String citaId,
    required String motivo,
    required DateTime fechaHora,
  }) async {
    await _cancelGroup(_baseId(uid, 'cita', citaId));

    final reminders = <Duration>[
      const Duration(days: 1),
      const Duration(hours: 1),
    ];
    final labels = <String>['en 1 día', 'en 1 hora'];

    for (var i = 0; i < reminders.length; i++) {
      final scheduleAt = fechaHora.subtract(reminders[i]);
      await _scheduleIfFuture(
        id: _baseId(uid, 'cita', citaId) + i,
        title: 'Recordatorio de cita médica',
        body: 'Tienes "$motivo" ${labels[i]}.',
        when: scheduleAt,
      );
    }
  }

  Future<void> _cancelGroup(int baseId) async {
    for (var i = 0; i < 4; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> _scheduleIfFuture({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    final scheduleDate = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'time4med_reminders',
          'Recordatorios Time 4 Med',
          channelDescription: 'Notificaciones de medicamentos y citas',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _baseId(String uid, String type, String itemId) {
    final raw = '$uid-$type-$itemId'.hashCode.abs();
    // se reservan 10 IDs por item; actualmente se usan offsets +0..+3.
    return (raw % 100000000) * 10;
  }
}
