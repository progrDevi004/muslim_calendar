import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;

class PrayerTimeCache {
  static final Map<String, Map<String, List<DateTime>>> _cache = {};

  static Future<Map<String, List<DateTime>>> getPrayerTimes(String city, String country, int year, int month) async {
    final String cacheKey = '$year-$month-$city-$country';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? cachedTimes = prefs.getString(cacheKey);

    if (cachedTimes != null) {
      final Map<String, List<DateTime>> prayerTimes = Map<String, List<DateTime>>.from(
        json.decode(cachedTimes).map((key, value) => MapEntry(
          key,
          (value as List).map((item) => DateTime.parse(item)).toList(),
        )),
      );
      _cache[cacheKey] = prayerTimes;
      return prayerTimes;
    }

    return await fetchPrayerTimes(city, country, year, month);
  }

  static Future<Map<String, List<DateTime>>> fetchPrayerTimes(String city, String country, int year, int month) async {
    final String apiUrl = 'https://api.aladhan.com/v1/calendarByAddress/$year/$month?address=$city,$country';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map<String, List<DateTime>> prayerTimes = {
        'fajr': [], 'dhuhr': [], 'asr': [], 'maghrib': [], 'isha': [],
      };

      for (var day in data['data']) {
        DateTime date = DateTime.parse(day['date']['gregorian']['date']);
        for (var prayer in prayerTimes.keys) {
          prayerTimes[prayer]!.add(DateTime(
            date.year, date.month, date.day,
            int.parse(day['timings'][prayer.capitalize()].split(':')[0]),
            int.parse(day['timings'][prayer.capitalize()].split(':')[1]),
          ));
        }
      }

      final String cacheKey = '$year-$month-$city-$country';
      _cache[cacheKey] = prayerTimes;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, json.encode(prayerTimes.map(
        (key, value) => MapEntry(key, value.map((dt) => dt.toIso8601String()).toList()),
      )));

      return prayerTimes;
    } else {
      throw Exception('Failed to load prayer times');
    }
  }
}

Future<DateTime> getPrayerTimeForDate(DateTime date, PrayerTime prayerTime, String city, String country) async {
  try {
    Map<String, List<DateTime>> prayerTimes = await PrayerTimeCache.getPrayerTimes(city, country, date.year, date.month);
    int dayIndex = date.day - 1;
    return prayerTimes[prayerTime.toString().split('.').last]![dayIndex];
  } catch (e) {
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


Future<List<Appointment>> loadAppointments({DateTime? start, DateTime? end}) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> appointmentList = prefs.getStringList('appointments') ?? [];
  List<Appointment> visibleAppointments = [];
  
  start ??= DateTime.now().subtract(Duration(days: 30));
  end ??= DateTime.now().add(Duration(days: 365));

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

    if (!appointment.isRecurring) {
      if (appointment.startTime.isAfter(start) && appointment.startTime.isBefore(end)) {
        if (appointment.isRelatedToPrayerTimes && appointment.prayerTime != null) {
          await updateAppointmentTime(appointment, appointment.startTime);
        }
        visibleAppointments.add(appointment);
      }
    } else {
      DateTime recurrenceDate = appointment.startTime;
      while (recurrenceDate.isBefore(appointment.repeatEndDate ?? end)) {
        if (recurrenceDate.isAfter(start) && recurrenceDate.isBefore(end) && 
            shouldDisplayEvent(appointment, recurrenceDate)) {
          Appointment recurrentAppointment = Appointment(
            startTime: recurrenceDate,
            endTime: recurrenceDate.add(appointment.endTime.difference(appointment.startTime)),
            isAllDay: appointment.isAllDay,
            subject: appointment.subject,
            notes: appointment.notes,
            country: appointment.country,
            city: appointment.city,
            color: appointment.color,
            isRecurring: false, // Tekil randevu olarak işaretliyoruz
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
String _generateAppointmentId(Appointment appointment) {
    // Benzersiz bir kimlik oluştur
    return '${appointment.subject}_${appointment.startTime}_${appointment.endTime}';
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

class LazyLoadingCalendarDataSource extends CalendarDataSource {
  final Future<List<Appointment>> Function({DateTime? start, DateTime? end}) loadAppointments;
  final Set<String> _loadedAppointmentIds = {};

  LazyLoadingCalendarDataSource(this.loadAppointments) {
    appointments = <Appointment>[];
  }

  @override
  Future<void> handleLoadMore(DateTime startDate, DateTime endDate) async {
    try {
      final List<Appointment> newAppointments = await loadAppointments(start: startDate, end: endDate);
      List<Appointment> uniqueNewAppointments = [];

      for (var appointment in newAppointments) {
        String appointmentId = _generateAppointmentId(appointment);
        if (!_loadedAppointmentIds.contains(appointmentId)) {
          _loadedAppointmentIds.add(appointmentId);
          uniqueNewAppointments.add(appointment);
        }
      }
      notifyListeners(CalendarDataSourceAction.add, uniqueNewAppointments);
    } catch (e) {
      print('Error loading more appointments: $e');
    }
  }
  String _generateAppointmentId(Appointment appointment) {
    // Benzersiz bir kimlik oluştur
    return '${appointment.subject}_${appointment.startTime}_${appointment.endTime}';
  }

  @override
  List<Appointment> get appointments => super.appointments as List<Appointment>;

  @override
  set appointments(List<dynamic>? value) {
    super.appointments = value?.cast<Appointment>() ?? <Appointment>[];
  }
}
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
