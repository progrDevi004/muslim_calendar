// lib/data/services/outlook_calendar_api.dart
import 'dart:convert';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:muslim_calendar/models/appointment_model.dart';

class OutlookCalendarApi {
  // Azure AD configuration
  static const String _authority = 'login.microsoftonline.com';
  static const String _tokenPath = '/c3517793-4c85-4977-ac5a-2c919bcccf8f/oauth2/v2.0/token';
  static const String _graphUrl = 'https://graph.microsoft.com/v1.0';

  // Package info for Android
  static const String _packageName = 'com.example.muslim_calendar';
  static const String _signatureHash = 'Bmce+9aHdOoVtE7fS3B07tfj7Bc=';

  final String clientId;
  final String clientSecret; // Note: Client secret should be stored securely
  final String redirectUrl;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiration;

  OutlookCalendarApi({
    this.clientId = '5780a779-225f-4a70-83dd-ecd78a413584',
    this.clientSecret = '', // Client secret should be provided through secure means
    this.redirectUrl = 'msauth://com.example.muslim_calendar/Bmce%2B9aHdOoVtE7fS3B07tfj7Bc%3D',
  });
  

  Future<void> signIn(String code) async {
    final response = await http.post(
      Uri.https(_authority, _tokenPath),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUrl,
        'grant_type': 'authorization_code',
        'scope': 'Calendars.ReadWrite offline_access',
      },
    );

    _handleTokenResponse(response);
  }

  Future<void> autoSignIn() async {
    if (_refreshToken == null) return;
    
    final response = await http.post(
      Uri.https(_authority, _tokenPath),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': _refreshToken,
        'grant_type': 'refresh_token',
        'scope': 'Calendars.ReadWrite offline_access',
      },
    );

    _handleTokenResponse(response);
  }

  void _handleTokenResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      _tokenExpiration = DateTime.now().add(
        Duration(seconds: data['expires_in']),
      );
    } else {
      throw Exception('Authentication failed: ${response.body}');
    }
  }

  Future<bool> isSignedIn() async {
    return _accessToken != null && 
        _tokenExpiration?.isAfter(DateTime.now()) == true;
  }

  Future<void> signOut() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiration = null;
    return Future.value();
  }

  Future<List<dynamic>> fetchEvents() async {
    await _checkAuth();
    final response = await http.get(
      Uri.parse('$_graphUrl/me/events'),
      headers: _authHeaders,
    );
    return json.decode(response.body)['value'];
  }

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

  Future<void> deleteEvent(String eventId) async {
    await _checkAuth();
    await http.delete(
      Uri.parse('$_graphUrl/me/events/$eventId'),
      headers: _authHeaders,
    );
  }

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
      if (appointment.recurrenceRule != null && 
          appointment.recurrenceRule!.isNotEmpty) {
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

  Map<String, String> get _authHeaders {
    return {'Authorization': 'Bearer $_accessToken'};
  }

  Future<void> _checkAuth() async {
    if (_accessToken == null || _tokenExpiration?.isBefore(DateTime.now()) == true) {
      await autoSignIn();
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