import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gCal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/ui/widgets/prayer_time_appointment_adapter.dart';
import 'package:muslim_calendar/data/repositories/google_event_mapping_repository.dart';
import 'package:muslim_calendar/data/services/google_calendar_service.dart';

// Wir verwenden die GoogleHttpClient-Klasse direkt aus GoogleCalendarService

/// GoogleCalendarSyncConfig enthält Konstanten und Hilfsmethoden zur Konfiguration der Synchronisierung
class GoogleCalendarSyncConfig {
  // Konfigurationsparameter für die Synchronisierung
  static const int maxFutureMonths = 3;
  static const int maxEventsPerSeries = 50;

  // Limitierung für Batch-Operationen
  static const int maxBatchSize = 10;

  // Zeitfenster für die Synchronisierung (28 Tage)
  static const Duration syncWindow = Duration(days: 28);

  // Zeitraum, nach dem alte Mappings bereinigt werden (7 Tage in der Vergangenheit)
  static const Duration cleanupThreshold = Duration(days: 7);

  // Berechnet den Synchronisierungszeitraum
  static DateTimeRange calculateSyncRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(
          days:
              1)), // Ein Tag in der Vergangenheit für bereits begonnene Termine
      end: now.add(syncWindow),
    );
  }

  // Berechnet das Datum für Cleanup alter Mappings
  static DateTime calculateCleanupDate() {
    return DateTime.now().subtract(cleanupThreshold);
  }
}

/// GoogleCalendarSyncService - Effiziente Batch-Synchronisierung mit Google Calendar
///
/// Dieser Service ist für die effiziente Synchronisierung zwischen der lokalen
/// Datenbank und Google Calendar optimiert. Seine Hauptaufgaben umfassen:
///
/// 1. Batch-Verarbeitung von Terminen für bessere Performance
/// 2. Management von Zuordnungen zwischen lokalen und Google-Events
/// 3. Spezielle Behandlung von wiederkehrenden Terminen
/// 4. Zeitfenster-basierte Synchronisierung
/// 5. Bereinigung veralteter Mappings
///
/// Der Service implementiert ChangeNotifier für UI-Updates und verwendet ein Repository
/// zur Speicherung der Mappings zwischen lokalen und Google-Events.
///
/// Im Gegensatz zum GoogleCalendarService, der low-level API-Operationen durchführt,
/// konzentriert sich dieser Service auf effiziente Synchronisierung mehrerer Termine.
class GoogleCalendarSyncService with ChangeNotifier {
  // Dependencies
  final AppointmentRepository _appointmentRepo;
  final PrayerTimeService _prayerTimeService;
  final GoogleEventMappingRepository _mappingRepo;
  final PrayerTimeAppointmentAdapter _appointmentAdapter;

  // Google API Client
  gCal.CalendarApi? _calendarApi;
  String? _selectedCalendarId;

  // Status Flags
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Konstruktor mit Required Services
  GoogleCalendarSyncService({
    required AppointmentRepository appointmentRepo,
    required PrayerTimeService prayerTimeService,
    required GoogleEventMappingRepository mappingRepo,
    required PrayerTimeAppointmentAdapter appointmentAdapter,
  })  : _appointmentRepo = appointmentRepo,
        _prayerTimeService = prayerTimeService,
        _mappingRepo = mappingRepo,
        _appointmentAdapter = appointmentAdapter;

  // Initialisiert die Google API mit einem AuthClient
  Future<bool> initialize(AuthClient client) async {
    try {
      _calendarApi = gCal.CalendarApi(client);
      await _loadSelectedCalendarId();
      return true;
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung: $e');
      return false;
    }
  }

