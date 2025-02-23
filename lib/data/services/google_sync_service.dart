// lib/data/services/google_sync_service.dart
import 'package:flutter/cupertino.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:intl/intl.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/google_calendar_api.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';

class GoogleSyncService {
  final GoogleCalendarApi calendarProvider;
  final AppointmentRepository appointmentRepository;
  final RecurrenceService recurrenceService;
  final PrayerTimeService prayerTimeService;

  GoogleSyncService({
    required this.calendarProvider,
    required this.appointmentRepository,
    required this.recurrenceService,
    required this.prayerTimeService,
  });

  Future<void> importAppointments() async {
  await calendarProvider.autoSignIn();
  List<Event> events = await calendarProvider.fetchCalendarEvents();

  for (var event in events) {
    // Doğum günü gibi otomatik oluşturulan eventleri filtreleyelim.
    // Örneğin, bazı hesaplarda doğum günü event'leri organizer email'i "addressbook#contacts@group.v.calendar.google.com" olarak gelebilir.
    // Ayrıca, summary içerisinde "birthday" veya "doğum günü" gibi ifadeler varsa, onları da atlayabiliriz.
    if ((event.organizer != null &&
            event.organizer!.email!.toLowerCase().contains('group.v.calendar.google.com')) ||
        (event.summary != null &&
            (event.summary!.toLowerCase().contains('birthday') ||
             event.summary!.toLowerCase().contains('doğum günü')))) {
      // Bu event doğum günü gibi otomatik oluşturulan bir eventse, atla.
      continue;
    }

    // İlgili extended property var mı kontrol edelim.
    String? muslimCalendarId = event.extendedProperties?.private?['muslimcalendarID'];
    AppointmentModel? existingAppointment;
    if (muslimCalendarId == null) {
      // Normal appointment: externalIdGoogle üzerinden eşleştir.
      existingAppointment = await appointmentRepository.getAppointmentByExternalIdGoogle(event.id!);
    } else {
      // Namaz vakitlerine bağlı appointment: extended property içerisindeki id'yi kullan.
      int? masterId = int.tryParse(muslimCalendarId);
      if (masterId != null) {
        existingAppointment = await appointmentRepository.getAppointment(masterId);
      }
    }
    if(event.recurrence != null){
      if(event.recurrence!.first == 'RRULE:FREQ=WEEKLY;WKST=TU'){
        event.recurrence?.first = recurrenceService.modifyRecurrenceRule(event.recurrence!.first.toString(), event.start!.dateTime!);
      }
      else{
        event.recurrence!.first = convertGoogleToICalendarRRule(event.recurrence!.first.toString());
      }
    }
    AppointmentModel appointment = AppointmentModel(
      id: existingAppointment?.id,
      subject: event.summary ?? '',
      notes: event.description,
      isAllDay: event.start?.date != null,
      isRelatedToPrayerTimes: muslimCalendarId != null,
      prayerTime: null,
      timeRelation: null,
      minutesBeforeAfter: null,
      duration: (event.start?.dateTime != null && event.end?.dateTime != null)
          ? event.end!.dateTime!.difference(event.start!.dateTime!)
          : null,
      location: event.location,
      recurrenceRule: event.recurrence != null ? event.recurrence!.join(',') : null,
      recurrenceExceptionDates: null,
      color: Color(0xFF2196F3),
      startTime: event.start?.dateTime != null
          ? event.start!.dateTime!.toLocal()
          : (event.start?.date != null ? event.start!.date! : null),
      endTime: event.end?.dateTime != null
          ? event.end!.dateTime!.toLocal()
          : (event.end?.date != null ? event.start!.date!.add(Duration(minutes: 1)) : null),
      categoryId: null,
      reminderMinutesBefore: null,
      lastSyncedAt: DateTime.now(),
    );

    if (muslimCalendarId == null) {
      appointment.externalIdGoogle = event.id;
    }

    if (existingAppointment == null) {
      await appointmentRepository.insertAppointment(appointment);
    } else {
      await appointmentRepository.updateAppointment(appointment);
    }
  }
  List<AppointmentModel> existingAppointments = await appointmentRepository.getAllAppointments();

  for (var existingAppointment in existingAppointments) {
    bool foundMatchingEvent = false;
    if(existingAppointment.externalIdGoogle != null){
      for (var event in events) {
        if (event.id == existingAppointment.externalIdGoogle.toString()) {
              foundMatchingEvent = true;
          break;
        }
      }
      if (!foundMatchingEvent) {
        // Eğer eşleşen bir event yoksa, bu appointment'ı sil.
        await appointmentRepository.deleteAppointment(existingAppointment.id!);
      }
    }
  }
}

