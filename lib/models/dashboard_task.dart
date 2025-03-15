import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modellklasse für die Darstellung von Aufgaben im Dashboard
class DashboardTask {
  final int? appointmentId;
  final bool isPrayerSlot;
  final String title;
  final DateTime start;
  final DateTime end;
  final int durationInMinutes;
  final String description;
  final Color color;
  final bool isAllDay;

  /// Formatierte Startzeit (abhängig vom 24-Stunden-Format)
  String? _formattedStartTime;

  /// Formatierte Endzeit (abhängig vom 24-Stunden-Format)
  String? _formattedEndTime;

  DashboardTask({
    this.appointmentId,
    required this.isPrayerSlot,
    required this.title,
    required this.start,
    required this.end,
    required this.durationInMinutes,
    required this.description,
    required this.color,
    required this.isAllDay,
  });

  /// Formatiert die Startzeit im gewünschten Format
  String get formattedStartTime {
    if (_formattedStartTime != null) return _formattedStartTime!;
    return _formatDateTime(start);
  }

  /// Formatiert die Endzeit im gewünschten Format
  String get formattedEndTime {
    if (_formattedEndTime != null) return _formattedEndTime!;
    return _formatDateTime(end);
  }

  /// Setzt die formatierten Zeiten (wird vom Dashboard aufgerufen)
  void setFormattedTimes(String startTime, String endTime) {
    _formattedStartTime = startTime;
    _formattedEndTime = endTime;
  }

  /// Hilfsmethode zur Formatierung von Datum/Uhrzeit
  String _formatDateTime(DateTime dt) {
    // Standardformat, wenn nicht extern gesetzt
    return DateFormat('HH:mm').format(dt);
  }
}
