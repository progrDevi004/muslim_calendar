//lib/widgets/prayer_time_appointment_adapter.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:Taqvimi/models/appointment_model.dart';
import 'package:Taqvimi/data/services/prayer_time_service.dart';
import 'package:Taqvimi/data/services/recurrence_service.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

class PrayerTimeAppointmentAdapter {
  final PrayerTimeService prayerTimeService;
  final RecurrenceService recurrenceService;
  final CategoryRepository _categoryRepository = CategoryRepository();

  // Cache für Kategorien, um wiederholte Datenbankzugriffe zu vermeiden
  final Map<int, CategoryModel> _categoryCache = {};

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
          result.add(await _toAppointment(model, start, end));
        }
      }
    } else {
      if (model.startTime != null && model.endTime != null) {
        final start = model.startTime!;
        final end = model.endTime!;
        if ((start.isBefore(endRange) && end.isAfter(startRange))) {
          result.add(await _toAppointment(model, start, end));
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

    // Farbe einmal abrufen für alle Wiederholungen
    final color = await getCategoryColor(model.categoryId);

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
              color: color, // Aktuelle Kategoriefarbe verwenden
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
            color: color, // Aktuelle Kategoriefarbe verwenden
            isAllDay: model.isAllDay,
            location: model.location,
          ));
        }
      }
    }

    return result;
  }

  Future<Appointment> _toAppointment(
      AppointmentModel model, DateTime start, DateTime end) async {
    // Aktuelle Kategoriefarbe verwenden
    final color = await getCategoryColor(model.categoryId);

    // Hier ebenfalls keine recurrenceRule oder recurrenceExceptionDates setzen,
    // da wir Occurrences bereits selbst generieren
    return Appointment(
      id: model.id,
      subject: model.subject,
      notes: model.notes,
      startTime: start,
      endTime: end,
      color: color, // Aktuelle Kategoriefarbe verwenden
      isAllDay: model.isAllDay,
      location: model.location,
    );
  }

  /// Lädt die aktuelle Farbe für eine Kategorie
  Future<Color> getCategoryColor(int? categoryId) async {
    if (categoryId == null) {
      return Colors.blue; // Standardfarbe
    }

    // Versuche zuerst, die Kategorie aus dem Cache zu laden
    if (_categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId]!.color;
    }

    // Lade die Kategorie aus der Datenbank
    try {
      final category = await _categoryRepository.getCategory(categoryId);
      if (category != null) {
        // Cache aktualisieren
        _categoryCache[categoryId] = category;
        return category.color;
      }
    } catch (e) {
      debugPrint("Fehler beim Laden der Kategorie $categoryId: $e");
    }

    return Colors.blue; // Fallback
  }

  /// Leert den Kategorien-Cache
  void clearCategoryCache({Function? onCacheCleared}) {
    _categoryCache.clear();

    // Optional: Callback ausführen nach dem Leeren des Caches
    if (onCacheCleared != null) {
      onCacheCleared();
    }
  }
}
