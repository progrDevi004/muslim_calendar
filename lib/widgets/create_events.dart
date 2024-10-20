import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
    );

    if (!appointment.isRecurring) {
      visibleAppointments.add(appointment);
    } else {
      // Tekrarlayan olaylar için tüm uygun tarihleri ekleyin
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