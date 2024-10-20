import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


Future<Position?> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return null;
  }

  return await Geolocator.getCurrentPosition();
}
 Future<Map<String, DateTime>> fetchPrayerTimes(Position position, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String cacheKey = '${date.year}-${date.month}-${date.day}-${position.latitude}-${position.longitude}';
    String? cachedTimes = prefs.getString(cacheKey);

    if (cachedTimes != null) {
      return Map<String, DateTime>.from(jsonDecode(cachedTimes));
    }

    // Fetch prayer times from API
    final String apiUrl = 'https://api.aladhan.com/v1/timings/${date.day}-${date.month}-${date.year}?latitude=${position.latitude}&longitude=${position.longitude}&method=3';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Map<String, DateTime> prayerTimes = {
        'fajr': DateTime.parse(data['data']['timings']['Fajr']),
        'dhuhr': DateTime.parse(data['data']['timings']['Dhuhr']),
        'asr': DateTime.parse(data['data']['timings']['Asr']),
        'maghrib': DateTime.parse(data['data']['timings']['Maghrib']),
        'isha': DateTime.parse(data['data']['timings']['Isha']),
      };

      // Cache the prayer times
      prefs.setString(cacheKey, jsonEncode(prayerTimes));
      return prayerTimes;
    } else {
      throw Exception('Failed to load prayer times');
    }
  }

Future<DateTime> getPrayerTimeForDate(DateTime date, PrayerTime prayerTime) async {
  Position? position = await _determinePosition();

  if (position != null) {
    try {
      Map<String, DateTime> prayerTimes = await fetchPrayerTimes(position, date);
      switch (prayerTime) {
        case PrayerTime.fajr:
          return prayerTimes['fajr']!;
        case PrayerTime.dhuhr:
          return prayerTimes['dhuhr']!;
        case PrayerTime.asr:
          return prayerTimes['asr']!;
        case PrayerTime.maghrib:
          return prayerTimes['maghrib']!;
        case PrayerTime.isha:
          return prayerTimes['isha']!;
        default:
          return date;
      }
    } catch (e) {
      // Handle exceptions and fallback to default times
    }
  }

  // Default prayer times if location or internet access is denied
  switch (prayerTime) {
    case PrayerTime.fajr:
      return DateTime(date.year, date.month, date.day, 5, 0);
    case PrayerTime.dhuhr:
      return DateTime(date.year, date.month, date.day, 12, 0);
    case PrayerTime.asr:
      return DateTime(date.year, date.month, date.day, 15, 0);
    case PrayerTime.maghrib:
      return DateTime(date.year, date.month, date.day, 18, 0);
    case PrayerTime.isha:
      return DateTime(date.year, date.month, date.day, 20, 0);
    default:
      return date;
  }
}

Future<List<Appointment>> loadAppointments() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> appointmentList = prefs.getStringList('appointments') ?? [];
  List<Appointment> visibleAppointments = [];
  DateTime today = DateTime.now();

  for (String appointmentStr in appointmentList) {
    final appointmentData = jsonDecode(appointmentStr);
    Appointment appointment = Appointment(
      startTime: DateTime.parse(appointmentData['startTime']),
      endTime: DateTime.parse(appointmentData['endTime']),
      isAllDay: appointmentData['isAllDay'],
      subject: appointmentData['subject'],
      notes: appointmentData['notes'],
      location: appointmentData['location'],
      color: Color(int.parse(appointmentData['color'])),
      isRecurring: appointmentData['isRecurring'],
      isRelatedToPrayerTimes: appointmentData['isRelatedToPrayerTimes'],
      repeatInterval: appointmentData['repeatInterval'],
      repeatFrequency: appointmentData['repeatFrequency'] != null
          ? RepeatFrequency.values[appointmentData['repeatFrequency']]
          : null,
      repeatEndDate: appointmentData['repeatEndDate'] != null
          ? DateTime.parse(appointmentData['repeatEndDate'])
          : null,
      prayerTime: appointmentData['prayerTime'] != null
          ? PrayerTime.values[appointmentData['prayerTime']]
          : null,
      timeRelation: appointmentData['timeRelation'] != null
          ? TimeRelation.values[appointmentData['timeRelation']]
          : null,
      offsetDuration: appointmentData['offsetDuration'] != null
          ? Duration(minutes: appointmentData['offsetDuration'])
          : null,
      duration: appointmentData['duration'] != null
          ? Duration(minutes: appointmentData['duration'])
          : null,
    );

    if (appointment.isRelatedToPrayerTimes && appointment.prayerTime != null) {
      DateTime prayerTime = await getPrayerTimeForDate(appointment.startTime, appointment.prayerTime!);
      final offset = appointment.offsetDuration ?? Duration();
      final duration = appointment.duration ?? Duration();

      if (appointment.timeRelation == TimeRelation.before) {
        appointment.startTime = prayerTime.subtract(offset);
        appointment.endTime = appointment.startTime.add(duration);
      } else {
        appointment.startTime = prayerTime.add(offset);
        appointment.endTime = appointment.startTime.add(duration);
      }
    }

    if (!appointment.isRecurring) {
      visibleAppointments.add(appointment);
    } else {
      DateTime recurrenceDate = appointment.startTime;
      while (recurrenceDate.isBefore(appointment.repeatEndDate ?? today.add(Duration(days: 365)))) {
        if (recurrenceDate.isAfter(today.subtract(Duration(days: 365))) && shouldDisplayEvent(appointment, recurrenceDate)) {
          visibleAppointments.add(Appointment(
            startTime: recurrenceDate,
            endTime: recurrenceDate.add(appointment.endTime.difference(appointment.startTime)),
            isAllDay: appointment.isAllDay,
            subject: appointment.subject,
            notes: appointment.notes,
            location: appointment.location,
            color: appointment.color,
            isRecurring: appointment.isRecurring,
            isRelatedToPrayerTimes: appointment.isRelatedToPrayerTimes,
          ));
        }
        recurrenceDate = getNextRecurrenceDate(recurrenceDate, appointment.repeatFrequency!, appointment.repeatInterval!);
      }
    }
  }
  return visibleAppointments;
}

DateTime getNextRecurrenceDate(DateTime currentDate, RepeatFrequency frequency, int interval) {
  switch (frequency) {
    case RepeatFrequency.daily:
      return currentDate.add(Duration(days: interval));
    case RepeatFrequency.weekly:
      return currentDate.add(Duration(days: 7 * interval));
    case RepeatFrequency.monthly:
      return DateTime(currentDate.year, currentDate.month + interval, currentDate.day);
    default:
      return currentDate;
  }
}

bool shouldDisplayEvent(Appointment appointment, DateTime currentDate) {
  final difference = currentDate.difference(appointment.startTime).inDays;
  if (appointment.repeatInterval == null || appointment.repeatFrequency == null) {
    return false;
  }

  switch (appointment.repeatFrequency) {
    case RepeatFrequency.daily:
      return difference % appointment.repeatInterval! == 0;
    case RepeatFrequency.weekly:
      return difference % (7 * appointment.repeatInterval!) == 0;
    case RepeatFrequency.monthly:
      return currentDate.day == appointment.startTime.day &&
          ((currentDate.year * 12 + currentDate.month) - 
           (appointment.startTime.year * 12 + appointment.startTime.month)) % appointment.repeatInterval! == 0;
    default:
      return false;
  }
}


class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}