import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;

Future<Map<String, List<DateTime>>> fetchPrayerTimes(String city, String country, int year, int month) async {
  final prefs = await SharedPreferences.getInstance();
  String cacheKey = '$year-$month-$city-$country';
  String? cachedTimes = prefs.getString(cacheKey);

  if (cachedTimes != null) {
    return Map<String, List<DateTime>>.from(json.decode(cachedTimes));
  }

  final String apiUrl = 'https://api.aladhan.com/v1/calendarByAddress/$year/$month?address=$city,$country';
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    Map<String, List<DateTime>> prayerTimes = {
      'fajr': [],
      'dhuhr': [],
      'asr': [],
      'maghrib': [],
      'isha': [],
    };

    for (var day in data['data']) {
      DateTime date = DateTime.parse(day['date']['gregorian']['date']);
      prayerTimes['fajr']!.add(DateTime(date.year, date.month, date.day, 
          int.parse(day['timings']['Fajr'].split(':')[0]), 
          int.parse(day['timings']['Fajr'].split(':')[1])));
      prayerTimes['dhuhr']!.add(DateTime(date.year, date.month, date.day, 
          int.parse(day['timings']['Dhuhr'].split(':')[0]), 
          int.parse(day['timings']['Dhuhr'].split(':')[1])));
      prayerTimes['asr']!.add(DateTime(date.year, date.month, date.day, 
          int.parse(day['timings']['Asr'].split(':')[0]), 
          int.parse(day['timings']['Asr'].split(':')[1])));
      prayerTimes['maghrib']!.add(DateTime(date.year, date.month, date.day, 
          int.parse(day['timings']['Maghrib'].split(':')[0]), 
          int.parse(day['timings']['Maghrib'].split(':')[1])));
      prayerTimes['isha']!.add(DateTime(date.year, date.month, date.day, 
          int.parse(day['timings']['Isha'].split(':')[0]), 
          int.parse(day['timings']['Isha'].split(':')[1])));
    }

    prefs.setString(cacheKey, json.encode(prayerTimes));
    return prayerTimes;
  } else {
    throw Exception('Failed to load prayer times');
  }
}

Future<DateTime> getPrayerTimeForDate(DateTime date, PrayerTime prayerTime, String city, String country) async {
  try {
    Map<String, List<DateTime>> prayerTimes = await fetchPrayerTimes(city, country, date.year, date.month);
    int dayIndex = date.day - 1; // API returns 1-indexed days, we need 0-indexed
    switch (prayerTime) {
      case PrayerTime.fajr:
        return prayerTimes['fajr']![dayIndex];
      case PrayerTime.dhuhr:
        return prayerTimes['dhuhr']![dayIndex];
      case PrayerTime.asr:
        return prayerTimes['asr']![dayIndex];
      case PrayerTime.maghrib:
        return prayerTimes['maghrib']![dayIndex];
      case PrayerTime.isha:
        return prayerTimes['isha']![dayIndex];
      default:
        return date;
    }
  } catch (e) {
    // Handle exceptions and fallback to default times
    return getDefaultPrayerTime(date, prayerTime);
  }
}

DateTime getDefaultPrayerTime(DateTime date, PrayerTime prayerTime) {
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


Future<List<Appointment>> loadAppointments() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> appointmentList = prefs.getStringList('appointments') ?? [];
  List<Appointment> visibleAppointments = [];
  DateTime today = DateTime.now();

  for (String appointmentStr in appointmentList) {
    final appointmentData = json.decode(appointmentStr);
    Appointment appointment = Appointment(
      startTime: DateTime.parse(appointmentData['startTime']),
      endTime: DateTime.parse(appointmentData['endTime']),
      isAllDay: appointmentData['isAllDay'],
      subject: appointmentData['subject'],
      notes: appointmentData['notes'],
      country: appointmentData['country'],
      city: appointmentData['city'],
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
      DateTime prayerTime = await getPrayerTimeForDate(appointment.startTime, appointment.prayerTime!, appointment.city!, appointment.country!);
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
      if (appointment.isRelatedToPrayerTimes && appointment.prayerTime != null) {
        await updateAppointmentTime(appointment, appointment.startTime);
      }
      visibleAppointments.add(appointment);
    } else {
      DateTime recurrenceDate = appointment.startTime;
      while (recurrenceDate.isBefore(appointment.repeatEndDate ?? today.add(Duration(days: 365)))) {
        if (recurrenceDate.isAfter(today.subtract(Duration(days: 365))) && shouldDisplayEvent(appointment, recurrenceDate)) {
          Appointment recurrentAppointment = Appointment(
            startTime: recurrenceDate,
            endTime: recurrenceDate.add(appointment.endTime.difference(appointment.startTime)),
            isAllDay: appointment.isAllDay,
            subject: appointment.subject,
            notes: appointment.notes,
            country: appointment.country,
            city: appointment.city,
            color: appointment.color,
            isRecurring: appointment.isRecurring,
            isRelatedToPrayerTimes: appointment.isRelatedToPrayerTimes,
            prayerTime: appointment.prayerTime,
            timeRelation: appointment.timeRelation,
            offsetDuration: appointment.offsetDuration,
            duration: appointment.duration,
          );
          
          if (recurrentAppointment.isRelatedToPrayerTimes && recurrentAppointment.prayerTime != null) {
            await updateAppointmentTime(recurrentAppointment, recurrenceDate);
          }
          
          visibleAppointments.add(recurrentAppointment);
        }
        recurrenceDate = getNextRecurrenceDate(recurrenceDate, appointment.repeatFrequency!, appointment.repeatInterval!);
      }
    }
  }
  return visibleAppointments;
}


Future<void> updateAppointmentTime(Appointment appointment, DateTime date) async {
  DateTime prayerTime = await getPrayerTimeForDate(date, appointment.prayerTime!, appointment.city!, appointment.country!);
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

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}