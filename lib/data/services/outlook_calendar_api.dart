// lib/data/services/outlook_calendar_api.dart
import 'dart:convert';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:msal_auth/msal_auth.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

class OutlookCalendarApi {
  // Microsoft Graph API base URL
  static const String _graphUrl = 'https://graph.microsoft.com/v1.0';

  final String clientId;
  final String clientSecret; // Bu örnekte artık kullanılmasa da saklama yöntemine dikkat edin.
  final String redirectUrl;

  // msal_auth için SingleAccountPca örneği
  SingleAccountPca? _msalAuth;
  String? _accessToken;

  OutlookCalendarApi({
    this.clientId = '5780a779-225f-4a70-83dd-ecd78a413584',
    this.clientSecret = '',
    this.redirectUrl = 'msauth://com.example.muslim_calendar/ackRbDvBxO%2FBggu6EyZBRWAl%2B2c%3D',
  });

  /// msal_auth’ı yapılandırmak için gerekli ayarların yüklendiği metod.
  Future<void> initAuth() async {
    _msalAuth = await SingleAccountPca.create(
      clientId: clientId,
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri: redirectUrl,
      ),
      appleConfig: AppleConfig(
        authority: 'https://login.microsoftonline.com/common',
        broker: Broker.msAuthenticator,
        authorityType: AuthorityType.aad,
      ),
    );
  }

  /// Kullanıcıdan interaktif olarak oturum açmasını isteyip access token alır.
  Future<void> signIn() async {
    if (_msalAuth == null) {
      await initAuth();
    }
    final result = await _msalAuth!.acquireToken(
      scopes: ['Calendars.ReadWrite', 'offline_access'],
    );
    _accessToken = result.accessToken;
  }

  /// Sessiz token yenileme denemesi yapar; başarısız olursa interaktif oturum açma gerçekleştirir.
  Future<void> _checkAuth() async {
    if (_msalAuth == null) {
      await initAuth();
    }
    try {
      final result = await _msalAuth!.acquireTokenSilent(
        scopes: ['Calendars.ReadWrite', 'offline_access'],
      );
      _accessToken = result.accessToken;
    } catch (e) {
      // Sessiz token yenileme başarısız olursa interaktif oturum açmayı tetikler.
      await signIn();
    }
  }

  /// Oturumu kapatır.
  Future<void> signOut() async {
    if (_msalAuth != null) {
      await _msalAuth!.signOut();
    }
    _accessToken = null;
  }

  Map<String, String> get _authHeaders {
    return {'Authorization': 'Bearer $_accessToken'};
  }

  /// Kullanıcının etkinliklerini getirir.
  Future<List<dynamic>> fetchEvents() async {
    await _checkAuth();
    final response = await http.get(
      Uri.parse('$_graphUrl/me/events'),
      headers: _authHeaders,
    );
    return json.decode(response.body)['value'];
  }

  /// Belirtilen extended property anahtar ve değere göre etkinlikleri getirir.
  Future<List<dynamic>> fetchEventsByExtendedProperty(String key, String value) async {
    await _checkAuth();
    final filter =
        "singleValueExtendedProperties/Any(ep: ep/id eq '$key' and ep/value eq '$value')";
    
    final response = await http.get(
      Uri.parse('$_graphUrl/me/events?\$filter=$filter'),
      headers: _authHeaders,
    );
    
    return json.decode(response.body)['value'];
  }

  /// Yeni bir etkinlik oluşturur.
  Future<dynamic> createEvent({
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? recurrence,
    Map<String, String>? extendedProperties,
    String? location,
  }) async {
    await _checkAuth();
    
    final timeZone = await _getLocalTimeZone();
    final event = {
      'subject': summary,
      'body': {'contentType': 'text', 'content': description},
      'start': _createDateTimeTimeZone(startTime, timeZone),
      'end': _createDateTimeTimeZone(endTime, timeZone),
      'location': {'displayName': location},
      'singleValueExtendedProperties': _formatExtendedProperties(extendedProperties),
    };

    if (recurrence != null) {
      event['recurrence'] = _formatRecurrence(recurrence);
    }

    final response = await http.post(
      Uri.parse('$_graphUrl/me/events'),
      headers: _authHeaders,
      body: json.encode(event),
    );

    return json.decode(response.body);
  }

  /// Varolan bir etkinliği günceller.
  Future<dynamic> updateEvent({
    required String eventId,
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? recurrence,
    Map<String, String>? extendedProperties,
    String? location,
  }) async {
    await _checkAuth();

    final timeZone = await _getLocalTimeZone();
    final event = {
      'subject': summary,
      'body': {'contentType': 'text', 'content': description},
      'start': _createDateTimeTimeZone(startTime, timeZone),
      'end': _createDateTimeTimeZone(endTime, timeZone),
      'location': {'displayName': location},
      'singleValueExtendedProperties': _formatExtendedProperties(extendedProperties),
    };

    if (recurrence != null) {
      event['recurrence'] = _formatRecurrence(recurrence);
    }

    final response = await http.patch(
      Uri.parse('$_graphUrl/me/events/$eventId'),
      headers: _authHeaders,
      body: json.encode(event),
    );

    return json.decode(response.body);
  }

  /// Belirtilen etkinliği siler.
  Future<void> deleteEvent(String eventId) async {
    await _checkAuth();
    await http.delete(
      Uri.parse('$_graphUrl/me/events/$eventId'),
      headers: _authHeaders,
    );
  }

  /// Belirtilen tarih için randevuyla eşleşen etkinliği getirir.
  Future<dynamic> getEventForAppointmentOnDate(int appointmentId, DateTime date) async {
    final filter =
        "singleValueExtendedProperties/Any(ep: ep/id eq 'muslimcalendarID' and ep/value eq '$appointmentId')";
    
    final response = await http.get(
      Uri.parse('$_graphUrl/me/events?\$filter=$filter'),
      headers: _authHeaders,
    );

    final events = json.decode(response.body)['value'];
    for (var event in events) {
      final eventStart = DateTime.parse(event['start']['dateTime']);
      if (eventStart.year == date.year &&
          eventStart.month == date.month &&
          eventStart.day == date.day) {
        return event;
      }
    }
    return null;
  }

  /// Randevuya bağlı etkinliği senkronize eder; güncelleme veya oluşturma işlemi gerçekleştirir.
  Future<dynamic> syncAppointmentEvent({
    required AppointmentModel appointment,
    required DateTime startTime,
    required DateTime endTime,
    required bool prayerRelated,
  }) async {
    if (prayerRelated) {
      final extendedProps = {'muslimcalendarID': appointment.id.toString()};
      final existingEvent = await getEventForAppointmentOnDate(appointment.id!, startTime);
      if (existingEvent != null) {
        return await updateEvent(
          eventId: existingEvent['id'],
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
      List<String>? recurrence;
      if (appointment.recurrenceRule != null && appointment.recurrenceRule!.isNotEmpty) {
        recurrence = [appointment.recurrenceRule!];
      }

      if (appointment.externalIdOutlook != null) {
        return await updateEvent(
          eventId: appointment.externalIdOutlook!,
          summary: appointment.subject,
          description: appointment.notes ?? '',
          startTime: startTime,
          endTime: endTime,
          location: appointment.location,
          recurrence: recurrence,
        );
      } else {
        final createdEvent = await createEvent(
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

  /// Belirtilen randevu ID'sine ait, geçerli tarihler dışında kalan etkinlikleri siler.
  Future<void> deleteEventsNotInDates({
    required int appointmentId,
    required List<DateTime> validDates,
  }) async {
    final filter =
        "singleValueExtendedProperties/Any(ep: ep/id eq 'muslimcalendarID' and ep/value eq '$appointmentId')";
    
    final response = await http.get(
      Uri.parse('$_graphUrl/me/events?\$filter=$filter'),
      headers: _authHeaders,
    );

    final events = json.decode(response.body)['value'];
    for (var event in events) {
      final eventStart = DateTime.parse(event['start']['dateTime']);
      final exists = validDates.any((date) =>
          date.year == eventStart.year &&
          date.month == eventStart.month &&
          date.day == eventStart.day);
      if (!exists) {
        await deleteEvent(event['id']);
      }
    }
  }

  Future<String> _getLocalTimeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      return 'UTC';
    }
  }

  Map<String, dynamic> _createDateTimeTimeZone(DateTime dateTime, String timeZone) {
    return {
      'dateTime': dateTime.toIso8601String(),
      'timeZone': timeZone,
    };
  }

  List<dynamic>? _formatExtendedProperties(Map<String, String>? extendedProperties) {
    if (extendedProperties == null) return null;
    return extendedProperties.entries.map((entry) {
      return {
        'id': 'String ${entry.key}',
        'value': entry.value,
      };
    }).toList();
  }

  Map<String, dynamic>? _formatRecurrence(List<String>? recurrence) {
    if (recurrence == null || recurrence.isEmpty) return null;
    return {
      'pattern': {
        'type': 'daily', // Örnek olarak günlük tekrar
        'interval': 1,
      },
      'range': {
        'type': 'noEnd',
      },
    };
  }
}
