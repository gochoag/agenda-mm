import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String channelId = 'agenda_channel_events';
  static const String channelName = 'Recordatorios de Agenda';
  static const String channelDescription = 'Notificaciones de fechas y citas agendadas';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      // Configurar zona horaria local según el offset del dispositivo
      try {
        final now = DateTime.now();
        final timeZoneOffset = now.timeZoneOffset;
        final locationName = tz.timeZoneDatabase.locations.entries
            .firstWhere(
              (entry) =>
                  entry.value.currentTimeZone.offset == timeZoneOffset,
              orElse: () => tz.timeZoneDatabase.locations.entries.first,
            )
            .key;
        tz.setLocalLocation(tz.getLocation(locationName));
      } catch (e) {
        debugPrint('[NotificationService] Fallback de timezone: $e');
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notificación presionada: ${response.payload}');
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Crear canal de alta prioridad explícitamente para Android 8.0+
      const AndroidNotificationChannel eventChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidImplementation?.createNotificationChannel(eventChannel);

      // Solicitar permisos en Android 13+ (POST_NOTIFICATIONS y alarmas exactas)
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      _initialized = true;
      debugPrint('[NotificationService] Inicializado con éxito');
    } catch (e) {
      debugPrint('[NotificationService] Error inicializando: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final notif = await androidImplementation?.requestNotificationsPermission();
      final alarms = await androidImplementation?.requestExactAlarmsPermission();
      return (notif ?? false) || (alarms ?? false);
    } catch (e) {
      debugPrint('[NotificationService] Error al solicitar permisos: $e');
      return false;
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] Fecha pasada, no se programa: $scheduledDate');
      return false;
    }

    try {
      // Construir TZDateTime exacto a partir de UTC para sincronización perfecta con AlarmManager
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('[NotificationService] Fallback a inexactAllowWhileIdle: $e');
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      debugPrint('[NotificationService] Programada con éxito id=$id para $tzScheduledDate (epoch=${tzScheduledDate.millisecondsSinceEpoch})');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error programando notificación: $e');
      return false;
    }
  }

  Future<bool> scheduleTestNotification({int seconds = 5}) async {
    try {
      await init();

      // 1. Mostrar notificación instantánea para verificación inmediata
      await showImmediateNotification(
        id: 999998,
        title: '🔔 Agenda MM - Alerta Activa',
        body: '¡Excelente! Las notificaciones funcionan correctamente.',
      );

      // 2. Programar notificación diferida
      final testTime = DateTime.now().add(Duration(seconds: seconds));
      final tzDate = tz.TZDateTime(
        tz.local,
        testTime.year,
        testTime.month,
        testTime.day,
        testTime.hour,
        testTime.minute,
        testTime.second,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: 999999,
          title: '🔔 Recordatorio Agenda MM (5s)',
          body: 'Notificación temporizada recibida con éxito.',
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: 999999,
          title: '🔔 Recordatorio Agenda MM (5s)',
          body: 'Notificación temporizada recibida con éxito.',
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error en test notification: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }
}
