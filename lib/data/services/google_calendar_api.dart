// lib/data/services/google_calendar_api.dart
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:http/http.dart' as http;
import 'package:muslim_calendar/models/appointment_model.dart';

class GoogleCalendarApi {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  CalendarApi? _calendarApi;

  /// Temel sign-in işlemleri
  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
      var auth = await _googleSignIn.currentUser!.authentication;
      var client = GoogleAuthClient(auth.accessToken!);
      _calendarApi = CalendarApi(client);
    } catch (error) {
      print('Google Sign-In Error: $error');
      throw error;
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
      print('Google Sign-In Error: $error');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _calendarApi = null;
  }

  /// Temel: Tüm event’leri getirir.
  Future<List<Event>> fetchEvents() async {
    if (_calendarApi == null) throw Exception('Not signed in');
    var events = await _calendarApi!.events.list('primary');
    return events.items ?? [];
  }

  /// Temel: Extended property filtresiyle event’leri getirir.
  Future<List<Event>> fetchEventsByExtendedProperty(String extendedProperty) async {
    if (_calendarApi == null) throw Exception('Not signed in');
    var events = await _calendarApi!.events.list(
      'primary',
      // Google API’da filtreleme "key=value" formatında yapılır.
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
  }) async {
    if (_calendarApi == null) throw Exception('Not signed in');

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
      event.extendedProperties = EventExtendedProperties(private: extendedProperties);
    }

    var createdEvent = await _calendarApi!.events.insert(event, 'primary');
    return createdEvent;
  }

  /// Temel: Var olan event’i günceller.
  Future<Event> updateEvent({
    required String eventId,
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? recurrence,
    Map<String, String>? extendedProperties,
    String? location,
  }) async {
    if (_calendarApi == null) throw Exception('Not signed in');

    // Cihazın saat dilimini alıyoruz.
    final timeZone = await _getLocalTimeZone();

    var event = await _calendarApi!.events.get('primary', eventId);
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
      event.extendedProperties = EventExtendedProperties(private: extendedProperties);
    }

    var updatedEvent = await _calendarApi!.events.update(event, 'primary', eventId);
    return updatedEvent;
  }

  /// Temel: Event’i siler.
  Future<void> deleteEvent(String eventId) async {
    if (_calendarApi == null) throw Exception('Not signed in');
    await _calendarApi!.events.delete('primary', eventId);
  }

  // ––––––– Ortak Kullanıma Uygun Fonksiyonlar –––––––

  /// Opsiyonel: Extended property filtresi parametresine göre event’leri getirir.
  Future<List<Event>> fetchCalendarEvents({String? extendedProperty}) async {
    if (extendedProperty != null) {
      return fetchEventsByExtendedProperty(extendedProperty);
    } else {
      return fetchEvents();
    }
  }

  /// Belirli bir tarih için (prayer-related) appointment event’ini getirir.
  Future<Event?> getEventForAppointmentOnDate(int appointmentId, DateTime date) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<Event> events = await fetchEventsByExtendedProperty(filter);
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

  /// Verilen appointment için (normal veya prayer-related) event’i oluşturup/günceller.
  ///
  /// - [prayerRelated] true ise, event extended property olarak 'muslimcalendarID' içerir.
  /// - false ise, appointment.externalIdGoogle üzerinden var olan event güncellenir ya da yenisi oluşturulur.
  Future<Event> syncAppointmentEvent({
  required AppointmentModel appointment,
  required DateTime startTime,
  required DateTime endTime,
  required bool prayerRelated,
}) async {
  if (prayerRelated) {
    // Namaz vakitlerine bağlı işlemler (extended properties vs.) burada yapılır.
    Map<String, String> extendedProps = {'muslimcalendarID': appointment.id.toString()};
    Event? existingEvent = await getEventForAppointmentOnDate(appointment.id!, startTime);
    if (existingEvent != null) {
      return await updateEvent(
        eventId: existingEvent.id!,
        summary: appointment.subject,
        description: appointment.notes ?? '',
        startTime: startTime,
        endTime: endTime,
        extendedProperties: extendedProps,
        location: appointment.location,
      );
    } else {
      return await createEvent(
        summary: appointment.subject,
        description: appointment.notes ?? '',
        startTime: startTime,
        endTime: endTime,
        extendedProperties: extendedProps,
        location: appointment.location,
      );
    }
  } else {
    // Namaz vakitlerine bağlı olmayan appointment için:
    // Recurrence bilgisini kontrol ediyoruz.
    List<String>? recurrence;
    if (appointment.recurrenceRule != null && appointment.recurrenceRule!.isNotEmpty) {
      recurrence = [appointment.recurrenceRule!];
      print(appointment.subject);
      print(appointment.recurrenceRule);
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
      );
    } else {
      Event createdEvent = await createEvent(
        summary: appointment.subject,
        description: appointment.notes ?? '',
        startTime: startTime,
        endTime: endTime,
        location: appointment.location,
        recurrence: recurrence,
      );
      return createdEvent;
    }
  }
}


  /// Prayer-related appointment’a ait, geçerli tarihler dışında kalan event’leri siler.
  Future<void> deleteEventsNotInDates({
    required int appointmentId,
    required List<DateTime> validDates,
  }) async {
    String filter = 'muslimcalendarID=$appointmentId';
    List<Event> events = await fetchEventsByExtendedProperty(filter);
    for (var event in events) {
      DateTime? eventStart = event.start?.dateTime?.toLocal();
      if (eventStart == null) continue;
      bool exists = validDates.any((date) =>
          date.year == eventStart.year &&
          date.month == eventStart.month &&
          date.day == eventStart.day);
      if (!exists) {
        await deleteEvent(event.id!);
      }
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(String token) : _headers = {'Authorization': 'Bearer $token'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
