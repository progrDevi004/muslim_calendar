// lib/data/services/prayer_time_service.dart

import 'package:flutter/foundation.dart'; // Für ChangeNotifier
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import '../repositories/prayer_time_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:sqflite/sqflite.dart';

class PrayerTimeService with ChangeNotifier {
  final PrayerTimeRepository prayerTimeRepo;
  // Für das automatische Update der vorhandenen Termine:
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  PrayerTimeService(this.prayerTimeRepo);

  Future<DateTime?> getCalculatedStartTime(
    AppointmentModel appointment,
    DateTime fallbackDate, {
    bool useAppointmentDate = false,
  }) async {
    if (!appointment.isRelatedToPrayerTimes || appointment.prayerTime == null) {
      return appointment.startTime;
    }

    final minutes = await prayerTimeRepo.getPrayerTimeMinutes(
      useAppointmentDate ? appointment.startTime! : fallbackDate,
      appointment.location!,
      appointment.prayerTime!,
    );

    if (minutes == null) return null;

    final baseSource =
        useAppointmentDate ? appointment.startTime! : fallbackDate;

    DateTime baseTime = DateTime(
      baseSource.year,
      baseSource.month,
      baseSource.day,
    ).add(Duration(minutes: minutes));

    // Vor-/Nachkorrektur
    if (appointment.timeRelation == TimeRelation.before &&
        appointment.minutesBeforeAfter != null) {
      baseTime =
          baseTime.subtract(Duration(minutes: appointment.minutesBeforeAfter!));
    } else if (appointment.timeRelation == TimeRelation.after &&
        appointment.minutesBeforeAfter != null) {
      baseTime =
          baseTime.add(Duration(minutes: appointment.minutesBeforeAfter!));
    }
    return baseTime;
  }

  Future<DateTime?> getCalculatedEndTime(
    AppointmentModel appointment,
    DateTime date,
  ) async {
    final start = await getCalculatedStartTime(appointment, date);
    if (start == null) return null;
    if (appointment.isRelatedToPrayerTimes && appointment.duration != null) {
      return start.add(appointment.duration!);
    }
    return appointment.endTime;
  }

