//lib/data/services/recurrence_service.dart
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/utils/recurrence_rule_converter.dart';

/// RecurrenceService - Zentraler Dienst für Wiederholungslogik
///
/// Dieser Service bietet Funktionen für die Verarbeitung von Wiederholungsregeln
/// und die Berechnung von Wiederholungsdaten für Termine.
///
/// Hauptfunktionen:
/// - Berechnung von Wiederholungen für einen bestimmten Zeitraum
/// - Modifikation und Korrektur von Wiederholungsregeln
/// - Konvertierung zwischen verschiedenen Wiederholungsformaten
class RecurrenceService {
  /// Berechnet alle Wiederholungstermine eines Appointments in einem bestimmten Zeitraum
  List<DateTime> getRecurrenceDates(
      AppointmentModel appointment, DateTime startRange, DateTime endRange) {
    if (appointment.recurrenceRule == null) return [];

    // Wenn ein Enddatum für die Wiederholung definiert ist, verwenden wir das als obere Grenze
    DateTime actualEndRange = endRange;
    if (appointment.recurrenceEndDate != null &&
        appointment.recurrenceEndDate!.isBefore(endRange)) {
      actualEndRange = appointment.recurrenceEndDate!;
    }

    final dates = SfCalendar.getRecurrenceDateTimeCollection(
      appointment.recurrenceRule!,
      appointment.startTime ?? DateTime.now(),
      specificStartDate: startRange,
      specificEndDate: actualEndRange,
    );

    // Filtere Ausnahmedaten heraus
    if (appointment.recurrenceExceptionDates != null &&
        appointment.recurrenceExceptionDates!.isNotEmpty) {
      return dates
          .where((d) => !appointment.recurrenceExceptionDates!.any((ex) =>
              ex.year == d.year && ex.month == d.month && ex.day == d.day))
          .toList();
    }
    return dates;
  }

  /// Modifiziert eine Wiederholungsregel, um problematische Elemente zu entfernen
  String modifyRecurrenceRule(String recurrenceRule, DateTime eventStartDate) {
    // Entferne WKST=TU, falls vorhanden
    if (recurrenceRule.contains('WKST')) {
      recurrenceRule =
          recurrenceRule.replaceAll(RegExp(r"WKST=[A-Za-z]{2}"), "");
    }

    // Stellen sicher, dass eine wöchentliche Regel einen BYDAY-Parameter hat
    if (recurrenceRule.contains('FREQ=WEEKLY') &&
        !recurrenceRule.contains('BYDAY')) {
      // Verwende den Wochentag des Startdatums
      String weekday =
          RecurrenceRuleConverter.getWeekdayFromDate(eventStartDate);
      if (recurrenceRule.endsWith(';') || recurrenceRule.endsWith(',')) {
        recurrenceRule = '${recurrenceRule}BYDAY=$weekday';
      } else {
        recurrenceRule = '$recurrenceRule;BYDAY=$weekday';
      }
    }

    return recurrenceRule;
  }

  /// Prüft und korrigiert fehlerhafte Wiederholungsregeln
  ///
  /// Diese Methode behandelt folgende Fälle:
  /// - Wöchentliche Wiederholungen ohne BYDAY
  /// - Ungültige WKST-Parameter
  /// - Fehlende INTERVAL-Parameter
  String fixRecurrenceRule(String? recurrenceRule, DateTime? startTime) {
    if (recurrenceRule == null || recurrenceRule.isEmpty) {
      return '';
    }

    String fixedRule = recurrenceRule;

    // Entferne 'RRULE:' Präfix, falls vorhanden
    if (fixedRule.startsWith('RRULE:')) {
      fixedRule = fixedRule.substring(6);
    }

    // Entferne Leerzeichen und doppelte Semikolons
    fixedRule = fixedRule.replaceAll(' ', '').replaceAll(';;', ';');

    // Korrigiere wöchentliche Wiederholungen ohne BYDAY
    if (fixedRule.contains('FREQ=WEEKLY') && !fixedRule.contains('BYDAY=')) {
      if (startTime != null) {
        String weekday = RecurrenceRuleConverter.getWeekdayFromDate(startTime);
        fixedRule = '$fixedRule;BYDAY=$weekday';
      }
    }

    // Stelle sicher, dass wöchentliche Wiederholungen ein INTERVAL haben
    if (fixedRule.contains('FREQ=WEEKLY') && !fixedRule.contains('INTERVAL=')) {
      fixedRule = '$fixedRule;INTERVAL=1';
    }

    // Behandle monatliche Wiederholungen mit BYDAY ohne BYSETPOS
    if (fixedRule.contains('FREQ=MONTHLY') &&
        fixedRule.contains('BYDAY=') &&
        !fixedRule.contains('BYSETPOS=')) {
      fixedRule = '$fixedRule;BYSETPOS=1';
    }

    debugPrint('🛠️ Wiederholungsregel korrigiert: $fixedRule');
    return fixedRule.toUpperCase();
  }

  String adjustRecurrenceRuleForMondayStart(String recurrenceRule) {
    // Eğer recurrenceRule varsa
    if (!recurrenceRule.contains("BYDAY")) {
      // 'WKST' değerini alıp 'BYDAY' parametresini ekliyoruz
      if (recurrenceRule.contains("WKST")) {
        String wkstValue = recurrenceRule.split("WKST=")[1].split(";")[0];
        recurrenceRule = "$recurrenceRule;BYDAY=$wkstValue";
      }
    }

    // Eğer 'WKST' parametresi varsa, bunu 'MO' olarak güncelleyelim
    if (recurrenceRule.contains("WKST")) {
      recurrenceRule =
          recurrenceRule.replaceAll(RegExp(r"WKST=[A-Za-z]{2}"), "");
    }

    // Eğer 'INTERVAL' parametresi yoksa, bunu 'INTERVAL=1' olarak ekleyelim
    if (!recurrenceRule.contains("INTERVAL")) {
      recurrenceRule = "$recurrenceRule;INTERVAL=1";
    }
    return recurrenceRule;
  }
}
