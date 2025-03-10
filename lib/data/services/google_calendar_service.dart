// lib/data/services/google_calendar_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:http/http.dart' as http;
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  CalendarApi? _calendarApi;
  final AppLocalizations _localizations;

  GoogleCalendarService({required AppLocalizations localizations})
      : _localizations = localizations;

  /// Prüft, ob der Nutzer eingeloggt ist
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Temel sign-in işlemleri
  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
      if (_googleSignIn.currentUser != null) {
        var auth = await _googleSignIn.currentUser!.authentication;
        var client = GoogleAuthClient(auth.accessToken!);
        _calendarApi = CalendarApi(client);
      } else {
        throw Exception(_localizations.signInRequired);
      }
    } catch (error) {
      debugPrint('${_localizations.googleSignInError}: $error');
      throw Exception('${_localizations.googleSignInError}: $error');
    }
  }

  Future<void> autoSignIn() async {
    try {
      if (_googleSignIn.currentUser != null) {
        var auth = await _googleSignIn.currentUser!.authentication;
        var client = GoogleAuthClient(auth.accessToken!);
        _calendarApi = CalendarApi(client);
      } else {
        await signIn();
      }
    } catch (error) {
      debugPrint('${_localizations.googleSignInError}: $error');
      throw Exception('${_localizations.syncError(error.toString())}');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _calendarApi = null;
  }

  /// Liste aller verfügbaren Kalender abrufen
  Future<List<CalendarListEntry>> fetchCalendarList() async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);
    var calendarList = await _calendarApi!.calendarList.list();
    return calendarList.items ?? [];
  }

  /// Temel: Tüm event'leri getirir.
  Future<List<Event>> fetchEvents({String calendarId = 'primary'}) async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);

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

      debugPrint(
          "🔍 ${events.items?.length ?? 0} Events gefunden, ${validEvents.length} valide Events");
      return validEvents;
    } catch (e) {
      debugPrint("⚠️ Fehler beim Abrufen der Events: $e");
      return [];
    }
  }

  /// Temel: Extended property filtresiyle event'leri getirir.
  Future<List<Event>> fetchEventsByExtendedProperty(String extendedProperty,
      {String calendarId = 'primary'}) async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);
    var events = await _calendarApi!.events.list(
      calendarId,
      // Google API'da filtreleme "key=value" formatında yapılır.
      privateExtendedProperty: [extendedProperty],
    );
    return events.items ?? [];
  }

  Future<String> _getLocalTimeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      return 'UTC';
    }
  }

  Future<Event> createEvent({
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? recurrence,
    Map<String, String>? extendedProperties,
    String? location,
    String calendarId = 'primary',
  }) async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);

    // Cihazın saat dilimini alıyoruz.
    final timeZone = await _getLocalTimeZone();

    var event = Event()
      ..summary = summary
      ..description = description
      ..start = EventDateTime(
        dateTime: startTime,
        timeZone: timeZone,
      )
      ..end = EventDateTime(
        dateTime: endTime,
        timeZone: timeZone,
      )
      ..recurrence = recurrence
      ..location = location;

    if (extendedProperties != null) {
      event.extendedProperties =
          EventExtendedProperties(private: extendedProperties);
    }

    var createdEvent = await _calendarApi!.events.insert(event, calendarId);
    return createdEvent;
  }

  /// Temel: Var olan event'i günceller.
  Future<Event> updateEvent({
    required String eventId,
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? recurrence,
    Map<String, String>? extendedProperties,
    String? location,
    String calendarId = 'primary',
  }) async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);

    // Cihazın saat dilimini alıyoruz.
    final timeZone = await _getLocalTimeZone();

    var event = await _calendarApi!.events.get(calendarId, eventId);
    event
      ..summary = summary
      ..description = description
      ..start = EventDateTime(
        dateTime: startTime,
        timeZone: timeZone,
      )
      ..end = EventDateTime(
        dateTime: endTime,
        timeZone: timeZone,
      )
      ..recurrence = recurrence
      ..location = location;

    if (extendedProperties != null) {
      event.extendedProperties =
          EventExtendedProperties(private: extendedProperties);
    }

    var updatedEvent =
        await _calendarApi!.events.update(event, calendarId, eventId);
    return updatedEvent;
  }

  /// Temel: Event'i siler.
  Future<void> deleteEvent(String eventId,
      {String calendarId = 'primary'}) async {
    if (_calendarApi == null) throw Exception(_localizations.notSignedIn);
    await _calendarApi!.events.delete(calendarId, eventId);
  }

  // ––––––– Ortak Kullanıma Uygun Fonksiyonlar –––––––

  /// Opsiyonel: Extended property filtresi parametresine göre event'leri getirir.
  Future<List<Event>> fetchCalendarEvents({
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

  /// Belirli bir tarih için (prayer-related) appointment event'ini getirir.
  Future<Event?> getEventForAppointmentOnDate(int appointmentId, DateTime date,
      {String calendarId = 'primary'}) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<Event> events =
        await fetchEventsByExtendedProperty(filter, calendarId: calendarId);
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

  /// Verilen appointment için (normal veya prayer-related) event'i oluşturup/günceller.
  ///
  /// - [prayerRelated] true ise, event extended property olarak 'muslimcalendarID' içerir.
  /// - false ise, appointment.externalIdGoogle üzerinden var olan event güncellenir ya da yenisi oluşturulur.
  Future<Event> syncAppointmentEvent({
    required AppointmentModel appointment,
    required DateTime startTime,
    required DateTime endTime,
    required bool prayerRelated,
    String calendarId = 'primary',
  }) async {
    if (prayerRelated) {
      // Namaz vakitlerine bağlı işlemler (extended properties vs.) burada yapılır.
      Map<String, String> extendedProps = {
        'muslimcalendarID': appointment.id.toString()
      };
      Event? existingEvent = await getEventForAppointmentOnDate(
          appointment.id!, startTime,
          calendarId: calendarId);
      if (existingEvent != null) {
        return await updateEvent(
          eventId: existingEvent.id!,
          summary: appointment.subject,
          description: appointment.notes ?? '',
          startTime: startTime,
          endTime: endTime,
          extendedProperties: extendedProps,
          location: appointment.location,
          calendarId: calendarId,
        );
      } else {
        return await createEvent(
          summary: appointment.subject,
          description: appointment.notes ?? '',
          startTime: startTime,
          endTime: endTime,
          extendedProperties: extendedProps,
          location: appointment.location,
          calendarId: calendarId,
        );
      }
    } else {
      // Namaz vakitlerine bağlı olmayan appointment için:
      // Recurrence bilgisini kontrol ediyoruz.
      List<String>? recurrence;
      if (appointment.recurrenceRule != null &&
          appointment.recurrenceRule!.isNotEmpty) {
        // Prüfen und korrigieren der Wiederholungsregel vor dem Export
        String correctedRule = appointment.recurrenceRule!;

        // Bei wöchentlichen Terminen muss BYDAY vorhanden sein
        if (correctedRule.contains('FREQ=WEEKLY') &&
            !correctedRule.contains('BYDAY=')) {
          // Wochentag aus dem Startdatum ermitteln
          String weekday;
          switch (startTime.weekday) {
            case DateTime.monday:
              weekday = 'MO';
              break;
            case DateTime.tuesday:
              weekday = 'TU';
              break;
            case DateTime.wednesday:
              weekday = 'WE';
              break;
            case DateTime.thursday:
              weekday = 'TH';
              break;
            case DateTime.friday:
              weekday = 'FR';
              break;
            case DateTime.saturday:
              weekday = 'SA';
              break;
            case DateTime.sunday:
              weekday = 'SU';
              break;
            default:
              weekday = 'MO'; // Standardwert
          }

          debugPrint(
              '📅 Korrigiere wöchentliche Wiederholung: Füge BYDAY=$weekday hinzu');
          // Vor dem UNTIL-Parameter oder am Ende einfügen
          if (correctedRule.contains('UNTIL=')) {
            correctedRule =
                correctedRule.replaceFirst('UNTIL=', 'BYDAY=$weekday;UNTIL=');
          } else {
            correctedRule = '$correctedRule;BYDAY=$weekday';
          }
        }

        recurrence = [correctedRule];
        debugPrint(
            '📅 Exportiere Termin mit Wiederholungsregel: $correctedRule');
      }

      if (appointment.externalIdGoogle != null) {
        return await updateEvent(
          eventId: appointment.externalIdGoogle!,
          summary: appointment.subject,
          description: appointment.notes ?? '',
          startTime: startTime,
          endTime: endTime,
          location: appointment.location,
          recurrence: recurrence,
          calendarId: calendarId,
        );
      } else {
        Event createdEvent = await createEvent(
          summary: appointment.subject,
          description: appointment.notes ?? '',
          startTime: startTime,
          endTime: endTime,
          location: appointment.location,
          recurrence: recurrence,
          calendarId: calendarId,
        );
        return createdEvent;
      }
    }
  }

  /// Prayer-related appointment'a ait, geçerli tarihler dışında kalan event'leri siler.
  Future<void> deleteEventsNotInDates({
    required int appointmentId,
    required List<DateTime> validDates,
    String calendarId = 'primary',
  }) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<Event> events =
        await fetchEventsByExtendedProperty(filter, calendarId: calendarId);
    for (var event in events) {
      DateTime? eventStart = event.start?.dateTime?.toLocal();
      if (eventStart == null) continue;
      bool exists = validDates.any((date) =>
          date.year == eventStart.year &&
          date.month == eventStart.month &&
          date.day == eventStart.day);
      if (!exists) {
        await deleteEvent(event.id!, calendarId: calendarId);
      }
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(String token)
      : _headers = {'Authorization': 'Bearer $token'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
