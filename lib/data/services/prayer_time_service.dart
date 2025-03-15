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

    // Prüfe, ob location null ist
    if (appointment.location == null) {
      return appointment.startTime;
    }

    final minutes = await prayerTimeRepo.getPrayerTimeMinutes(
      useAppointmentDate ? appointment.startTime! : fallbackDate,
      appointment.location!,
      appointment.prayerTime!,
    );

    if (minutes == null) {
      return null;
    }

    final baseSource =
        useAppointmentDate ? appointment.startTime! : fallbackDate;

    // Erstelle ein neues Datum-Objekt mit den berechneten Minuten
    // Wir konvertieren hier explizit zu einer lokalen Zeit
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
    if (start == null) {
      return null;
    }
    if (appointment.isRelatedToPrayerTimes && appointment.duration != null) {
      final end = start.add(appointment.duration!);
      return end;
    }
    return appointment.endTime;
  }

  /// Die Funktion lädt die aktuellen Standorteinstellungen aus den SharedPreferences.
  Future<String?> _getCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final automaticLocation = prefs.getBool('automaticLocation') ?? false;
    final defaultCountry = prefs.getString('defaultCountry');
    final defaultCity = prefs.getString('defaultCity');

    if (defaultCountry == null ||
        defaultCity == null ||
        defaultCountry.isEmpty ||
        defaultCity.isEmpty) {
      return null;
    }

    return '${defaultCity.trim()},${defaultCountry.trim()}'.toLowerCase();
  }

  /// Lädt alle Gebetszeiten neu herunter und aktualisiert Termine
  Future<void> reDownloadAndRecalcAll() async {
    debugPrint("📅 PrayerTimeService: Starte reDownloadAndRecalcAll()");

    // 1) Hole alle gebetszeitbezogenen Termine
    final allAppointments = await _appointmentRepo.getAllAppointments();
    List<AppointmentModel> prayerAppointments = allAppointments
        .where((a) => a.isRelatedToPrayerTimes && a.startTime != null)
        .toList();

    if (prayerAppointments.isEmpty) {
      debugPrint(
          "📅 Keine gebetszeitbezogenen Termine gefunden, nichts zu tun.");
      return;
    }

    // 2) Aktuelle Standorteinstellungen laden
    final location = await _getCurrentLocation();
    if (location == null) {
      return;
    }
    final newLocation = location;

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
