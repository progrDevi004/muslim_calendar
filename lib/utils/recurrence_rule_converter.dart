// lib/utils/recurrence_rule_converter.dart

import 'package:flutter/foundation.dart';

/// Utility-Klasse für die Konvertierung von Wiederholungsregeln
/// zwischen verschiedenen Kalenderformaten (Google, iCalendar, etc.)
class RecurrenceRuleConverter {
  /// Konvertiert eine Google Calendar Wiederholungsregel in das iCalendar-Format
  ///
  /// Behandelt verschiedene Sonderfälle:
  /// - Wöchentliche Wiederholungen ohne BYDAY-Parameter
  /// - Spezielle Formatierung für Position (1TU)
  /// - Monatliche Wiederholungen mit BYDAY aber ohne BYSETPOS
  static String convertGoogleToICalendar(String googleRrule) {
    final params = googleRrule.split(';');
    final icalParams = <String>[];
    bool isWeekly = false;
    bool hasByDay = false;

    for (var param in params) {
      final parts = param.split('=');
      if (parts.length != 2) continue;

      final key = parts[0];
      final value = parts[1];

      if (key == 'FREQ' && value.toUpperCase() == 'WEEKLY') {
        isWeekly = true;
      }

      if (key == 'BYDAY') {
        hasByDay = true;
        // Konvertiert das Google-Format 1TU in iCalendar-Format
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
        // FREQ-Wert in Großbuchstaben umwandeln
        icalParams.add('FREQ=${value.toUpperCase()}');
      } else {
        // Andere Parameter unverändert übernehmen
        icalParams.add('$key=$value');
      }
    }

    // Wenn es sich um eine wöchentliche Wiederholung handelt aber kein BYDAY-Parameter vorhanden ist
    if (isWeekly && !hasByDay) {
      // Den Wochentag des aktuellen Datums als Standard verwenden
      DateTime now = DateTime.now();
      String weekday;

      switch (now.weekday) {
        case DateTime.monday:
          weekday = 'MO';
          break;
        case DateTime.tuesday:
          weekday = 'TU';
          break;
        case DateTime.wednesday:
          weekday = 'WE';
          break;
        case DateTime.thursday:
          weekday = 'TH';
          break;
        case DateTime.friday:
          weekday = 'FR';
          break;
        case DateTime.saturday:
          weekday = 'SA';
          break;
        case DateTime.sunday:
          weekday = 'SU';
          break;
        default:
          weekday = 'MO'; // Standardwert
      }

      debugPrint(
          '🛠️ Wöchentliche Wiederholung ohne BYDAY gefunden, füge BYDAY=$weekday hinzu');
      icalParams.add('BYDAY=$weekday');
    }

    // Sonderfall: Bei monatlichen Regeln mit BYDAY aber ohne BYSETPOS, füge BYSETPOS=1 hinzu
    if (icalParams.any((p) => p.startsWith('FREQ=MONTHLY')) &&
        icalParams.any((p) => p.startsWith('BYDAY=')) &&
        !icalParams.any((p) => p.startsWith('BYSETPOS'))) {
      icalParams.add('BYSETPOS=1');
    }

    return '${icalParams.join(';').toUpperCase()}';
  }

  /// Konvertiert eine iCalendar-Wiederholungsregel in das Google Calendar Format
  ///
  /// Diese Methode kann erweitert werden, wenn Bedarf an einer Rückkonvertierung besteht.
  static String convertICalendarToGoogle(String icalRrule) {
    // Entferne "RRULE:" Präfix, falls vorhanden
    if (icalRrule.startsWith('RRULE:')) {
      icalRrule = icalRrule.substring(6);
    }

    // Standardmäßig ist die Konvertierung in vielen Fällen direkt möglich
    // Hier könnten in Zukunft spezielle Konvertierungsregeln implementiert werden

    return icalRrule;
  }

  /// Formatiert die Wiederholungsregel speziell für Google Calendar
  ///
  /// Behandelt verschiedene Sonderfälle:
  /// - Stellt sicher, dass die Regel mit 'RRULE:' beginnt
  /// - Fügt BYDAY für wöchentliche Wiederholungen hinzu, falls nicht vorhanden
  /// - Stellt sicher, dass INTERVAL vorhanden ist
  /// - Behandelt monatliche Wiederholungen mit BYDAY
  static String formatRecurrenceRuleForGoogle(
      String recurrenceRule, DateTime? startDate) {
    debugPrint("🔄 Originale Wiederholungsregel: $recurrenceRule");

    // Stellen Sie sicher, dass die Regel mit 'RRULE:' beginnt
    if (!recurrenceRule.startsWith('RRULE:')) {
      recurrenceRule = 'RRULE:$recurrenceRule';
    }

    // Entferne Leerzeichen und doppelte Semikolons
    recurrenceRule =
        recurrenceRule.replaceAll(' ', '').replaceAll(';;', ';').toUpperCase();

    // Prüfe, ob die Regel 'FREQ=WEEKLY' enthält, aber kein 'BYDAY'
    if (recurrenceRule.contains('FREQ=WEEKLY') &&
        !recurrenceRule.contains('BYDAY')) {
      // Wenn ein Startdatum vorhanden ist, fügen wir den entsprechenden Wochentag hinzu
      if (startDate != null) {
        String weekday = getWeekdayFromDate(startDate);
        recurrenceRule = '${recurrenceRule};BYDAY=$weekday';
      }
    }

    // Stelle sicher, dass bei 'FREQ=WEEKLY' ein 'INTERVAL' vorhanden ist
    if (recurrenceRule.contains('FREQ=WEEKLY') &&
        !recurrenceRule.contains('INTERVAL')) {
      recurrenceRule = '${recurrenceRule};INTERVAL=1';
    }

    // Bei monatlichen Wiederholungen mit BYDAY, aber ohne BYSETPOS
    if (recurrenceRule.contains('FREQ=MONTHLY') &&
        recurrenceRule.contains('BYDAY=') &&
        !recurrenceRule.contains('BYSETPOS=')) {
      // Standardmäßig das erste Vorkommen im Monat verwenden
      recurrenceRule = '${recurrenceRule};BYSETPOS=1';
    }

    return recurrenceRule;
  }

  /// Hilfsmethode, um den Wochentag als String im iCalendar-Format zu erhalten
  static String getWeekdayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'MO';
      case DateTime.tuesday:
        return 'TU';
      case DateTime.wednesday:
        return 'WE';
      case DateTime.thursday:
        return 'TH';
      case DateTime.friday:
        return 'FR';
      case DateTime.saturday:
        return 'SA';
      case DateTime.sunday:
        return 'SU';
      default:
        return 'MO'; // Fallback
    }
  }
}
