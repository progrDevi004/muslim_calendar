// lib/data/services/outlook_sync_service.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/outlook_calendar_api.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';

class OutlookSyncService {
  final OutlookCalendarApi calendarProvider;
  final AppointmentRepository appointmentRepository;
  final RecurrenceService recurrenceService;
  final PrayerTimeService prayerTimeService;

  OutlookSyncService({
    required this.calendarProvider,
    required this.appointmentRepository,
    required this.recurrenceService,
    required this.prayerTimeService,
  });

  Future<void> importAppointments() async {
    await calendarProvider.autoSignIn();
    final events = await calendarProvider.fetchEvents();

    for (var event in events) {
      // Outlook'ta doğum günü event'leri genellikle 'Birthday' kategorisinde gelir
      if (event['categories']?.contains('Birthday') == true ||
          event['subject']?.toLowerCase().contains('doğum günü') == true) {
        continue;
      }

      final extendedProps = event['singleValueExtendedProperties'] as List?;
      String? muslimCalendarId;
      if (extendedProps != null) {
        final muslimProp = extendedProps.firstWhere(
          (prop) => prop['id'] == 'String muslimcalendarID',
          orElse: () => null,
        );
        muslimCalendarId = muslimProp?['value'] as String?;
      }

      AppointmentModel? existingAppointment;
      if (muslimCalendarId == null) {
        existingAppointment = await appointmentRepository.getAppointmentByExternalIdOutlook(event['id']);
      } else {
        final masterId = int.tryParse(muslimCalendarId);
        if (masterId != null) {
          existingAppointment = await appointmentRepository.getAppointment(masterId);
        }
      }

      // Microsoft recurrence formatını iCalendar RRULE'a çevir
      String? recurrenceRule;
      if (event['recurrence'] != null) {
        recurrenceRule = _convertOutlookToICalendarRRule(event['recurrence']);
      }

      final startTime = DateTime.parse(event['start']['dateTime']);
      final endTime = DateTime.parse(event['end']['dateTime']);

      final appointment = AppointmentModel(
        id: existingAppointment?.id,
        subject: event['subject'] ?? '',
        notes: event['body']['content'] ?? '',
        isAllDay: event['isAllDay'] ?? false,
        isRelatedToPrayerTimes: muslimCalendarId != null,
        startTime: startTime,
        endTime: endTime,
        duration: endTime.difference(startTime),
        location: event['location']['displayName'],
        recurrenceRule: recurrenceRule,
        color: Color(0xFF0078D4), // Outlook mavisi
        externalIdOutlook: event['id'],
        lastSyncedAt: DateTime.now(),
      );

      if (existingAppointment == null) {
        await appointmentRepository.insertAppointment(appointment);
      } else {
        await appointmentRepository.updateAppointment(appointment);
      }
    }

    // Silinmiş event'leri temizle
    final existingAppointments = await appointmentRepository.getAllAppointments();
    for (final appointment in existingAppointments) {
      if (appointment.externalIdOutlook != null &&
          !events.any((e) => e['id'] == appointment.externalIdOutlook)) {
        await appointmentRepository.deleteAppointment(appointment.id!);
      }
    }
  }

  String? _convertOutlookToICalendarRRule(Map<String, dynamic>? recurrence) {
    if (recurrence == null) return null;
    
    final pattern = recurrence['pattern'] as Map<String, dynamic>;
    final range = recurrence['range'] as Map<String, dynamic>;
    
    final sb = StringBuffer('RRULE:');
    sb.write('FREQ=${pattern['type']!.toString().toUpperCase()};');
    sb.write('INTERVAL=${pattern['interval']};');
    
    if (pattern['daysOfWeek'] != null) {
      sb.write('BYDAY=${pattern['daysOfWeek'].join(',')};');
    }
    
    if (range['type'] == 'endDate') {
      sb.write('UNTIL=${DateFormat('yyyyMMdd').format(DateTime.parse(range['endDate']))};');
    } else if (range['type'] == 'numbered') {
      sb.write('COUNT=${range['numberOfOccurrences']};');
    }
    
    return sb.toString().replaceAll(RegExp(r';$'), '');
  }

  Future<void> exportAppointments() async {
    await calendarProvider.autoSignIn();
    final appointments = await appointmentRepository.getAllAppointments();

    for (final appointment in appointments) {
      if (appointment.isRelatedToPrayerTimes) {
        final startRange = DateTime.now();
        final endRange = startRange.add(Duration(days: 30));
        final recurrenceDates = recurrenceService.getRecurrenceDates(
          appointment, 
          startRange, 
          endRange,
        );

        for (final date in recurrenceDates) {
          final calculatedStart = await prayerTimeService.getCalculatedStartTime(appointment, date);
          final calculatedEnd = await prayerTimeService.getCalculatedEndTime(appointment, date);
          
          if (calculatedStart != null && calculatedEnd != null) {
            await calendarProvider.syncAppointmentEvent(
              appointment: appointment,
              startTime: calculatedStart,
              endTime: calculatedEnd,
              prayerRelated: true,
            );
          }
        }

        await calendarProvider.deleteEventsNotInDates(
          appointmentId: appointment.id!,
          validDates: recurrenceDates,
        );
      } else {
        if (appointment.startTime == null || appointment.endTime == null) continue;
        
        final event = await calendarProvider.syncAppointmentEvent(
          appointment: appointment,
          startTime: appointment.startTime!,
          endTime: appointment.endTime!,
          prayerRelated: false,
        );
        
        if (appointment.externalIdOutlook == null) {
          appointment.externalIdOutlook = event['id'] as String;
          await appointmentRepository.updateAppointment(appointment);
        }
      }
    }
  }
}