  String convertGoogleToICalendarRRule(String googleRrule) {
  final params = googleRrule.split(';');
  final icalParams = <String>[];

  for (var param in params) {
    final parts = param.split('=');
    if (parts.length != 2) continue;

    final key = parts[0];
    final value = parts[1];

    if (key == 'BYDAY') {
      // Google'ın 1TU formatını iCalendar'a dönüştür
      final regex = RegExp(r'^(-?\d+)([A-Za-z]{2})$');
      final match = regex.firstMatch(value);
      
      if (match != null) {
        final position = int.parse(match.group(1)!);
        final day = match.group(2)!;
        icalParams.add('BYSETPOS=$position');
        icalParams.add('BYDAY=$day');
      } else {
        icalParams.add('BYDAY=$value');
      }
    } else if (key == 'FREQ') {
      // FREQ değerini lowercase'e çevir
      icalParams.add('FREQ=${value.toUpperCase()}');
    } else {
      // Diğer parametreleri aynen aktar
      icalParams.add('$key=$value');
    }
  }

  // Özel durum: Aylık kurallarda BYSETPOS ekle
  if (icalParams.any((p) => p.startsWith('FREQ=MONTHLY')) && 
      icalParams.any((p) => p.startsWith('BYDAY=')) && 
      !icalParams.any((p) => p.startsWith('BYSETPOS'))) {
    icalParams.add('BYSETPOS=1');
  }

  return '${icalParams.join(';').toUpperCase()}';
}
  /// Ortak export fonksiyonu: Yerel veritabanındaki appointment’ları sağlayıcıya (Google) aktarır.
  Future<void> exportAppointments() async {
    await calendarProvider.autoSignIn();
    List<AppointmentModel> appointments = await appointmentRepository.getAllAppointments();

    for (var appointment in appointments) {
      if (appointment.isRelatedToPrayerTimes) {
        // Prayer-related appointment’lar için: RecurrenceService ile tekrarlanan tarihler hesaplanır.
        DateTime startRange = DateTime.now();
        DateTime endRange = startRange.add(Duration(days: 30));
        List<DateTime> recurrenceDates =
            recurrenceService.getRecurrenceDates(appointment, startRange, endRange);

        for (var date in recurrenceDates) {
          DateTime? calculatedStart =
              await prayerTimeService.getCalculatedStartTime(appointment, date);
          DateTime? calculatedEnd =
              await prayerTimeService.getCalculatedEndTime(appointment, date);
          if (calculatedStart == null || calculatedEnd == null) continue;

          await calendarProvider.syncAppointmentEvent(
            appointment: appointment,
            startTime: calculatedStart,
            endTime: calculatedEnd,
            prayerRelated: true,
          );
        }
        // Silinmesi gereken event’ler, geçerli tekrarlanan tarihler dışında kalmış ise silinir.
        await calendarProvider.deleteEventsNotInDates(
          appointmentId: appointment.id!,
          validDates: recurrenceDates,
        );
      } else {
        if (appointment.startTime == null || appointment.endTime == null) continue;
        Event event = await calendarProvider.syncAppointmentEvent(
          appointment: appointment,
          startTime: appointment.startTime!,
          endTime: appointment.endTime!,
          prayerRelated: false,
        );
        if (appointment.externalIdGoogle == null) {
          appointment.externalIdGoogle = event.id;
          await appointmentRepository.updateAppointment(appointment);
        }
      }
    }
  }
}
