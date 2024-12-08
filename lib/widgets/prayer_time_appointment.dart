import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

enum PrayerTime {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

enum TimeRelation {
  before,
  after,
}

class PrayerTimeAppointment extends Appointment {
  PrayerTime? prayerTime;
  TimeRelation? timeRelation;
  int? minutesBeforeAfter;
  bool? isRelatedToPrayerTimes;
  Duration? duration;

  PrayerTimeAppointment({
    this.prayerTime,
    this.timeRelation,
    this.minutesBeforeAfter,
    this.isRelatedToPrayerTimes,
    this.duration,
    DateTime? startTime,
    DateTime? endTime,
    String? startTimeZone,
    String? endTimeZone,
    String? recurrenceRule,
    bool isAllDay = false,
    String? notes,
    String? location,
    List<Object>? resourceIds,
    Object? recurrenceId,
    Object? id,
    String subject = '',
    Color color = Colors.lightBlue,
    List<DateTime>? recurrenceExceptionDates,
  }) : super(
          startTime: startTime ?? DateTime.now(),
          endTime: endTime ?? DateTime.now(),
          startTimeZone: startTimeZone,
          endTimeZone: endTimeZone,
          recurrenceRule: recurrenceRule,
          isAllDay: isAllDay,
          notes: notes,
          location: location,
          resourceIds: resourceIds,
          recurrenceId: recurrenceId,
          id: id,
          subject: subject,
          color: color,
          recurrenceExceptionDates: recurrenceExceptionDates,
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startTimeZone': startTimeZone,
      'endTimeZone': endTimeZone,
      'recurrenceRule': recurrenceRule,
      'isAllDay': isAllDay ? 1 : 0,
      'isRelatedToPrayerTimes': isRelatedToPrayerTimes == true ? 1 : 0,
      'notes': notes,
      'location': location,
      'subject': subject,
      'color': color.value,
      'prayerTime': prayerTime?.index,
      'timeRelation': timeRelation?.index,
      'minutesBeforeAfter': minutesBeforeAfter,
      'duration': duration?.inMinutes,
    };
  }
}