  /// Diese Methode wird aufgerufen, wenn der User entweder die Berechnungsmethode ändert
  /// oder manuell den Standort anpasst.
  /// Vorgehen:
  /// 1) Es werden zunächst alle gebetszeitabhängigen Termine geladen.
  /// 2) Dann wird der aktuelle Standort (defaultCountry und defaultCity) aus den SharedPreferences
  ///    ausgelesen und als neuer Standort (in Kleinbuchstaben) ermittelt.
  /// 3) Falls in einem Termin die gespeicherte Location nicht dem neuen Standort entspricht,
  ///    wird ein neues AppointmentModel mit dem aktualisierten Standort erstellt und in der DB gespeichert.
  /// 4) Anschließend laden wir alle Gebetszeiten in der DB für den aktuellen Standort neu,
  ///    indem wir diese zunächst löschen und dann für alle relevanten Jahre neu abrufen.
  /// 5) Zuletzt werden alle betroffenen Termine anhand der neuen Gebetszeiten neu kalkuliert und aktualisiert.
  Future<void> reDownloadAndRecalcAll() async {
    // 1) Alle gebetszeitabhängigen Termine ermitteln
    final allAppointments = await _appointmentRepo.getAllAppointments();
    var prayerAppointments = allAppointments
        .where((a) => a.isRelatedToPrayerTimes && a.startTime != null)
        .toList();
    if (prayerAppointments.isEmpty) {
      return;
    }

    // 2) Aktuelle Standorteinstellungen laden
    final prefs = await SharedPreferences.getInstance();
    final defaultCountry = prefs.getString('defaultCountry');
    final defaultCity = prefs.getString('defaultCity');
    if (defaultCountry == null || defaultCity == null) {
      return;
    }
    final newLocation =
        '${defaultCity.trim()},${defaultCountry.trim()}'.toLowerCase();

    // 3) Falls nötig: Aktualisiere die Location in den Terminen,
    // sofern sie nicht dem neuen Standort entspricht.
    for (final appt in prayerAppointments) {
      if (appt.location == null ||
          appt.location!.trim().toLowerCase() != newLocation) {
        // Da appt.location final ist, erstellen wir ein neues AppointmentModel mit dem aktualisierten Standort.
        final updatedAppt = AppointmentModel(
          id: appt.id,
          subject: appt.subject,
          notes: appt.notes,
          isAllDay: appt.isAllDay,
          isRelatedToPrayerTimes: appt.isRelatedToPrayerTimes,
          prayerTime: appt.prayerTime,
          timeRelation: appt.timeRelation,
          minutesBeforeAfter: appt.minutesBeforeAfter,
          duration: appt.duration,
          location: newLocation,
          recurrenceRule: appt.recurrenceRule,
          recurrenceExceptionDates: appt.recurrenceExceptionDates,
          color: appt.color,
          startTime: appt.startTime,
          endTime: appt.endTime,
          categoryId: appt.categoryId,
          reminderMinutesBefore: appt.reminderMinutesBefore,
          externalIdGoogle: appt.externalIdGoogle,
          externalIdOutlook: appt.externalIdOutlook,
          externalIdApple: appt.externalIdApple,
          lastSyncedAt: appt.lastSyncedAt,
        );
        await _appointmentRepo.updateAppointment(updatedAppt);
      }
    }

    // 3b) Jetzt holen wir die aktualisierten Termine neu aus der DB,
    // sodass die weiteren Berechnungen den neuen Standort berücksichtigen.
    final updatedAllAppointments = await _appointmentRepo.getAllAppointments();
    prayerAppointments = updatedAllAppointments
        .where((a) => a.isRelatedToPrayerTimes && a.startTime != null)
        .toList();

    // 4) Gebetszeiten löschen, damit sie neu geladen werden (nur für den aktuellen Standort)
    final db = await prayerTimeRepo.dbHelper.database;
    await db.delete('prayer_times',
        where: 'LOWER(location) = ?', whereArgs: [newLocation]);

    // 5) Sammle alle relevanten Jahre aus den Terminen
    final uniqueYears =
        prayerAppointments.map((appt) => appt.startTime!.year).toSet().toList();

    // 6) Für jedes relevante Jahr: Lade die Gebetszeiten für den neuen Standort neu
    for (final year in uniqueYears) {
      await prayerTimeRepo.fetchAndSaveYearlyPrayerTimes(year, newLocation);
    }

    // 7) Alle relevanten Termine neu berechnen und abspeichern
    for (final appt in prayerAppointments) {
      final baseDate = DateTime(
        appt.startTime!.year,
        appt.startTime!.month,
        appt.startTime!.day,
      );
      final newStart = await getCalculatedStartTime(appt, baseDate);
      final newEnd = await getCalculatedEndTime(appt, baseDate);

      if (newStart != null && newEnd != null) {
        final updated = AppointmentModel(
          id: appt.id,
          subject: appt.subject,
          notes: appt.notes,
          isAllDay: appt.isAllDay,
          isRelatedToPrayerTimes: appt.isRelatedToPrayerTimes,
          prayerTime: appt.prayerTime,
          timeRelation: appt.timeRelation,
          minutesBeforeAfter: appt.minutesBeforeAfter,
          duration: appt.duration,
          location: appt.location, // sollte nun den neuen Standort enthalten
          recurrenceRule: appt.recurrenceRule,
          recurrenceExceptionDates: appt.recurrenceExceptionDates,
          color: appt.color,
          startTime: newStart,
          endTime: newEnd,
          categoryId: appt.categoryId,
          reminderMinutesBefore: appt.reminderMinutesBefore,
          externalIdGoogle: appt.externalIdGoogle,
          externalIdOutlook: appt.externalIdOutlook,
          externalIdApple: appt.externalIdApple,
          lastSyncedAt: appt.lastSyncedAt,
        );
        await _appointmentRepo.updateAppointment(updated);
      }
    }

    // 8) UI informieren, damit die Änderungen überall übernommen werden
    notifyListeners();
  }
}
