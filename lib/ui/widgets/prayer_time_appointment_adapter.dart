//widgets/prayer_time_appointment_adapter.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';

class PrayerTimeAppointmentAdapter {
  final PrayerTimeService prayerTimeService;
  final RecurrenceService recurrenceService;

  PrayerTimeAppointmentAdapter({
    required this.prayerTimeService,
    required this.recurrenceService,
  });

  Future<List<Appointment>> getAppointmentsForRange(
    AppointmentModel model,
    DateTime startRange,
    DateTime endRange,
  ) async {
    if (model.startTime == null) {
      return [];
    }

    if (model.recurrenceRule == null) {
      return _getSingleAppointments(model, startRange, endRange);
    } else {
      return _getRecurringAppointments(model, startRange, endRange);
    }
  }

  Future<List<Appointment>> _getSingleAppointments(
    AppointmentModel model,
    DateTime startRange,
    DateTime endRange,
  ) async {
    List<Appointment> result = [];

    if (model.isRelatedToPrayerTimes) {
      final baseDate = DateTime(
          model.startTime!.year, model.startTime!.month, model.startTime!.day);
      final start =
          await prayerTimeService.getCalculatedStartTime(model, baseDate);
      final end = await prayerTimeService.getCalculatedEndTime(model, baseDate);

      if (start != null && end != null) {
        if ((start.isBefore(endRange) && end.isAfter(startRange))) {
          result.add(_toAppointment(model, start, end));
        }
      }
    } else {
      if (model.startTime != null && model.endTime != null) {
        final start = model.startTime!;
        final end = model.endTime!;
        if ((start.isBefore(endRange) && end.isAfter(startRange))) {
          result.add(_toAppointment(model, start, end));
        }
      }
    }

    return result;
  }

  Future<List<Appointment>> _getRecurringAppointments(
    AppointmentModel model,
    DateTime startRange,
    DateTime endRange,
  ) async {
    List<Appointment> result = [];
    final dates =
        recurrenceService.getRecurrenceDates(model, startRange, endRange);

    final uniqueDates = <DateTime>{};
    for (var d in dates) {
      uniqueDates.add(DateTime(d.year, d.month, d.day, d.hour, d.minute));
    }

    for (var d in uniqueDates) {
      if (model.isRelatedToPrayerTimes) {
        final baseDate = DateTime(d.year, d.month, d.day);
        final start =
            await prayerTimeService.getCalculatedStartTime(model, baseDate);
        final end =
            await prayerTimeService.getCalculatedEndTime(model, baseDate);
        if (start != null && end != null) {
          if ((start.isBefore(endRange) && end.isAfter(startRange))) {
            // Keine recurrenceRule oder recurrenceExceptionDates bei Occurrences setzen!
            result.add(Appointment(
              id: model.id,
              subject: model.subject,
              notes: model.notes,
              startTime: start,
              endTime: end,
              color: model.color,
              isAllDay: model.isAllDay,
              location: model.location,
            ));
          }
        }
      } else {
        final baseDuration = (model.endTime != null && model.startTime != null)
            ? model.endTime!.difference(model.startTime!)
            : const Duration(minutes: 30);

        final originalStart = model.startTime!;
        final start = DateTime(
            d.year, d.month, d.day, originalStart.hour, originalStart.minute);
        final end = start.add(baseDuration);

        if ((start.isBefore(endRange) && end.isAfter(startRange))) {
          // Keine recurrenceRule oder recurrenceExceptionDates bei Occurrences setzen!
          result.add(Appointment(
            id: model.id,
            subject: model.subject,
            notes: model.notes,
            startTime: start,
            endTime: end,
            color: model.color,
            isAllDay: model.isAllDay,
            location: model.location,
          ));
        }
      }
    }

    return result;
  }

  Appointment _toAppointment(
      AppointmentModel model, DateTime start, DateTime end) {
    // Hier ebenfalls keine recurrenceRule oder recurrenceExceptionDates setzen,
    // da wir Occurrences bereits selbst generieren
    return Appointment(
      id: model.id,
      subject: model.subject,
      notes: model.notes,
      startTime: start,
      endTime: end,
      color: model.color,
      isAllDay: model.isAllDay,
      location: model.location,
    );
  }
}
