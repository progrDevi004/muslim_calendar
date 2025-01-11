// lib/data/services/notification_service.dart

import 'dart:io' show Platform;
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

  /// Aufruf zum globalen Aktivieren. Hier kann man ggf. nochmal `_initIfNeeded()` triggern.
  Future<void> enableNotifications() async {
    if (kDebugMode) {
      print("[NotificationService] Notifications globally enabled.");
    }
    await _initIfNeeded();
  }

  /// Globales Deaktivieren (alle geplanten Notifications abbrechen).
  Future<void> disableNotifications() async {
    if (kDebugMode) {
      print("[NotificationService] Notifications globally disabled.");
    }
    await cancelAllNotifications();
  }

  /// Initiales Setup mit optionaler iOS-Permission-Abfrage
  /// (Kannst du bei Bedarf auch manuell aufrufen.)
  Future<void> init() async {
    // Wir initialisieren und fragen auf iOS um Erlaubnis
    await _initIfNeeded();
    if (Platform.isIOS) {
      await requestIOSPermissions();
    }
  }

  /// iOS-spezifisch: Benachrichtigungs-Rechte anfragen (alert, badge, sound).
  Future<void> requestIOSPermissions() async {
    if (!Platform.isIOS) return; // Nur iOS braucht das
    final iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print("[NotificationService] iOS Permission granted? $granted");
      }
    }
  }

  /// Plant eine Notification, sofern das Datum in der Zukunft liegt.
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
    const androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Appointments',
      channelDescription: 'Termin-Erinnerungen',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

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

  /// Bricht eine Notification mit der entsprechenden ID ab.
  Future<void> cancelNotification(int appointmentId) async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancel(appointmentId);
    if (kDebugMode) {
      print(
          "[NotificationService] Canceled notification for ID=$appointmentId");
    }
  }

  /// Bricht alle Notifications ab.
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

      // iOS-Init, falls benötigt
      const iosInitSettings = DarwinInitializationSettings();

      // Kombinierte Settings
      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      // Plugin initialisieren
      await _flutterLocalNotificationsPlugin.initialize(initSettings);
      _initialized = true;

      if (kDebugMode) {
        print("[NotificationService] LocalNotifications initialized.");
      }
    }
  }

  /// Wandelt das DateTime in ein 'tz.TZDateTime' um (Zeitzone).
  tz.TZDateTime _convertTimeToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
