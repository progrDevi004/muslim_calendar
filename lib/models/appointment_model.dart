// lib/models/appointment_model.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'enums.dart';

class AppointmentModel {
  final int? id;
  final String subject;
  final String? notes;
  final bool isAllDay;
  final bool isRelatedToPrayerTimes;
  final PrayerTime? prayerTime;
  final TimeRelation? timeRelation;
  final int? minutesBeforeAfter;
  final Duration? duration;
  final String? location;
  final String? recurrenceRule;
  final List<DateTime>? recurrenceExceptionDates;
  final Color color;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? categoryId;

  // >>> NEU: Erinnerung X Minuten vor Start
  final int? reminderMinutesBefore;

  // >>> NEU: Für Synchronisierung
  String? externalIdGoogle; // z.B. Event-ID in Google Calendar
  String? externalIdOutlook; // z.B. Event-ID in Outlook
  final String? externalIdApple; // z.B. Event-Identifier in Apple-Kalender
  final DateTime? lastSyncedAt; // Zuletzt erfolgreich synchronisiert

  AppointmentModel({
    this.id,
    required this.subject,
    this.notes,
    required this.isAllDay,
    required this.isRelatedToPrayerTimes,
    this.prayerTime,
    this.timeRelation,
    this.minutesBeforeAfter,
    this.duration,
    this.location,
    this.recurrenceRule,
    this.recurrenceExceptionDates,
    required this.color,
    this.startTime,
    this.endTime,
    this.categoryId,
    this.reminderMinutesBefore,

    // NEU
    this.externalIdGoogle,
    this.externalIdOutlook,
    this.externalIdApple,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'notes': notes,
      'isAllDay': isAllDay ? 1 : 0,
      'isRelatedToPrayerTimes': isRelatedToPrayerTimes ? 1 : 0,
      'prayerTime': prayerTime?.index,
      'timeRelation': timeRelation?.index,
      'minutesBeforeAfter': minutesBeforeAfter,
      'duration': duration?.inMinutes,
      'location': location,
      'recurrenceRule': recurrenceRule,
      'recurrenceExceptionDates': recurrenceExceptionDates != null
          ? json.encode(
              recurrenceExceptionDates!
                  .map((e) => e.toIso8601String())
                  .toList(),
            )
          : null,
      'color': color.value,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'categoryId': categoryId,
      'reminderMinutesBefore': reminderMinutesBefore,

      // NEU
      'externalIdGoogle': externalIdGoogle,
      'externalIdOutlook': externalIdOutlook,
      'externalIdApple': externalIdApple,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    List<DateTime>? exceptionDates;
    if (map['recurrenceExceptionDates'] != null) {
      final exceptionString = map['recurrenceExceptionDates'];
      if (exceptionString is String) {
        final decoded = json.decode(exceptionString);
        if (decoded is List) {
          exceptionDates =
              decoded.map((e) => DateTime.parse(e.toString())).toList();
        }
      }
    }

    return AppointmentModel(
      id: map['id'],
      subject: map['subject'],
      notes: map['notes'],
      isAllDay: map['isAllDay'] == 1,
      isRelatedToPrayerTimes: map['isRelatedToPrayerTimes'] == 1,
      prayerTime: map['prayerTime'] != null
          ? PrayerTime.values[map['prayerTime']]
          : null,
      timeRelation: map['timeRelation'] != null
          ? TimeRelation.values[map['timeRelation']]
          : null,
      minutesBeforeAfter: map['minutesBeforeAfter'],
      duration:
          map['duration'] != null ? Duration(minutes: map['duration']) : null,
      location: map['location'],
      recurrenceRule: map['recurrenceRule'],
      recurrenceExceptionDates: exceptionDates,
      color: Color(map['color']),
      startTime:
          map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      categoryId: map['categoryId'],

      // NEU
      reminderMinutesBefore: map['reminderMinutesBefore'],

      externalIdGoogle: map['externalIdGoogle'],
      externalIdOutlook: map['externalIdOutlook'],
      externalIdApple: map['externalIdApple'],
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'])
          : null,
    );
  }
    @override
  String toString() {
    return '''
    AppointmentModel(
      id: $id,
      subject: $subject,
      notes: $notes,
      isAllDay: $isAllDay,
      isRelatedToPrayerTimes: $isRelatedToPrayerTimes,
      prayerTime: $prayerTime,
      timeRelation: $timeRelation,
      minutesBeforeAfter: $minutesBeforeAfter,
      duration: $duration,
      location: $location,
      recurrenceRule: $recurrenceRule,
      recurrenceExceptionDates: $recurrenceExceptionDates,
      color: ${color.value},
      startTime: $startTime,
      endTime: $endTime,
      categoryId: $categoryId,
      reminderMinutesBefore: $reminderMinutesBefore,
      externalIdGoogle: $externalIdGoogle,
      externalIdOutlook: $externalIdOutlook,
      externalIdApple: $externalIdApple,
      lastSyncedAt: $lastSyncedAt
    )''';
  }
}
