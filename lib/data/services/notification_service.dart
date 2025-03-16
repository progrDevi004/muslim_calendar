// lib/data/services/notification_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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
    debugPrint("[NotificationService] Notifications globally enabled.");
    await _initIfNeeded();
    // Geplante Benachrichtigungen wiederherstellen
    await restoreScheduledNotifications();
  }

  /// Globales Deaktivieren (alle geplanten Notifications abbrechen).
  Future<void> disableNotifications() async {
    debugPrint("[NotificationService] Notifications globally disabled.");
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
      final bool? granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint("[NotificationService] iOS Permission granted? $granted");
    }
  }

  /// Android-spezifisch: Benachrichtigungs-Rechte anfragen.
  Future<void> requestAndroidPermissions() async {
    if (!Platform.isAndroid) return; // Nur Android braucht das
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final bool? granted =
          await androidPlugin.requestNotificationsPermission();
      debugPrint("[NotificationService] Android Permission granted? $granted");
    }
  }

  /// Plant eine Notification, sofern das Datum in der Zukunft liegt.
  Future<void> scheduleNotification({
    required int appointmentId,
    required String title,
    required DateTime dateTime,
    required String body,
  }) async {
    // Erweiterte Debug-Informationen
    debugPrint("==========================================");
    debugPrint("[DEBUG] Scheduling notification:");
    debugPrint("  ID: $appointmentId");
    debugPrint("  Title: $title");
    debugPrint("  Body: $body");
    debugPrint("  Target time: $dateTime");
    debugPrint("  Current time: ${DateTime.now()}");
    debugPrint(
        "  Difference: ${dateTime.difference(DateTime.now()).inMinutes} minutes");

    await _initIfNeeded();

    if (dateTime.isBefore(DateTime.now())) {
      debugPrint("[NotificationService] Start time is in the past, skipping.");
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

    debugPrint("[DEBUG] Calling zonedSchedule with date: $scheduledDate");

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
      debugPrint("[DEBUG] zonedSchedule call successful");
    } catch (e) {
      debugPrint("[DEBUG] ERROR in zonedSchedule: $e");
    }

    debugPrint(
        "[NotificationService] Scheduled notification for $dateTime (ID=$id)");

    // Benachrichtigung speichern
    await _saveScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: dateTime,
    );

    // Aktuelle ausstehende Benachrichtigungen anzeigen
    final pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint(
        "[DEBUG] Current pending notifications: ${pendingNotifications.length}");
    if (pendingNotifications.isNotEmpty) {
      for (final notification in pendingNotifications) {
        debugPrint(
            "[DEBUG]   - ID: ${notification.id}, Title: ${notification.title}");
      }
    }
    debugPrint("==========================================");
  }

  /// 30-Sekunden-Testbenachrichtigung für Debugging
  Future<void> testScheduledNotification() async {
    // Benachrichtigung in 30 Sekunden
    final DateTime targetTime = DateTime.now().add(const Duration(seconds: 30));

    debugPrint("[TEST] Scheduling test notification for: $targetTime");

    await scheduleNotification(
      appointmentId: 99999,
      title: "Test Scheduled Notification",
      body:
          "Diese Benachrichtigung sollte 30 Sekunden nach dem Planen erscheinen",
      dateTime: targetTime,
    );

    debugPrint("[TEST] Scheduled test notification successfully");
  }

  /// Zeigt eine sofortige Testbenachrichtigung an
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _initIfNeeded();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Zum Testen der Benachrichtigungen',
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

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );

    debugPrint(
        "[NotificationService] Immediate notification shown with ID=$id");
  }

  /// Bricht eine Notification mit der entsprechenden ID ab.
  Future<void> cancelNotification(int appointmentId) async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancel(appointmentId);

    // Aus dem Speicher entfernen
    await _removeScheduledNotification(appointmentId);

    debugPrint(
        "[NotificationService] Canceled notification for ID=$appointmentId");
  }

  /// Bricht alle Notifications ab.
  Future<void> cancelAllNotifications() async {
    await _initIfNeeded();
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Alle gespeicherten Benachrichtigungen löschen
    await _clearStoredNotifications();

    debugPrint("[NotificationService] Canceled all notifications.");
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
        debugPrint(
            "[DEBUG] Benachrichtigungen aktiviert: $notificationsEnabled");

        if (notificationsEnabled != null && !notificationsEnabled) {
          debugPrint(
              "[DEBUG] *** WARNUNG: Benachrichtigungen sind nicht aktiviert! ***");
          debugPrint("[DEBUG] Der Nutzer sollte die App-Einstellungen prüfen.");
        }

        // Hinweise zu exakten Alarmen für Android 12+
        debugPrint("[DEBUG] Wichtiger Hinweis für Android 12+:");
        debugPrint(
            "[DEBUG] Exakte Alarme sind erforderlich, damit geplante Benachrichtigungen korrekt funktionieren.");
        debugPrint(
            "[DEBUG] Falls keine geplanten Benachrichtigungen erscheinen, überprüfe bitte folgende Einstellungen:");
        debugPrint(
            "[DEBUG] 1. Gehe zu Einstellungen > Apps > Muslim Calendar > Spezielle App-Zugriffe > Alarme & Erinnerungen");
        debugPrint("[DEBUG] 2. Aktiviere 'Alarme & Erinnerungen erlauben'");
        debugPrint(
            "[DEBUG] 3. Gehe zu Einstellungen > Apps > Muslim Calendar > Akku");
        debugPrint(
            "[DEBUG] 4. Wähle 'Keine Einschränkungen' oder 'Nicht optimieren'");

        // Es gibt keinen direkten API-Aufruf, um den aktuellen Status zu überprüfen
        // daher können wir nur Anleitungen geben
      }
    } catch (e) {
      debugPrint(
          "[DEBUG] Error bei der Prüfung von Android-Berechtigungen: $e");
    }
  }

  /// >>> NEU: An einer zentralen Stelle initialisieren wir (falls nicht schon geschehen)
  /// sowohl das FlutterLocalNotificationsPlugin als auch die Zeitzonendaten.
  Future<void> _initIfNeeded() async {
    if (!_timeZoneInitialized) {
      // Zeitzonen-Daten laden
      tzData.initializeTimeZones();
      final localTimeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZoneName));
      _timeZoneInitialized = true;

      debugPrint(
          "[NotificationService] Time zone initialized: $localTimeZoneName");
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
          debugPrint(
              "[NotificationService] Notification tapped: ID=${response.id}, payload: ${response.payload}");
          // Hier könntest du eine Navigation zur betreffenden Seite implementieren
        },
      );

      // Für Android 13+ explizite Berechtigungen anfordern
      if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImplementation?.requestNotificationsPermission();
        debugPrint(
            "[NotificationService] Android notification permission granted: $granted");
      }

      _initialized = true;
      debugPrint("[NotificationService] LocalNotifications initialized.");
    }
  }

  /// Wandelt das DateTime in ein 'tz.TZDateTime' um (Zeitzone).
  tz.TZDateTime _convertTimeToTZDateTime(DateTime dateTime) {
    // Sicherstellen, dass wir die lokale Zeitzone verwenden
    final tz.Location location = tz.local;

    debugPrint("[DEBUG] Converting time:");
    debugPrint("  Input: $dateTime");
    debugPrint("  Timezone: ${location.name}");

    // Alternative Konvertierungsmethoden zum Testen
    final method1 = tz.TZDateTime.from(dateTime, location);
    final method2 = tz.TZDateTime(
      location,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    debugPrint("  Method 1 result: $method1");
    debugPrint("  Method 2 result: $method2");

    // In dieser Version verwenden wir Method 2, die exakte Komponenten verwendet
    final tz.TZDateTime result = method2;

    debugPrint(
        "[NotificationService] Converted ${dateTime.toString()} to ${result.toString()} (local timezone)");
    return result;
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
      debugPrint("[NotificationService] Saved notification to storage: ID=$id");
    } catch (e) {
      debugPrint("[NotificationService] Error saving notification: $e");
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
      debugPrint(
          "[NotificationService] Removed notification from storage: ID=$id");
    } catch (e) {
      debugPrint("[NotificationService] Error removing notification: $e");
    }
  }

  /// Löscht alle gespeicherten Benachrichtigungen
  Future<void> _clearStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      debugPrint("[NotificationService] Cleared all stored notifications");
    } catch (e) {
      debugPrint("[NotificationService] Error clearing notifications: $e");
    }
  }

  /// Stellt alle gespeicherten Benachrichtigungen wieder her
  Future<void> restoreScheduledNotifications() async {
    await _initIfNeeded();

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> storedNotifications =
          prefs.getStringList(_notificationsKey) ?? [];

      debugPrint(
          "[NotificationService] Restoring ${storedNotifications.length} notifications");

      int restoredCount = 0;

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
            restoredCount++;
            debugPrint(
                "[NotificationService] Restored notification: ID=$id, date=$scheduledDate");
          } else {
            // Benachrichtigung ist abgelaufen, aus dem Speicher entfernen
            await _removeScheduledNotification(id);
            debugPrint(
                "[NotificationService] Removed expired notification: ID=$id, date=$scheduledDate");
          }
        } catch (e) {
          debugPrint("[NotificationService] Error restoring notification: $e");
        }
      }

      debugPrint(
          "[NotificationService] Successfully restored $restoredCount notifications");
    } catch (e) {
      debugPrint(
          "[NotificationService] Error in restoreScheduledNotifications: $e");
    }
  }

  /// Prüft, ob Benachrichtigungen korrekt aktiviert wurden
  Future<String> getStatusInfo() async {
    await _initIfNeeded();
    String status = "Benachrichtigungsstatus:\n";

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImplementation?.areNotificationsEnabled() ?? false;
        status +=
            "- Android-Berechtigungen: ${granted ? 'Erteilt' : 'Nicht erteilt'}\n";

        // Zeige Hinweis zu exakten Alarmen an
        status += "- Hinweis zu exakten Alarmen:\n";
        status +=
            "  * Für Android 12+: Exakte Alarme müssen in den Einstellungen aktiviert sein\n";
        status +=
            "  * Prüfe: Einstellungen > Apps > Muslim Calendar > Spezielle App-Zugriffe > Alarme & Erinnerungen\n";
      }

      if (Platform.isIOS) {
        status += "- iOS: Initialisiert\n";
      }

      // Prüfen auf ausstehende Benachrichtigungen
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      status +=
          "- Ausstehende Benachrichtigungen: ${pendingNotifications.length}\n";

      if (pendingNotifications.isNotEmpty) {
        status +=
            "  * IDs: ${pendingNotifications.map((n) => n.id).join(', ')}\n";
      }

      // Gespeicherte Benachrichtigungen prüfen
      final prefs = await SharedPreferences.getInstance();
      final List<String> storedNotifications =
          prefs.getStringList(_notificationsKey) ?? [];
      status +=
          "- Gespeicherte Benachrichtigungen: ${storedNotifications.length}\n";

      if (storedNotifications.isNotEmpty) {
        status += "  * Details:\n";
        for (final String notificationJson in storedNotifications) {
          final Map<String, dynamic> notification =
              json.decode(notificationJson);
          final DateTime date = DateTime.parse(notification['scheduledDate']);
          status +=
              "    - ID: ${notification['id']}, Zeit: ${date.toString()}\n";
        }
      }

      status += "- Zeitzone: ${tz.local.name}\n";
      status += "- Service initialisiert: $_initialized\n";
      status += "- Zeitzone initialisiert: $_timeZoneInitialized";
    } catch (e) {
      status += "Fehler bei Statusabfrage: $e";
    }

    return status;
  }

  /// Zeigt einen Dialog mit Hinweisen zu benötigten Berechtigungen an
  Future<void> showPermissionInfoDialog(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // Einfache Prüfung, ob Benachrichtigungen aktiviert sind
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final notificationsEnabled = androidImplementation != null
        ? await androidImplementation.areNotificationsEnabled()
        : false;

    if (notificationsEnabled == null || !notificationsEnabled) {
      // Keine Benachrichtigungsberechtigung
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Benachrichtigungen deaktiviert'),
          content: const Text(
              'Benachrichtigungen sind nicht aktiviert. Bitte erlaube Benachrichtigungen in den '
              'App-Einstellungen, damit die Terminerinnerungen funktionieren können.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
      return;
    }

    // Info zu exakten Alarmen für Android 12+
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Benachrichtigungs-Hinweis'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damit geplante Benachrichtigungen zuverlässig angezeigt werden, werden '
              'folgende Einstellungen benötigt:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1. Alarme & Erinnerungen erlauben:'),
            Text(
                '   Einstellungen > Apps > Muslim Calendar > Spezielle App-Zugriffe > Alarme & Erinnerungen'),
            SizedBox(height: 8),
            Text('2. Batterie-Optimierungen deaktivieren:'),
            Text(
                '   Einstellungen > Apps > Muslim Calendar > Akku > Keine Einschränkungen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }
}
