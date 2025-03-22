// lib/data/services/google_calendar_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/models/appointment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Taqvimi/data/services/prayer_time_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/enums.dart'
    as sf;
import 'package:Taqvimi/utils/recurrence_rule_converter.dart';

/// GoogleCalendarService - Low-Level API-Schnittstelle
///
/// Dieser Service ist für die direkte Interaktion mit der Google Calendar API zuständig
/// und sollte primär für folgende Aufgaben verwendet werden:
///
/// 1. Authentifizierung mit Google-Konto (Login/Logout)
/// 2. Abrufen von Kalenderlisten und Events
/// 3. Grundlegende CRUD-Operationen für einzelne Events
/// 4. Konvertierung zwischen App-Modellen und Google Calendar Events
///
/// Dieser Service ist als Singleton implementiert und sollte nicht direkt für
/// Batch-Operationen oder komplexe Synchronisierungslogik verwendet werden.
/// Für diese Zwecke wurde der GoogleCalendarSyncService entwickelt.
class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;

  // Service zum Berechnen der Gebetszeiten
  PrayerTimeService? _prayerTimeService;

  GoogleCalendarService._internal() {
    // Leerer Konstruktor für Singleton
    _initialize();
  }

  // Factory-Methode mit PrayerTimeService
  static GoogleCalendarService withPrayerTimeService(
      PrayerTimeService prayerTimeService) {
    _instance._prayerTimeService = prayerTimeService;
    return _instance;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;
  AppLocalizations? _localizations;

  // Status für UI-Feedback
  bool _isSignedIn = false;
  bool _isSyncing = false;
  String? _lastError;

  // Getter
  bool get isSignedIn => _isSignedIn;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  GoogleSignInAccount? get currentUser => _currentUser;

  // Initialisierung
  void _initialize() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      if (account != null) {
        _isSignedIn = true;
        _initCalendarApi();
      } else {
        _isSignedIn = false;
        _calendarApi = null;
      }
    });
  }

  // Setzt die Lokalisierung
  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }

  // Brücken-Methode für die Kompatibilität mit CalendarSyncService
  Future<void> autoSignIn() async {
    try {
      if (_currentUser != null) {
        // CalendarApi initialisieren, wenn bereits angemeldet
        await _initCalendarApi();
      } else {
        // Ansonsten neu anmelden
        await signIn();
      }
    } catch (error) {
      debugPrint('Fehler beim automatischen Login: $error');
      _lastError = error.toString();
      throw Exception('Fehler beim automatischen Login: $error');
    }
  }

  // Prüft den aktuellen Login-Status beim App-Start
  Future<bool> checkSignInStatus() async {
    try {
      // Versuche, den zuletzt angemeldeten Benutzer zu erhalten
      _currentUser = await _googleSignIn.signInSilently();
      _isSignedIn = _currentUser != null;

      if (_isSignedIn) {
        // CalendarApi initialisieren
        await _initCalendarApi();
      }

      return _isSignedIn;
    } catch (e) {
      debugPrint('Fehler beim Prüfen des Login-Status: $e');
      _lastError = e.toString();
      _isSignedIn = false;
      return false;
    }
  }

  // Liste aller verfügbaren Kalender abrufen
  Future<List<calendar.CalendarListEntry>> fetchCalendarList() async {
    if (_calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      throw Exception(_lastError);
    }

    try {
      var calendarList = await _calendarApi!.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      _lastError = 'Fehler beim Abrufen der Kalenderliste: $e';
      debugPrint(_lastError);
      throw Exception(_lastError);
    }
  }

  // Ruft alle Events aus einem Kalender ab
  Future<List<calendar.Event>> fetchEvents(
      {String calendarId = 'primary'}) async {
    if (_calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      throw Exception(_lastError);
    }

    try {
      var events = await _calendarApi!.events.list(calendarId);

      // Filtern von ungültigen Events
      final validEvents = events.items
              ?.where((event) =>
                  event.id != null &&
                  event.summary != null &&
                  event.summary!.trim().isNotEmpty &&
                  (event.start?.dateTime != null ||
                      event.start?.date != null) &&
                  (event.end?.dateTime != null || event.end?.date != null))
              .toList() ??
          [];

      return validEvents;
    } catch (e) {
      _lastError = 'Fehler beim Abrufen der Events: $e';
      debugPrint(_lastError);
      return [];
    }
  }

  // Ruft Events mit einem bestimmten Extended Property ab
  Future<List<calendar.Event>> fetchEventsByExtendedProperty(
      String extendedProperty,
      {String calendarId = 'primary'}) async {
    if (_calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      throw Exception(_lastError);
    }

    try {
      var events = await _calendarApi!.events.list(
        calendarId,
        privateExtendedProperty: [extendedProperty],
      );
      return events.items ?? [];
    } catch (e) {
      _lastError = 'Fehler beim Abrufen der Events mit Properties: $e';
      debugPrint(_lastError);
      return [];
    }
  }

  // Methode zum Abrufen von Events mit oder ohne Extended Property Filter
  Future<List<calendar.Event>> fetchCalendarEvents({
    String? extendedProperty,
    String calendarId = 'primary',
  }) async {
    if (extendedProperty != null) {
      return fetchEventsByExtendedProperty(extendedProperty,
          calendarId: calendarId);
    } else {
      return fetchEvents(calendarId: calendarId);
    }
  }

  // Google Sign-In Prozess
  Future<bool> signIn() async {
    try {
      _lastError = null;
      final user = await _googleSignIn.signIn();

      if (user == null) {
        _isSignedIn = false;
        _lastError = 'Sign-In abgebrochen';
        return false;
      }

      _currentUser = user;
      _isSignedIn = true;

      // CalendarApi initialisieren
      await _initCalendarApi();

      // Login-Status speichern
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('google_signed_in', true);

      return true;
    } catch (e) {
      debugPrint('Fehler beim Google Sign-In: $e');
      _lastError = e.toString();
      _isSignedIn = false;
      return false;
    }
  }

  // Google Sign-Out
  Future<bool> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;
      _isSignedIn = false;

      // Login-Status aktualisieren
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('google_signed_in', false);

      return true;
    } catch (e) {
      debugPrint('Fehler beim Abmelden: $e');
      _lastError = e.toString();
      return false;
    }
  }

  // Initialisiert die Google Calendar API
  Future<void> _initCalendarApi() async {
    if (_currentUser == null) return;

    final authHeaders = await _currentUser!.authHeaders;
    final client = http.Client();
    final httpClient = GoogleHttpClient(authHeaders, client);
    _calendarApi = calendar.CalendarApi(httpClient);
  }

  // Holt die lokale Zeitzone
  Future<String> _getLocalTimeZone() async {
    try {
      final String timeZone = await FlutterTimezone.getLocalTimezone();

      // Prüfen, ob wir einen gültigen IANA-Namen haben
      if (timeZone == 'GMT' || timeZone.isEmpty) {
        // Deutschland ist standardmäßig in Europe/Berlin
        return 'Europe/Berlin';
      }

      debugPrint('Verwendete IANA-Zeitzone: $timeZone');
      return timeZone;
    } catch (e) {
      debugPrint('Fehler beim Ermitteln der Zeitzone: $e');
      // Deutschland ist standardmäßig in Europe/Berlin
      return 'Europe/Berlin';
    }
  }

  // Termin zu Google Calendar hinzufügen
  Future<String?> addEventToGoogleCalendar(AppointmentModel appointment) async {
    if (!_isSignedIn || _calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      return null;
    }

    try {
      _isSyncing = true;
      _lastError = null;

      // Google Calendar Event erstellen
      final event = await _createGoogleEvent(appointment);

      // Event in Google Calendar einfügen
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');

      _isSyncing = false;
      return createdEvent.id; // ID des erstellten Events zurückgeben
    } catch (e) {
      _isSyncing = false;
      _lastError = 'Fehler beim Hinzufügen des Termins: $e';
      debugPrint(_lastError);
      return null;
    }
  }

  // Termin in Google Calendar aktualisieren
  Future<bool> updateEventInGoogleCalendar(AppointmentModel appointment) async {
    if (!_isSignedIn || _calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      return false;
    }

    if (appointment.externalIdGoogle == null) {
      _lastError = 'Termin existiert nicht in Google Calendar';
      return false;
    }

    try {
      _isSyncing = true;
      _lastError = null;

      // Google Calendar Event erstellen
      final event = await _createGoogleEvent(appointment);

      // Event in Google Calendar aktualisieren
      await _calendarApi!.events
          .update(event, 'primary', appointment.externalIdGoogle!);

      _isSyncing = false;
      return true;
    } catch (e) {
      _isSyncing = false;
      _lastError = 'Fehler beim Aktualisieren des Termins: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  // Termin aus Google Calendar löschen
  Future<bool> deleteEventFromGoogleCalendar(String googleEventId) async {
    if (!_isSignedIn || _calendarApi == null) {
      _lastError = 'Nicht bei Google angemeldet';
      return false;
    }

    try {
      _isSyncing = true;
      _lastError = null;

      await _calendarApi!.events.delete('primary', googleEventId);

      _isSyncing = false;
      return true;
    } catch (e) {
      _isSyncing = false;
      _lastError = 'Fehler beim Löschen des Termins: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  // Termin mit Google Calendar synchronisieren
  // (fügt hinzu oder aktualisiert, je nach Bedarf)
  Future<String?> syncAppointmentWithGoogleCalendar(
      AppointmentModel appointment) async {
    // Prüfen, ob dieser Termin synchronisiert werden soll
    if (!appointment.syncWithGoogleCalendar) {
      return null;
    }

    if (!_isSignedIn) {
      bool signedIn = await signIn();
      if (!signedIn) {
        return null;
      }
    }

    // Sonderbehandlung für gebetszeitabhängige Termine mit Wiederholung
    if (_prayerTimeService != null &&
        appointment.isRelatedToPrayerTimes &&
        appointment.prayerTime != null &&
        appointment.recurrenceRule != null &&
        appointment.id != null) {
      debugPrint('Gebetszeitabhängiger Termin mit Wiederholung erkannt');

      // Zeitraum bestimmen (3 Monate in die Zukunft)
      final DateTime today = DateTime.now();
      final DateTime startRangeDate =
          DateTime(today.year, today.month, today.day);
      final DateTime endRangeDate =
          startRangeDate.add(const Duration(days: 90));

      try {
        // Wiederholungstermine generieren
        final RecurrenceProperties recurrenceProperties = SfCalendar.parseRRule(
          appointment.recurrenceRule!,
          appointment.startTime ?? DateTime.now(),
        );

        final List<DateTime> occurrences = _getRecurrenceDates(
          recurrenceProperties,
          appointment.startTime ?? DateTime.now(),
          startRangeDate,
          endRangeDate,
        );

        debugPrint('${occurrences.length} Wiederholungen gefunden');

        // Entferne bereits vorhandene Events für diesen Termin, die nicht in den aktuellen Wiederholungen enthalten sind
        await _removeOutdatedEvents(appointment, occurrences);

        // Für jedes Datum in der Wiederholung individuelle Termine erstellen
        String? lastExternalId;
        for (DateTime occurrenceDate in occurrences) {
          // Basismodell für diesen Tag erstellen
          final baseDate = DateTime(
            occurrenceDate.year,
            occurrenceDate.month,
            occurrenceDate.day,
          );

          debugPrint(
              'Verarbeite Wiederholung am ${baseDate.toIso8601String()}');

          // Gebetszeiten für dieses spezifische Datum berechnen
          final calculatedStart = await _prayerTimeService!
              .getCalculatedStartTime(appointment, baseDate);

          final calculatedEnd = await _prayerTimeService!
              .getCalculatedEndTime(appointment, baseDate);

          if (calculatedStart != null && calculatedEnd != null) {
            // Einzeltermin ohne Wiederholung erstellen
            final singleAppointment = appointment.copyWith(
              startTime: calculatedStart,
              endTime: calculatedEnd,
              recurrenceRule:
                  null, // Wichtig: Keine Wiederholung für Einzeltermine
              recurrenceExceptionDates: null,
            );

            // Prüfen, ob bereits ein Event für diesen Termin an diesem Datum existiert
            final existingEvent = await getEventForAppointmentOnDate(
              appointment.id!,
              baseDate,
            );

            if (existingEvent != null) {
              // Event aktualisieren
              final event = await _createGoogleEvent(singleAppointment);
              await _calendarApi!.events.update(
                event,
                'primary',
                existingEvent.id!,
              );
              lastExternalId = existingEvent.id;
              debugPrint(
                  'Event für ${baseDate.toIso8601String()} aktualisiert');
            } else {
              // Neues Event erstellen
              final event = await _createGoogleEvent(singleAppointment);
              final createdEvent =
                  await _calendarApi!.events.insert(event, 'primary');
              lastExternalId = createdEvent.id;
              debugPrint('Event für ${baseDate.toIso8601String()} erstellt');
            }
          } else {
            debugPrint(
                'Konnte Gebetszeiten für ${baseDate.toIso8601String()} nicht berechnen');
          }
        }

        // Die ID des letzten erstellten/aktualisierten Events zurückgeben
        return lastExternalId;
      } catch (e) {
        debugPrint(
            'Fehler bei der Verarbeitung des wiederkehrenden Termins: $e');
        // Fallback zum normalen Verhalten
      }
    } else {
      // Bei gebetszeitabhängigen Terminen ohne Wiederholung zuerst die berechneten Zeiten ermitteln
      AppointmentModel appointmentToSync = appointment;

      if (_prayerTimeService != null &&
          appointment.isRelatedToPrayerTimes &&
          appointment.prayerTime != null) {
        debugPrint(
            'Berechne gebetszeitabhängige Zeiten für Google Calendar Synchronisierung');

        final calculatedStart = await _prayerTimeService!
            .getCalculatedStartTime(
                appointment, appointment.startTime ?? DateTime.now());

        final calculatedEnd = await _prayerTimeService!.getCalculatedEndTime(
            appointment, appointment.startTime ?? DateTime.now());

        if (calculatedStart != null && calculatedEnd != null) {
          debugPrint('Google Calendar Sync - Gebetszeitabhängiger Termin:');
          debugPrint('- Original startTime: ${appointment.startTime}');
          debugPrint('- Berechnet startTime: $calculatedStart');
          debugPrint('- Berechnet endTime: $calculatedEnd');

          // Erstelle eine Kopie des Appointment mit den berechneten Zeiten
          appointmentToSync = appointment.copyWith(
            startTime: calculatedStart,
            endTime: calculatedEnd,
          );
        } else {
          debugPrint(
              'Warnung: Gebetszeiten konnten nicht berechnet werden für: ${appointment.subject}');
        }
      }

      // Wenn der Termin bereits eine Google-ID hat, aktualisieren
      if (appointmentToSync.externalIdGoogle != null) {
        bool success = await updateEventInGoogleCalendar(appointmentToSync);
        return success ? appointmentToSync.externalIdGoogle : null;
      } else {
        // Ansonsten neuen Termin erstellen
        return await addEventToGoogleCalendar(appointmentToSync);
      }
    }
    return null;
  }

  // Hilfsmethode: Berechnet Wiederholungsdaten für einen Termin
  List<DateTime> _getRecurrenceDates(
    RecurrenceProperties recurrenceProperties,
    DateTime patternStartDate,
    DateTime startRangeDate,
    DateTime endRangeDate,
  ) {
    List<DateTime> dates = [];

    int count = recurrenceProperties.recurrenceCount;
    DateTime? endDate = recurrenceProperties.endDate;

    DateTime currentDate = patternStartDate;

    // Sicherstellen, dass wir keine unendliche Schleife erzeugen
    int maxIterations = 200;
    int iteration = 0;

    while (currentDate.isBefore(endRangeDate) && iteration < maxIterations) {
      iteration++;

      // Prüfen, ob das aktuelle Datum im Bereich liegt
      if (!currentDate.isBefore(startRangeDate) &&
          !currentDate.isAfter(endRangeDate)) {
        dates.add(currentDate);
      }

      // Nächstes Datum gemäß Wiederholungsregel berechnen
      switch (recurrenceProperties.recurrenceType) {
        case sf.RecurrenceType.daily:
          currentDate =
              currentDate.add(Duration(days: recurrenceProperties.interval));
          break;

        case sf.RecurrenceType.weekly:
          if (recurrenceProperties.weekDays.isEmpty) {
            // Wenn keine Wochentage angegeben, verwende den gleichen Wochentag
            currentDate = currentDate
                .add(Duration(days: 7 * recurrenceProperties.interval));
          } else {
            // Überspringe zum nächsten ausgewählten Wochentag
            // Vereinfachte Implementierung: Wir fügen einen Tag hinzu und prüfen
            currentDate = currentDate.add(const Duration(days: 1));

            // Prüfung, ob wir in der nächsten Woche sind und den Interval anwenden müssen
            int weeksBetween =
                (currentDate.difference(patternStartDate).inDays / 7).floor();
            if (weeksBetween >= recurrenceProperties.interval) {
              // Überspringe weitere Tage, wenn wir den Interval erreicht haben
              currentDate = currentDate.add(Duration(
                  days: (7 *
                          (((weeksBetween / recurrenceProperties.interval)
                                          .floor() +
                                      1) *
                                  recurrenceProperties.interval -
                              7 * weeksBetween))
                      .toInt()));
            }
          }
          break;

        case sf.RecurrenceType.monthly:
          // Füge einen Monat hinzu (vereinfacht)
          int newMonth = currentDate.month + recurrenceProperties.interval;
          int yearAdd = (newMonth - 1) ~/ 12; // Wie viele Jahre hinzufügen
          int finalMonth = ((newMonth - 1) % 12) + 1; // Finaler Monat (1-12)

          DateTime nextMonth = DateTime(
            currentDate.year + yearAdd,
            finalMonth,
            1,
          );

          int day = currentDate.day;
          int lastDayOfMonth =
              DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          if (day > lastDayOfMonth) {
            day = lastDayOfMonth;
          }

          currentDate = DateTime(nextMonth.year, nextMonth.month, day);
          break;

        case sf.RecurrenceType.yearly:
          currentDate = DateTime(
            currentDate.year + recurrenceProperties.interval,
            currentDate.month,
            currentDate.day,
          );
          break;

        default:
          currentDate =
              currentDate.add(Duration(days: recurrenceProperties.interval));
      }

      // Prüfe, ob wir die Anzahl der Wiederholungen erreicht haben
      if (count > 0 && dates.length >= count) {
        break;
      }

      // Prüfe, ob wir das Enddatum erreicht haben
      if (endDate != null && currentDate.isAfter(endDate)) {
        break;
      }
    }

    return dates;
  }

  // Entfernt veraltete Events, die nicht mehr im Wiederholungsmuster sind
  Future<void> _removeOutdatedEvents(
    AppointmentModel appointment,
    List<DateTime> validDates,
  ) async {
    if (appointment.id == null) return;

    String filter = 'muslimcalendarID=${appointment.id}';
    List<calendar.Event> events = await fetchEventsByExtendedProperty(
      filter,
      calendarId: 'primary',
    );

    for (var event in events) {
      DateTime? eventDate =
          event.start?.dateTime?.toLocal() ?? event.start?.date?.toLocal();
      if (eventDate == null) continue;

      // Prüfe, ob dieses Datum in der Liste der gültigen Daten ist
      bool isValidDate = validDates.any((date) =>
          date.year == eventDate.year &&
          date.month == eventDate.month &&
          date.day == eventDate.day);

      if (!isValidDate && event.id != null) {
        debugPrint('Lösche veraltetes Event am ${eventDate.toIso8601String()}');
        await _calendarApi!.events.delete('primary', event.id!);
      }
    }
  }

  // API-Schnittstelle für CalendarSyncService
  Future<calendar.Event> syncAppointmentEvent({
    required AppointmentModel appointment,
    required DateTime startTime,
    required DateTime endTime,
    required bool prayerRelated,
    String calendarId = 'primary',
  }) async {
    await autoSignIn();

    // Korrektur: Stunde subtrahieren, um die Zeitverschiebung zu kompensieren
    final adjustedStartTime = startTime;
    final adjustedEndTime = endTime;

    if (prayerRelated) {
      // Für gebetszeitbezogene Termine
      Map<String, String> extendedProps = {
        'muslimcalendarID': appointment.id.toString(),
        'localAppID': appointment.id
            .toString(), // Hinzugefügt: Kennzeichnung als App-exportierter Termin
      };

      // Prüfen, ob bereits ein Event für diesen Termin und dieses Datum existiert
      calendar.Event? existingEvent = await getEventForAppointmentOnDate(
        appointment.id!,
        startTime, // Hier Original-Startzeit für die Suche verwenden
        calendarId: calendarId,
      );

      calendar.Event result;

      if (existingEvent != null) {
        // Aktualisiere existierendes Event
        existingEvent.summary = appointment.subject;
        existingEvent.description = appointment.notes;
        existingEvent.location = appointment.location;

        // Neu setzen von Start- und Endzeit mit korrekter Zeitzone und angepasster Zeit
        final timeZone = await _getLocalTimeZone();
        existingEvent.start = calendar.EventDateTime(
          dateTime: adjustedStartTime,
          timeZone: timeZone,
        );
        existingEvent.end = calendar.EventDateTime(
          dateTime: adjustedEndTime,
          timeZone: timeZone,
        );

        // Extended Properties aktualisieren
        if (existingEvent.extendedProperties == null) {
          existingEvent.extendedProperties = calendar.EventExtendedProperties(
            private: extendedProps,
          );
        } else {
          existingEvent.extendedProperties!.private ??= {};
          existingEvent.extendedProperties!.private!.addAll(extendedProps);
        }

        result = await _calendarApi!.events.update(
          existingEvent,
          calendarId,
          existingEvent.id!,
        );
      } else {
        // Erstelle neues Event mit korrekter Zeitzone und angepasster Zeit
        final timeZone = await _getLocalTimeZone();
        final event = calendar.Event(
          summary: appointment.subject,
          description: appointment.notes,
          location: appointment.location,
          start: calendar.EventDateTime(
            dateTime: adjustedStartTime,
            timeZone: timeZone,
          ),
          end: calendar.EventDateTime(
            dateTime: adjustedEndTime,
            timeZone: timeZone,
          ),
          extendedProperties: calendar.EventExtendedProperties(
            private: extendedProps,
          ),
        );

        result = await _calendarApi!.events.insert(event, calendarId);
      }

      return result;
    } else {
      // Für reguläre Termine
      if (appointment.externalIdGoogle != null) {
        // Aktualisiere existierendes Event
        calendar.Event event = await _createGoogleEvent(appointment);

        // Stelle sicher, dass localAppID gesetzt ist
        if (event.extendedProperties == null) {
          event.extendedProperties = calendar.EventExtendedProperties(
            private: {'localAppID': appointment.id.toString()},
          );
        } else {
          event.extendedProperties!.private ??= {};
          event.extendedProperties!.private!['localAppID'] =
              appointment.id.toString();
        }

        return await _calendarApi!.events.update(
          event,
          calendarId,
          appointment.externalIdGoogle!,
        );
      } else {
        // Erstelle neues Event
        calendar.Event event = await _createGoogleEvent(appointment);

        // Stelle sicher, dass localAppID gesetzt ist
        if (event.extendedProperties == null) {
          event.extendedProperties = calendar.EventExtendedProperties(
            private: {'localAppID': appointment.id.toString()},
          );
        } else {
          event.extendedProperties!.private ??= {};
          event.extendedProperties!.private!['localAppID'] =
              appointment.id.toString();
        }

        return await _calendarApi!.events.insert(event, calendarId);
      }
    }
  }

  // Findet ein Event für einen Termin an einem bestimmten Datum
  Future<calendar.Event?> getEventForAppointmentOnDate(
    int appointmentId,
    DateTime date, {
    String calendarId = 'primary',
  }) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<calendar.Event> events = await fetchEventsByExtendedProperty(
      filter,
      calendarId: calendarId,
    );

    for (var event in events) {
      DateTime? eventStart = event.start?.dateTime?.toLocal();
      if (eventStart != null &&
          eventStart.year == date.year &&
          eventStart.month == date.month &&
          eventStart.day == date.day) {
        return event;
      }
    }
    return null;
  }

  // Löscht Events, die nicht zu den angegebenen Daten gehören
  Future<void> deleteEventsNotInDates({
    required int appointmentId,
    required List<DateTime> validDates,
    String calendarId = 'primary',
  }) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<calendar.Event> events = await fetchEventsByExtendedProperty(
      filter,
      calendarId: calendarId,
    );

    for (var event in events) {
      DateTime? eventStart = event.start?.dateTime?.toLocal();
      if (eventStart == null) continue;

      bool exists = validDates.any((date) =>
          date.year == eventStart.year &&
          date.month == eventStart.month &&
          date.day == eventStart.day);

      if (!exists && event.id != null) {
        await _calendarApi!.events.delete(calendarId, event.id!);
      }
    }
  }

  // Erstellt ein Google Calendar Event aus den Daten des AppointmentModels
  Future<calendar.Event> _createGoogleEvent(
      AppointmentModel appointment) async {
    // Lokale Zeitzone ermitteln
    final timeZone = await _getLocalTimeZone();

    // Start- und Endzeit mit korrekter Formatierung erstellen
    calendar.EventDateTime? startEventDateTime;
    calendar.EventDateTime? endEventDateTime;

    final start = appointment.startTime ?? DateTime.now();
    final end = appointment.endTime ?? start.add(const Duration(minutes: 30));

    if (appointment.isAllDay) {
      // Ganztägige Events
      startEventDateTime = calendar.EventDateTime(
        date: DateTime(start.year, start.month, start.day),
      );
      endEventDateTime = calendar.EventDateTime(
        date: DateTime(end.year, end.month, end.day),
      );
    } else {
      // Events mit Zeitangabe
      // Zeitprobleme umgehen: -1 Stunde für die Zeitverschiebung
      final adjustedStart = start;
      final adjustedEnd = end;

      startEventDateTime = calendar.EventDateTime(
        dateTime: adjustedStart,
        timeZone: timeZone,
      );

      endEventDateTime = calendar.EventDateTime(
        dateTime: adjustedEnd,
        timeZone: timeZone,
      );

      // Debug-Ausgabe für Zeitzonenprobleme
      debugPrint('Event Zeitzone für ${appointment.subject}:');
      debugPrint('- Originale Startzeit: ${start.toString()}');
      debugPrint('- Angepasste Startzeit: ${adjustedStart.toString()}');
      debugPrint('- Verwendete Zeitzone: $timeZone');
    }

    // Wiederholungsregel verarbeiten
    List<String>? recurrence;
    if (appointment.recurrenceRule != null &&
        appointment.recurrenceRule!.isNotEmpty) {
      String formattedRule =
          RecurrenceRuleConverter.formatRecurrenceRuleForGoogle(
        appointment.recurrenceRule!,
        start,
      );
      recurrence = [formattedRule];
      debugPrint("🔄 Formatierte Wiederholungsregel: $formattedRule");
    }

    // Erstellen des Google Calendar Events
    return calendar.Event(
      summary: appointment.subject,
      description: appointment.notes,
      location: appointment.location,
      start: startEventDateTime,
      end: endEventDateTime,
      recurrence: recurrence,
      // Optional: Farbe des Termins (wenn unterstützt)
      colorId: _getGoogleCalendarColorId(appointment.color),
      // Speichere die Muslim Calendar Termin-ID als benutzerdefinierte Eigenschaft
      extendedProperties: calendar.EventExtendedProperties(
        private: {
          'muslimcalendarID': appointment.id?.toString() ?? 'new',
          'localAppID': appointment.id?.toString() ??
              'new', // Kennzeichnung als App-exportierter Termin
        },
      ),
    );
  }

  // Wandelt Flutter-Farben in Google Calendar Farb-IDs um
  String? _getGoogleCalendarColorId(Color color) {
    // Google Calendar hat begrenzte Farboptionen (1-11)
    // Hier eine vereinfachte Zuordnung
    if (color == Colors.red) return "4"; // Rot
    if (color == Colors.blue) return "1"; // Blau
    if (color == Colors.green) return "2"; // Grün
    if (color == Colors.orange) return "6"; // Orange
    if (color == Colors.purple) return "3"; // Lila
    // Standardwert
    return "1"; // Blau
  }
}

// Hilfsklasse für die Authentifizierung
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleHttpClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
