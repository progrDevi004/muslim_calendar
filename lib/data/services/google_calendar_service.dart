// lib/data/services/google_calendar_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;

  GoogleCalendarService._internal() {
    // Leerer Konstruktor für Singleton
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
                  event != null &&
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
      return await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      return 'UTC';
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

    // Wenn der Termin bereits eine Google-ID hat, aktualisieren
    if (appointment.externalIdGoogle != null) {
      bool success = await updateEventInGoogleCalendar(appointment);
      return success ? appointment.externalIdGoogle : null;
    } else {
      // Ansonsten neuen Termin erstellen
      return await addEventToGoogleCalendar(appointment);
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

    if (prayerRelated) {
      // Für gebetszeitbezogene Termine
      Map<String, String> extendedProps = {
        'muslimcalendarID': appointment.id.toString()
      };

      // Prüfen, ob bereits ein Event für diesen Termin und dieses Datum existiert
      calendar.Event? existingEvent = await getEventForAppointmentOnDate(
        appointment.id!,
        startTime,
        calendarId: calendarId,
      );

      calendar.Event result;

      if (existingEvent != null) {
        // Aktualisiere existierendes Event
        existingEvent.summary = appointment.subject;
        existingEvent.description = appointment.notes;
        existingEvent.location = appointment.location;

        // Neu setzen von Start- und Endzeit
        final timeZone = await _getLocalTimeZone();
        existingEvent.start = calendar.EventDateTime(
          dateTime: startTime,
          timeZone: timeZone,
        );
        existingEvent.end = calendar.EventDateTime(
          dateTime: endTime,
          timeZone: timeZone,
        );

        result = await _calendarApi!.events.update(
          existingEvent,
          calendarId,
          existingEvent.id!,
        );
      } else {
        // Erstelle neues Event
        final timeZone = await _getLocalTimeZone();
        final event = calendar.Event(
          summary: appointment.subject,
          description: appointment.notes,
          location: appointment.location,
          start: calendar.EventDateTime(
            dateTime: startTime,
            timeZone: timeZone,
          ),
          end: calendar.EventDateTime(
            dateTime: endTime,
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
        return await _calendarApi!.events.update(
          event,
          calendarId,
          appointment.externalIdGoogle!,
        );
      } else {
        // Erstelle neues Event
        calendar.Event event = await _createGoogleEvent(appointment);
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

  // Wandelt einen Muslim Calendar Termin in ein Google Calendar Event um
  Future<calendar.Event> _createGoogleEvent(
      AppointmentModel appointment) async {
    // Zeitformatierung
    final start = appointment.startTime;
    final end = appointment.endTime;
    final timeZone = await _getLocalTimeZone();

    calendar.EventDateTime? startEventDateTime;
    calendar.EventDateTime? endEventDateTime;

    if (appointment.isAllDay) {
      // Ganztägige Termine
      startEventDateTime = calendar.EventDateTime(
        date: DateTime(start!.year, start.month, start.day),
      );

      // Bei ganztägigen Terminen muss das Enddatum +1 Tag sein in Google Calendar
      final endDate = end?.add(const Duration(days: 1)) ??
          start.add(const Duration(days: 1));

      endEventDateTime = calendar.EventDateTime(
        date: DateTime(endDate.year, endDate.month, endDate.day),
      );
    } else {
      // Termine mit Zeitangabe
      startEventDateTime = calendar.EventDateTime(
        dateTime: start,
        timeZone: timeZone,
      );

      endEventDateTime = calendar.EventDateTime(
        dateTime: end ?? start?.add(const Duration(minutes: 30)),
        timeZone: timeZone,
      );
    }

    // Wiederholungsregel verarbeiten
    List<String>? recurrence;
    if (appointment.recurrenceRule != null &&
        appointment.recurrenceRule!.isNotEmpty) {
      String formattedRule = _formatRecurrenceRuleForGoogle(
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
        private: {'muslimcalendarID': appointment.id?.toString() ?? 'new'},
      ),
    );
  }

  // Formatiert die Wiederholungsregel für Google Calendar
  String _formatRecurrenceRuleForGoogle(
      String recurrenceRule, DateTime? startDate) {
    debugPrint("🔄 Originale Wiederholungsregel: $recurrenceRule");

    // Stellen Sie sicher, dass die Regel mit 'RRULE:' beginnt
    if (!recurrenceRule.startsWith('RRULE:')) {
      recurrenceRule = 'RRULE:$recurrenceRule';
    }

    // Entferne Leerzeichen und doppelte Semikolons
    recurrenceRule =
        recurrenceRule.replaceAll(' ', '').replaceAll(';;', ';').toUpperCase();

    // Prüfe, ob die Regel 'FREQ=WEEKLY' enthält, aber kein 'BYDAY'
    if (recurrenceRule.contains('FREQ=WEEKLY') &&
        !recurrenceRule.contains('BYDAY')) {
      // Wenn ein Startdatum vorhanden ist, fügen wir den entsprechenden Wochentag hinzu
      if (startDate != null) {
        String weekday = _getWeekdayFromDate(startDate);
        recurrenceRule = '${recurrenceRule};BYDAY=$weekday';
      }
    }

    // Stelle sicher, dass bei 'FREQ=WEEKLY' ein 'INTERVAL' vorhanden ist
    if (recurrenceRule.contains('FREQ=WEEKLY') &&
        !recurrenceRule.contains('INTERVAL')) {
      recurrenceRule = '${recurrenceRule};INTERVAL=1';
    }

    // Bei monatlichen Wiederholungen mit BYDAY, aber ohne BYSETPOS
    if (recurrenceRule.contains('FREQ=MONTHLY') &&
        recurrenceRule.contains('BYDAY=') &&
        !recurrenceRule.contains('BYSETPOS=')) {
      // Standardmäßig das erste Vorkommen im Monat verwenden
      recurrenceRule = '${recurrenceRule};BYSETPOS=1';
    }

    return recurrenceRule;
  }

  // Hilfsmethode: Gibt den Wochentag als String im iCalendar-Format zurück
  String _getWeekdayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'MO';
      case DateTime.tuesday:
        return 'TU';
      case DateTime.wednesday:
        return 'WE';
      case DateTime.thursday:
        return 'TH';
      case DateTime.friday:
        return 'FR';
      case DateTime.saturday:
        return 'SA';
      case DateTime.sunday:
        return 'SU';
      default:
        return 'MO'; // Fallback
    }
  }

  // Wandelt Flutter-Farben in Google Calendar Farb-IDs um
  String? _getGoogleCalendarColorId(Color color) {
    // Google Calendar hat begrenzte Farboptionen (1-11)
    // Hier eine vereinfachte Zuordnung
    if (color.value == Colors.red.value) return "4"; // Rot
    if (color.value == Colors.blue.value) return "1"; // Blau
    if (color.value == Colors.green.value) return "2"; // Grün
    if (color.value == Colors.orange.value) return "6"; // Orange
    if (color.value == Colors.purple.value) return "3"; // Lila
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