  /// Hilfsmethode zur Initialisierung des API-Clients
  Future<bool> _initializeApiClient() async {
    try {
      // Integration mit GoogleCalendarService für die Authentifizierung
      final googleCalendarService = GoogleCalendarService();

      // Prüfen ob bereits angemeldet, ansonsten Anmeldung versuchen
      if (!googleCalendarService.isSignedIn) {
        final signInSuccess = await googleCalendarService.signIn();
        if (!signInSuccess) {
          debugPrint("Konnte nicht bei Google anmelden");
          return false;
        }
      }

      // Google-Nutzer abrufen
      final currentUser = googleCalendarService.currentUser;
      if (currentUser == null) {
        debugPrint("Kein Google-Nutzer angemeldet");
        return false;
      }

      // Authentifizierungsheader holen und Calendar API initialisieren
      final authHeaders = await currentUser.authHeaders;
      final client = http.Client();
      final httpClient = GoogleHttpClient(authHeaders, client);
      _calendarApi = gCal.CalendarApi(httpClient);

      return _calendarApi != null;
    } catch (e) {
      debugPrint("Fehler bei der API-Client-Initialisierung: $e");
      return false;
    }
  }

  // Lädt die gespeicherte Kalender-ID
  Future<void> _loadSelectedCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCalendarId = prefs.getString('google_calendar_id');
    if (_selectedCalendarId == null) {
      // Falls keine ID gespeichert ist, primären Kalender verwenden
      try {
        final calendars = await _calendarApi?.calendarList.list();
        final primaryCalendar = calendars?.items?.firstWhere(
          (cal) => cal.primary == true,
          orElse: () => calendars.items!.first,
        );
        _selectedCalendarId = primaryCalendar?.id;

        // Speichern der ausgewählten Kalender-ID
        if (_selectedCalendarId != null) {
          await prefs.setString('google_calendar_id', _selectedCalendarId!);
        }
      } catch (e) {
        debugPrint('Fehler beim Laden der Kalender-ID: $e');
      }
    }
  }

  // Ändert den ausgewählten Google Kalender
  Future<bool> setSelectedCalendar(String calendarId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_calendar_id', calendarId);
      _selectedCalendarId = calendarId;
      return true;
    } catch (e) {
      debugPrint('Fehler beim Ändern des Kalenders: $e');
      return false;
    }
  }

  // Hauptmethode: Synchronisiert alle Termine mit Google Calendar
  Future<bool> syncAllAppointments() async {
    // Falls noch nicht initialisiert, versuche die Initialisierung
    if (_calendarApi == null || _selectedCalendarId == null) {
      try {
        // Versuche, API-Client und Kalender-ID zu initialisieren
        await _initializeApiClient();
        await _loadSelectedCalendarId();
      } catch (e) {
        debugPrint("Fehler bei der Initialisierung: $e");
        return false;
      }

      // Prüfen, ob die Initialisierung erfolgreich war
      if (_calendarApi == null || _selectedCalendarId == null) {
        return false;
      }
    }

    if (_isSyncing) {
      debugPrint("Synchronisierung läuft bereits");
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Zeitfenster für die Synchronisierung berechnen
      final syncRange = GoogleCalendarSyncConfig.calculateSyncRange();

      // 2. Alte Mappings bereinigen
      final cleanupDate = GoogleCalendarSyncConfig.calculateCleanupDate();
      await _mappingRepo.cleanupOldMappings(cleanupDate);

      // 3. Alle Termine laden, die mit Google synchronisiert werden sollen
      final allAppointments = await _appointmentRepo.getAllAppointments();
      final toSyncAppointments =
          allAppointments.where((a) => a.syncWithGoogleCalendar).toList();

      // 4. Priorisierung: Termine nach Datum sortieren (nahe Termine zuerst)
      toSyncAppointments.sort((a, b) {
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

      // 5. Batch-Verarbeitung der Termine
      List<Future> batchOperations = [];
      int batchCount = 0;

      for (final appointment in toSyncAppointments) {
        if (appointment.startTime == null) continue;

        // Normaler Termin oder wiederkehrender gebetszeitabhängiger Termin?
        if (appointment.isRelatedToPrayerTimes &&
            appointment.recurrenceRule != null) {
          // Gebetszeitabhängige wiederkehrende Termine als Einzeltermine behandeln
          await _syncRecurringPrayerTimeAppointment(appointment, syncRange);
        } else if (appointment.recurrenceRule != null) {
          // Normale wiederkehrende Termine
          await _syncRecurringAppointment(appointment);
        } else {
          // Einzeltermine
          final operation = _syncSingleAppointment(appointment);
          batchOperations.add(operation);
          batchCount++;

          // Batch-Verarbeitung, wenn maximale Größe erreicht ist
          if (batchCount >= GoogleCalendarSyncConfig.maxBatchSize) {
            await Future.wait(batchOperations);
            batchOperations = [];
            batchCount = 0;
          }
        }
      }

      // Restliche Batch-Operationen ausführen
      if (batchOperations.isNotEmpty) {
        await Future.wait(batchOperations);
      }

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Fehler bei der Synchronisierung: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Synchronisiert einen einzelnen Termin
  Future<bool> _syncSingleAppointment(AppointmentModel appointment) async {
    try {
      if (_calendarApi == null ||
          _selectedCalendarId == null ||
          appointment.id == null) {
        debugPrint(
            'Synchronisierung nicht möglich: API nicht initialisiert oder Termin-ID fehlt');
        return false;
      }

      DateTime startTime;
      DateTime endTime;

      if (appointment.isRelatedToPrayerTimes) {
        // Berechne die genauen Zeiten basierend auf Gebetszeiten
        final calculatedStart = await _prayerTimeService.getCalculatedStartTime(
            appointment, appointment.startTime!);
        final calculatedEnd = await _prayerTimeService.getCalculatedEndTime(
            appointment, appointment.startTime!);

        if (calculatedStart == null || calculatedEnd == null) {
          debugPrint(
              'Warnung: Gebetszeit-Berechnung fehlgeschlagen für Termin: ${appointment.subject}');
          return false;
        }

        startTime = calculatedStart;
        endTime = calculatedEnd;

        // Debug-Ausgabe für berechnete Zeiten
        debugPrint('Gebetszeit-abhängiger Termin "${appointment.subject}":');
        debugPrint('- Original startTime: ${appointment.startTime}');
        debugPrint(
            '- Berechnet startTime: $startTime (${startTime.timeZoneName})');
        debugPrint('- Berechnet endTime: $endTime (${endTime.timeZoneName})');
        debugPrint('- Gebetszeit: ${appointment.prayerTime}');
        debugPrint('- Relation: ${appointment.timeRelation}');
        debugPrint(
            '- Minuten vorher/nachher: ${appointment.minutesBeforeAfter}');
      } else {
        // Normale Termine ohne Gebetszeitabhängigkeit
        if (appointment.startTime == null || appointment.endTime == null) {
          debugPrint(
              'Fehler: Start- oder Endzeit fehlt für ${appointment.subject}');
          return false;
        }
        startTime = appointment.startTime!;
        endTime = appointment.endTime!;
      }

      // Prüfen, ob der Termin bereits synchronisiert wurde
      final existingMapping = await _mappingRepo.getMappingForDate(
        appointment.id!,
        startTime,
      );

      // Google Event erstellen oder aktualisieren
      final event = _createGoogleEvent(
        appointment.subject,
        startTime,
        endTime,
        notes: appointment.notes,
        location: appointment.location,
        isAllDay: appointment.isAllDay,
        reminderMinutes: appointment.reminderMinutesBefore,
      );

      try {
        if (existingMapping != null) {
          // Event aktualisieren
          debugPrint('Aktualisiere Google Event für "${appointment.subject}"');
          await _calendarApi!.events.update(
            event,
            _selectedCalendarId!,
            existingMapping.googleEventId,
          );

          // Mapping aktualisieren
          await _mappingRepo.saveMapping(
            GoogleEventMapping(
              id: existingMapping.id,
              localAppointmentId: appointment.id!,
              originalDate: startTime.toIso8601String().split('T')[0],
              googleEventId: existingMapping.googleEventId,
              lastSyncedAt: DateTime.now(),
            ),
          );
        } else {
          // Neues Event erstellen
          debugPrint(
              'Erstelle neues Google Event für "${appointment.subject}"');
          debugPrint('- Event-Zusammenfassung: ${event.summary}');
          debugPrint(
              '- Event-Startzeit: ${event.start?.dateTime} (Zeitzone: ${event.start?.timeZone})');
          debugPrint(
              '- Event-Endzeit: ${event.end?.dateTime} (Zeitzone: ${event.end?.timeZone})');

          final createdEvent = await _calendarApi!.events.insert(
            event,
            _selectedCalendarId!,
          );

          debugPrint(
              'Google Event erfolgreich erstellt, ID: ${createdEvent.id}');

          // Neues Mapping speichern
          await _mappingRepo.saveMapping(
            GoogleEventMapping(
              localAppointmentId: appointment.id!,
              originalDate: startTime.toIso8601String().split('T')[0],
              googleEventId: createdEvent.id!,
              lastSyncedAt: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        // Spezifischere Fehlerbehandlung für API-Fehler
        if (e.toString().contains('401')) {
          debugPrint('Authentifizierungsfehler (401) beim Synchronisieren: $e');
          throw Exception(
              'Authentifizierungsfehler: Bitte erneut anmelden. Details: $e');
        } else {
          debugPrint('Google API-Fehler beim Synchronisieren: $e');
          throw e; // Fehler weitergeben für allgemeine Fehlerbehandlung
        }
      }

      return true;
    } catch (e) {
      debugPrint('Fehler beim Synchronisieren des Einzeltermins: $e');
      return false;
    }
  }

  // Synchronisiert einen normalen wiederkehrenden Termin
  Future<bool> _syncRecurringAppointment(AppointmentModel appointment) async {
    try {
      if (_calendarApi == null ||
          _selectedCalendarId == null ||
          appointment.id == null) {
        return false;
      }

      if (appointment.startTime == null || appointment.endTime == null) {
        return false;
      }

      // Prüfen, ob bereits ein Google Event existiert
      final existingMappings =
          await _mappingRepo.getMappingsForAppointment(appointment.id!);
      String? googleEventId;

      if (existingMappings.isNotEmpty) {
        // Bei wiederkehrenden Terminen nehmen wir die erste Mapping-ID
        googleEventId = existingMappings.first.googleEventId;
      }

      // Google Event mit Wiederholungsregel erstellen
      final event = _createGoogleEvent(
        appointment.subject,
        appointment.startTime!,
        appointment.endTime!,
        notes: appointment.notes,
        location: appointment.location,
        isAllDay: appointment.isAllDay,
        reminderMinutes: appointment.reminderMinutesBefore,
        recurrenceRule: appointment.recurrenceRule,
      );

      if (googleEventId != null) {
        // Event aktualisieren
        await _calendarApi!.events.update(
          event,
          _selectedCalendarId!,
          googleEventId,
        );
      } else {
        // Neues Event erstellen
        final createdEvent = await _calendarApi!.events.insert(
          event,
          _selectedCalendarId!,
        );

        // Mapping für die Serie speichern (mit dem Datum des ersten Vorkommens)
        await _mappingRepo.saveMapping(
          GoogleEventMapping(
            localAppointmentId: appointment.id!,
            originalDate:
                appointment.startTime!.toIso8601String().split('T')[0],
            googleEventId: createdEvent.id!,
            lastSyncedAt: DateTime.now(),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Fehler beim Synchronisieren des wiederkehrenden Termins: $e');
      return false;
    }
  }

  // Synchronisiert einen gebetszeitabhängigen wiederkehrenden Termin als Serie von Einzelterminen
  Future<bool> _syncRecurringPrayerTimeAppointment(
    AppointmentModel appointment,
    DateTimeRange syncRange,
  ) async {
    try {
      if (_calendarApi == null ||
          _selectedCalendarId == null ||
          appointment.id == null) {
        return false;
      }

      debugPrint(
          'Synchronisiere gebetszeitabhängigen wiederkehrenden Termin: ${appointment.subject}');
      debugPrint('- Gebetszeit: ${appointment.prayerTime}');
      debugPrint('- Relation: ${appointment.timeRelation}');
      debugPrint('- Minuten vorher/nachher: ${appointment.minutesBeforeAfter}');
      debugPrint('- Wiederholungsregel: ${appointment.recurrenceRule}');

      // 1. Alle Vorkommen innerhalb des Synchronisierungszeitraums ermitteln
      final instances = await _appointmentAdapter.getAppointmentsForRange(
        appointment,
        syncRange.start,
        syncRange.end,
      );

      debugPrint('Anzahl Termininstanzen im Zeitraum: ${instances.length}');

      // 2. Limitierung der Anzahl der Instanzen
      final limitedInstances = instances.length >
              GoogleCalendarSyncConfig.maxEventsPerSeries
          ? instances.sublist(0, GoogleCalendarSyncConfig.maxEventsPerSeries)
          : instances;

      if (instances.length > GoogleCalendarSyncConfig.maxEventsPerSeries) {
        debugPrint(
            'Anzahl der Instanzen wurde begrenzt auf: ${GoogleCalendarSyncConfig.maxEventsPerSeries}');
      }

      // 3. Bestehende Mappings für diesen Termin laden
      final existingMappings =
          await _mappingRepo.getMappingsForAppointment(appointment.id!);
      final existingMappingsByDate = {
        for (var mapping in existingMappings) mapping.originalDate: mapping
      };

      // 4. Batch-Verarbeitung für die Instanzen
      List<Future> batchOperations = [];
      int batchCount = 0;

      for (final instance in limitedInstances) {
        final originalDate = instance.startTime.toIso8601String().split('T')[0];
        final existing = existingMappingsByDate[originalDate];

        // Debug-Ausgabe für jede Instanz
        debugPrint('Verarbeite Instanz für ${originalDate}:');
        debugPrint('- Start: ${instance.startTime}');
        debugPrint('- Ende: ${instance.endTime}');

        if (existing != null) {
          // Event aktualisieren
          final event = _createGoogleEvent(
            instance.subject,
            instance.startTime,
            instance.endTime,
            notes: instance.notes,
            location: instance.location,
            isAllDay: instance.isAllDay,
            // Keine Wiederholungsregel bei Einzelinstanzen
          );

          debugPrint('Aktualisiere bestehende Instanz für ${originalDate}');
          final operation = _calendarApi!.events
              .update(
            event,
            _selectedCalendarId!,
            existing.googleEventId,
          )
              .then((_) {
            return _mappingRepo.saveMapping(
              GoogleEventMapping(
                id: existing.id,
                localAppointmentId: appointment.id!,
                originalDate: originalDate,
                googleEventId: existing.googleEventId,
                lastSyncedAt: DateTime.now(),
              ),
            );
          }).catchError((e) {
            debugPrint(
                'Fehler beim Aktualisieren der Instanz ${originalDate}: $e');
          });

          batchOperations.add(operation);
        } else {
          // Neues Event erstellen
          final event = _createGoogleEvent(
            instance.subject,
            instance.startTime,
            instance.endTime,
            notes: instance.notes,
            location: instance.location,
            isAllDay: instance.isAllDay,
            // Keine Wiederholungsregel bei Einzelinstanzen
          );

          debugPrint('Erstelle neue Instanz für ${originalDate}');
          final operation = _calendarApi!.events
              .insert(
            event,
            _selectedCalendarId!,
          )
              .then((createdEvent) {
            return _mappingRepo.saveMapping(
              GoogleEventMapping(
                localAppointmentId: appointment.id!,
                originalDate: originalDate,
                googleEventId: createdEvent.id!,
                lastSyncedAt: DateTime.now(),
              ),
            );
          }).catchError((e) {
            debugPrint('Fehler beim Erstellen der Instanz ${originalDate}: $e');
          });

          batchOperations.add(operation);
        }

        batchCount++;

        // Batch-Verarbeitung, wenn maximale Größe erreicht ist
        if (batchCount >= GoogleCalendarSyncConfig.maxBatchSize) {
          await Future.wait(batchOperations);
          batchOperations = [];
          batchCount = 0;
        }
      }

      // Restliche Batch-Operationen ausführen
      if (batchOperations.isNotEmpty) {
        await Future.wait(batchOperations);
      }

      return true;
    } catch (e) {
      debugPrint(
          'Fehler beim Synchronisieren des gebetszeitabhängigen Termins: $e');
      return false;
    }
  }

  // Löscht einen Termin aus Google Calendar
  Future<bool> deleteAppointmentFromGoogle(int appointmentId) async {
    try {
      if (_calendarApi == null || _selectedCalendarId == null) {
        return false;
      }

      // Alle Mappings für diesen Termin laden
      final mappings =
          await _mappingRepo.getMappingsForAppointment(appointmentId);

      // Batch-Verarbeitung für das Löschen
      List<Future> batchOperations = [];
      int batchCount = 0;

      for (final mapping in mappings) {
        final operation = _calendarApi!.events
            .delete(
          _selectedCalendarId!,
          mapping.googleEventId,
        )
            .catchError((e) {
          debugPrint('Fehler beim Löschen des Events: $e');
        });

        batchOperations.add(operation);
        batchCount++;

        // Batch-Verarbeitung, wenn maximale Größe erreicht ist
        if (batchCount >= GoogleCalendarSyncConfig.maxBatchSize) {
          await Future.wait(batchOperations);
          batchOperations = [];
          batchCount = 0;
        }
      }

      // Restliche Batch-Operationen ausführen
      if (batchOperations.isNotEmpty) {
        await Future.wait(batchOperations);
      }

      // Alle Mappings für diesen Termin löschen
      await _mappingRepo.deleteMappingsForAppointment(appointmentId);

      return true;
    } catch (e) {
      debugPrint('Fehler beim Löschen des Termins: $e');
      return false;
    }
  }

  // Erstellt ein Google Event aus den übergebenen Parametern
  gCal.Event _createGoogleEvent(
    String subject,
    DateTime startTime,
    DateTime endTime, {
    String? notes,
    String? location,
    bool isAllDay = false,
    int? reminderMinutes,
    String? recurrenceRule,
  }) {
    // Zeitformatierung
    final event = gCal.Event();
    event.summary = subject;
    event.description = notes;
    event.location = location;

    // Start- und Endzeit
    if (isAllDay) {
      // Ganztägiges Event (nur Datum, keine Uhrzeit)
      event.start = gCal.EventDateTime(
        date: DateTime(startTime.year, startTime.month, startTime.day),
      );
      event.end = gCal.EventDateTime(
        date: DateTime(endTime.year, endTime.month, endTime.day),
      );
    } else {
      // Event mit Start- und Endzeit
      // Wir senden die lokalen Zeiten ohne Zeitzonenkonvertierung und lassen
      // Google Calendar die richtige Zeitzone basierend auf der Konfiguration des Benutzers verwenden
      event.start = gCal.EventDateTime(
        dateTime: startTime,
      );

      event.end = gCal.EventDateTime(
        dateTime: endTime,
      );
    }

    // Wiederholungsregel
    if (recurrenceRule != null) {
      event.recurrence = ['RRULE:$recurrenceRule'];
    }

    // Erinnerung
    if (reminderMinutes != null) {
      event.reminders = gCal.EventReminders(
        useDefault: false,
        overrides: [
          gCal.EventReminder(
            method: 'popup',
            minutes: reminderMinutes,
          ),
        ],
      );
    }

    return event;
  }

  // Periodische Synchronisierung planen
  void schedulePeriodicSync(Duration interval) {
    Timer.periodic(interval, (_) async {
      if (!_isSyncing) {
        await syncAllAppointments();
      }
    });
  }
}
