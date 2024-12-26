// lib/data/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// >>> NEU: Für Zeitzonen-Init
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // >>> NEU: gesondertes Flag für Zeitzonen-Init
  bool _timeZoneInitialized = false;

  Future<void> enableNotifications() async {
    if (kDebugMode) {
      print("[NotificationService] Notifications globally enabled.");
    }
    await _initIfNeeded();
  }

  Future<void> disableNotifications() async {
    if (kDebugMode) {
      print("[NotificationService] Notifications globally disabled.");
    }
    await cancelAllNotifications();
  }

  Future<void> scheduleNotification({
    required int appointmentId,
    required String title,
    required DateTime dateTime,
    required String body,
  }) async {
    await _initIfNeeded();

    if (dateTime.isBefore(DateTime.now())) {
      if (kDebugMode) {
        print("[NotificationService] Start time is in the past, skipping.");
      }
      return;
    }

    final id = appointmentId;

    final androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Appointments',
      channelDescription: 'Termin-Erinnerungen',
      importance: Importance.max,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertTimeToTZDateTime(dateTime),
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    if (kDebugMode) {
      print(
          "[NotificationService] Scheduled notification for $dateTime (ID=$id)");
    }
  }

  Future<void> cancelNotification(int appointmentId) async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancel(appointmentId);
    if (kDebugMode) {
      print(
          "[NotificationService] Canceled notification for ID=$appointmentId");
    }
  }

  Future<void> cancelAllNotifications() async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancelAll();
    if (kDebugMode) {
      print("[NotificationService] Canceled all notifications.");
    }
  }

  /// >>> NEU: An einer zentralen Stelle initialisieren wir (falls nicht schon geschehen)
  /// sowohl das FlutterLocalNotificationsPlugin als auch die Zeitzonendaten.
  Future<void> _initIfNeeded() async {
    if (!_timeZoneInitialized) {
      // Zeitzonen-Daten laden
      tzData.initializeTimeZones();
      final localTimeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
      _timeZoneInitialized = true;

      if (kDebugMode) {
        print(
            "[NotificationService] Time zone initialized: $localTimeZoneName");
      }
    }

    if (!_initialized) {
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidInitSettings,
      );
      await _flutterLocalNotificationsPlugin.initialize(initSettings);
      _initialized = true;

      if (kDebugMode) {
        print("[NotificationService] LocalNotifications initialized.");
      }
    }
  }

  /// >>> Wichtig: Wir wandeln das DateTime in ein 'tz.TZDateTime' um,
  /// nachdem wir 'tz.local' korrekt gesetzt haben.
  tz.TZDateTime _convertTimeToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
