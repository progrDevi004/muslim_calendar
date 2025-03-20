// lib/data/services/notification_service.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// >>> NEU: Für Zeitzonen-Init
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // >>> NEU: gesondertes Flag für Zeitzonen-Init
  bool _timeZoneInitialized = false;

  // Konstante für SharedPreferences Key
  static const String _notificationsKey = 'scheduled_notifications';

  /// Aufruf zum globalen Aktivieren. Hier kann man ggf. nochmal `_initIfNeeded()` triggern.
  Future<void> enableNotifications() async {
    await _initIfNeeded();
    // Geplante Benachrichtigungen wiederherstellen
    await restoreScheduledNotifications();
  }

  /// Globales Deaktivieren (alle geplanten Notifications abbrechen).
  Future<void> disableNotifications() async {
    await cancelAllNotifications();
    // Gespeicherte Benachrichtigungen löschen
    await _clearStoredNotifications();
  }

  /// Initiales Setup mit optionaler iOS-Permission-Abfrage
  /// (Kannst du bei Bedarf auch manuell aufrufen.)
  Future<void> init() async {
    // Wir initialisieren und fragen auf iOS um Erlaubnis
    await _initIfNeeded();
    if (Platform.isIOS) {
      await requestIOSPermissions();
    }

    // Prüfe auch Android-Berechtigungen
    if (Platform.isAndroid) {
      await requestAndroidPermissions();
    }

    // Prüfe Android-spezifische Alarm-Permissions
    if (Platform.isAndroid) {
      await testAlarmPermissions();
    }

    // Stelle gespeicherte Benachrichtigungen wieder her
    await restoreScheduledNotifications();
  }

  /// iOS-spezifisch: Benachrichtigungs-Rechte anfragen (alert, badge, sound).
  Future<void> requestIOSPermissions() async {
    if (!Platform.isIOS) return; // Nur iOS braucht das
    final iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Android-spezifisch: Benachrichtigungs-Rechte anfragen.
  Future<void> requestAndroidPermissions() async {
    if (!Platform.isAndroid) return; // Nur Android braucht das
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
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
      return;
    }

    final id = appointmentId;
    const androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Appointments',
      channelDescription: 'Termin-Erinnerungen',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledDate = _convertTimeToTZDateTime(dateTime);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }

    // Benachrichtigung speichern
    await _saveScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: dateTime,
    );
  }

  /// Testet Android-Berechtigungen für AlarmManager
  Future<void> testAlarmPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      // Ein einfacher Test, ob AlarmManager funktioniert
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Prüfe, ob Benachrichtigungen aktiviert sind
        final notificationsEnabled =
            await androidImplementation.areNotificationsEnabled();

        if (notificationsEnabled != null && !notificationsEnabled) {
          // Hinweise zu exakten Alarmen für Android 12+
          // Es gibt keinen direkten API-Aufruf, um den aktuellen Status zu überprüfen
          // daher können wir nur Anleitungen geben
        }
      }
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }
  }

  /// An einer zentralen Stelle initialisieren wir (falls nicht schon geschehen)
  /// sowohl das FlutterLocalNotificationsPlugin als auch die Zeitzonendaten.
  Future<void> _initIfNeeded() async {
    if (!_timeZoneInitialized) {
      // Zeitzonen-Daten laden
      tzData.initializeTimeZones();
      final localTimeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
      _timeZoneInitialized = true;
    }

    if (!_initialized) {
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS-Init mit Berechtigungseinstellungen
      const iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Kombinierte Settings
      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      // Plugin mit Callback für Benachrichtigungsaktionen initialisieren
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Hier könnte Navigation zur betreffenden Seite implementiert werden
        },
      );

      // Für Android 13+ explizite Berechtigungen anfordern
      if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      _initialized = true;
    }
  }

  /// Wandelt das DateTime in ein 'tz.TZDateTime' um (Zeitzone).
  tz.TZDateTime _convertTimeToTZDateTime(DateTime dateTime) {
    // Sicherstellen, dass wir die lokale Zeitzone verwenden
    final tz.Location location = tz.local;

    // Explizite Komponenten verwenden
    return tz.TZDateTime(
      location,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  /// Speichert eine geplante Benachrichtigung in SharedPreferences
  Future<void> _saveScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bestehende Benachrichtigungen laden
      final List<String> storedNotifications =
          prefs.getStringList(_notificationsKey) ?? [];

      // Benachrichtigung als JSON-Map erstellen
      final Map<String, dynamic> notification = {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
      };

      // In JSON umwandeln
      final String notificationJson = json.encode(notification);

      // Prüfen, ob bereits eine Benachrichtigung mit dieser ID existiert
      final existingIndex = storedNotifications.indexWhere((item) {
        final Map<String, dynamic> existing = json.decode(item);
        return existing['id'] == id;
      });

      // Aktualisieren oder hinzufügen
      if (existingIndex >= 0) {
        storedNotifications[existingIndex] = notificationJson;
      } else {
        storedNotifications.add(notificationJson);
      }

      // Speichern
      await prefs.setStringList(_notificationsKey, storedNotifications);
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }
  }

  /// Entfernt eine gespeicherte Benachrichtigung
  Future<void> _removeScheduledNotification(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bestehende Benachrichtigungen laden
      final List<String> storedNotifications =
          prefs.getStringList(_notificationsKey) ?? [];

      // Benachrichtigung mit der ID entfernen
      final filteredNotifications = storedNotifications.where((item) {
        final Map<String, dynamic> notification = json.decode(item);
        return notification['id'] != id;
      }).toList();

      // Speichern
      await prefs.setStringList(_notificationsKey, filteredNotifications);
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }
  }

  /// Löscht alle gespeicherten Benachrichtigungen
  Future<void> _clearStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }
  }

  /// Stellt alle gespeicherten Benachrichtigungen wieder her
  Future<void> restoreScheduledNotifications() async {
    await _initIfNeeded();

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> storedNotifications =
          prefs.getStringList(_notificationsKey) ?? [];

      for (final String notificationJson in storedNotifications) {
        try {
          final Map<String, dynamic> notification =
              json.decode(notificationJson);
          final int id = notification['id'];
          final String title = notification['title'];
          final String body = notification['body'];
          final DateTime scheduledDate =
              DateTime.parse(notification['scheduledDate']);

          // Nur wiederherstellen, wenn das Datum noch in der Zukunft liegt
          if (scheduledDate.isAfter(DateTime.now())) {
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              title,
              body,
              _convertTimeToTZDateTime(scheduledDate),
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'appointments_channel',
                  'Appointments',
                  channelDescription: 'Termin-Erinnerungen',
                  importance: Importance.max,
                  priority: Priority.high,
                  enableVibration: true,
                  playSound: true,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dateAndTime,
            );
          } else {
            // Benachrichtigung ist abgelaufen, aus dem Speicher entfernen
            await _removeScheduledNotification(id);
          }
        } catch (e) {
          // Fehler protokollieren, aber keine Debug-Ausgabe
        }
      }
    } catch (e) {
      // Fehler protokollieren, aber keine Debug-Ausgabe
    }
  }

  /// Shows a dialog with information about required permissions
  Future<void> showPermissionInfoDialog(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // Simple check if notifications are enabled
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final notificationsEnabled = androidImplementation != null
        ? await androidImplementation.areNotificationsEnabled()
        : false;

    if (notificationsEnabled == null || !notificationsEnabled) {
      // No notification permission
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notifications disabled'),
          content: const Text(
              'Notifications are not enabled. Please allow notifications in the '
              'app settings for appointment reminders to work properly.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    // Info about exact alarms for Android 12+
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For scheduled notifications to be displayed reliably, the '
              'following settings are required:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1. Allow alarms & reminders:'),
            Text(
                '   Settings > Apps > Muslim Calendar > Special app access > Alarms & reminders'),
            SizedBox(height: 8),
            Text('2. Disable battery optimizations:'),
            Text(
                '   Settings > Apps > Muslim Calendar > Battery > Unrestricted'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  /// Bricht eine Notification mit der entsprechenden ID ab
  Future<void> cancelNotification(int appointmentId) async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancel(appointmentId);

    // Aus dem Speicher entfernen
    await _removeScheduledNotification(appointmentId);
  }

  /// Bricht alle Notifications ab
  Future<void> cancelAllNotifications() async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Alle gespeicherten Benachrichtigungen löschen
    await _clearStoredNotifications();
  }
}
