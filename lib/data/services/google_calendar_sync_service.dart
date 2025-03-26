import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gCal;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Taqvimi/models/appointment_model.dart';
import 'package:Taqvimi/data/repositories/appointment_repository.dart';
import 'package:Taqvimi/data/services/prayer_time_service.dart';
import 'package:Taqvimi/ui/widgets/prayer_time_appointment_adapter.dart';
import 'package:Taqvimi/data/repositories/google_event_mapping_repository.dart';
import 'package:Taqvimi/data/services/google_calendar_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Taqvimi/data/services/google_sign_in_service.dart';

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
  final CategoryRepository _categoryRepo;
  final GoogleSignInService _signInService = GoogleSignInService();

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
    required CategoryRepository categoryRepo,
  })  : _appointmentRepo = appointmentRepo,
        _prayerTimeService = prayerTimeService,
        _mappingRepo = mappingRepo,
        _appointmentAdapter = appointmentAdapter,
        _categoryRepo = categoryRepo;

  // Initialisiert die Google API mit einem AuthClient
  Future<bool> initialize(http.Client client) async {
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
      // debugPrint("Synchronisierung läuft bereits");
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

      // Debug-Ausgabe: Wie viele Termine haben syncWithGoogleCalendar=true?
      final markedForSync =
          allAppointments.where((a) => a.syncWithGoogleCalendar).toList();
      // debugPrint(
      //     "Termine markiert für Synchronisierung: ${markedForSync.length} von ${allAppointments.length}");

      // Wenn keine Termine für Synchronisierung markiert sind, verwenden wir alle Termine
      List<AppointmentModel> appointmentsToSync;
      if (markedForSync.isEmpty) {
        debugPrint(
            "⚠️ Keine Termine für Synchronisierung markiert! Verwende alle Termine.");
        appointmentsToSync = allAppointments;
      } else {
        appointmentsToSync = markedForSync;
      }

      // Filtere Termine, die bereits von Google importiert wurden
      final toSyncAppointments = appointmentsToSync
          .where(
              (a) => a.externalIdGoogle == null || a.externalIdGoogle!.isEmpty)
          .toList();

      // debugPrint("📊 ${appointmentsToSync.length} Termine für Sync markiert");
      // debugPrint(
      //     "📊 ${toSyncAppointments.length} Termine zum Export (ohne von Google importierte)");
      // debugPrint(
      //     "📊 ${appointmentsToSync.length - toSyncAppointments.length} Termine übersprungen (von Google importiert)");

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

      // Implementierung der Kategorie-zu-Kalender-Zuordnung
      String targetCalendarId = _selectedCalendarId!;

      // Wenn die Kategorie bekannt ist, versuche einen entsprechenden Kalender zu finden
      if (appointment.categoryId != null && appointment.categoryId! > 0) {
        debugPrint(
            "🔍 Suche nach Zielkalender für Kategorie ID: ${appointment.categoryId}");

        try {
          // Lade verfügbare Kalender
          final calendarList = await _calendarApi!.calendarList.list();
          final availableCalendars = calendarList.items ?? [];

          // Lade die Kategorie
          final category =
              await _categoryRepo.getCategory(appointment.categoryId!);

          if (category != null) {
            debugPrint(
                "✓ Kategorie gefunden: ${category.name} (ID: ${category.id})");

            // Suche nach einem Kalender mit demselben Namen (case-insensitive)
            final lowerCategoryName = category.name.toLowerCase().trim();

            // Erstelle eine Map für einfachere Suche
            final calendarMap = {
              for (var calendar in availableCalendars)
                calendar.summary?.toLowerCase().trim() ?? '': calendar.id ?? ''
            };

            // 1. Direkte Übereinstimmung des Namens
            if (calendarMap.containsKey(lowerCategoryName)) {
              targetCalendarId = calendarMap[lowerCategoryName]!;
              debugPrint(
                  "✅ Passender Kalender gefunden: $targetCalendarId für Kategorie: ${category.name}");
            } else {
              // 2. Suche nach partiellen Übereinstimmungen
              final partialMatches = availableCalendars.where((calendar) {
                final calendarName =
                    calendar.summary?.toLowerCase().trim() ?? '';
                return calendarName.contains(lowerCategoryName) ||
                    lowerCategoryName.contains(calendarName);
              }).toList();

              if (partialMatches.isNotEmpty) {
                targetCalendarId =
                    partialMatches.first.id ?? _selectedCalendarId!;
                debugPrint(
                    "✅ Ähnlicher Kalender gefunden: $targetCalendarId für Kategorie: ${category.name}");
              } else {
                debugPrint(
                    "ℹ️ Kein passender Kalender für Kategorie '${category.name}' gefunden, verwende Standard-Kalender");
              }
            }
          }
        } catch (e) {
          debugPrint("⚠️ Fehler bei der Kalendersuche: $e");
          // Bei Fehlern verwenden wir den Standard-Kalender
        }
      }

      // debugPrint(
      //     "🎯 Verwende Kalender: $targetCalendarId für Termin: ${appointment.subject}");

      // Überprüfe, ob der Termin bereits in Google existiert
      final existingMapping = await _mappingRepo.getMappingForLocalAppointment(
          appointment.id!, 'google');

      if (existingMapping != null && existingMapping.externalId.isNotEmpty) {
        // Termin aktualisieren
        final existingEvent = await _calendarApi!.events
            .get(targetCalendarId, existingMapping.externalId);

        // Konvertiere Appointment zu Google Event und aktualisiere
        final updatedEvent = await _createGoogleEvent(
          appointment.subject,
          appointment.startTime!,
          appointment.endTime!,
          notes: appointment.notes,
          location: appointment.location,
          isAllDay: appointment.isAllDay,
          reminderMinutes: appointment.reminderMinutesBefore,
          recurrenceRule: appointment.recurrenceRule,
          appointmentId: appointment.id,
        );
        await _calendarApi!.events
            .update(updatedEvent, targetCalendarId, existingMapping.externalId);

        // Aktualisiere Zeitstempel in der lokalen Datenbank
        await _appointmentRepo.updateSyncTimestamp(
            appointment.id!, DateTime.now().toIso8601String());

        // debugPrint(
        //     '✅ Termin ${appointment.id} in Google aktualisiert (Google-ID: ${existingMapping.externalId})');
        return true;
      }

      // Neuen Termin erstellen
      final newEvent = await _createGoogleEvent(
        appointment.subject,
        appointment.startTime!,
        appointment.endTime!,
        notes: appointment.notes,
        location: appointment.location,
        isAllDay: appointment.isAllDay,
        reminderMinutes: appointment.reminderMinutesBefore,
        recurrenceRule: appointment.recurrenceRule,
        appointmentId: appointment.id,
      );
      final createdEvent =
          await _calendarApi!.events.insert(newEvent, targetCalendarId);

      if (createdEvent.id != null) {
        // Speichere Mapping zwischen Google Event ID und lokalem Appointment
        await _mappingRepo.addMapping(
          localId: appointment.id!,
          externalId: createdEvent.id!,
          source: 'google',
          sourceCalendarId: targetCalendarId,
        );

        // Aktualisiere externalIdGoogle und lastSyncedAt in der Datenbank
        await _appointmentRepo.updateExternalId(
          appointment.id!,
          createdEvent.id!,
          'google',
          DateTime.now().toIso8601String(),
        );

        // debugPrint(
        //     '✅ Neuer Termin ${appointment.id} in Google erstellt (Google-ID: ${createdEvent.id})');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
          'Fehler beim Synchronisieren des Termins ${appointment.id}: $e');
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
      final event = await _createGoogleEvent(
        appointment.subject,
        appointment.startTime!,
        appointment.endTime!,
        notes: appointment.notes,
        location: appointment.location,
        isAllDay: appointment.isAllDay,
        reminderMinutes: appointment.reminderMinutesBefore,
        recurrenceRule: appointment.recurrenceRule,
        appointmentId: appointment.id,
        isRecurringInstance: true,
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

      // debugPrint(
      //     "🕌 Synchronisiere gebetszeitabhängigen Termin mit Wiederholung: ${appointment.subject}");
      // debugPrint("🔄 Wiederholungsregel: ${appointment.recurrenceRule}");

      // 1. Alle Vorkommen innerhalb des Synchronisierungszeitraums ermitteln
      final instances = await _appointmentAdapter.getAppointmentsForRange(
        appointment,
        syncRange.start,
        syncRange.end,
      );

      // debugPrint(
      //     "📅 ${instances.length} Instanzen im Zeitfenster ${syncRange.start.toIso8601String()} bis ${syncRange.end.toIso8601String()}");

      if (instances.isEmpty) {
        // debugPrint(
        //     "⚠️ Keine Instanzen gefunden - überspringe Synchronisierung");
        return true; // Erfolgreich, da nichts zu synchronisieren
      }

      // 2. Limitierung der Anzahl der Instanzen
      final limitedInstances = instances.length >
              GoogleCalendarSyncConfig.maxEventsPerSeries
          ? instances.sublist(0, GoogleCalendarSyncConfig.maxEventsPerSeries)
          : instances;

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
        // debugPrint('Verarbeite Instanz für $originalDate:');
        // debugPrint('- Start: ${instance.startTime}');
        // debugPrint('- Ende: ${instance.endTime}');

        if (existing != null) {
          // Event aktualisieren
          final event = await _createGoogleEvent(
            instance.subject,
            instance.startTime,
            instance.endTime,
            notes: instance.notes,
            location: instance.location,
            isAllDay: instance.isAllDay,
            appointmentId: appointment.id,
            isRecurringInstance: true,
          );

          //  debugPrint('Aktualisiere bestehende Instanz für $originalDate');
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
                'Fehler beim Aktualisieren der Instanz $originalDate: $e');
          });

          batchOperations.add(operation);
        } else {
          // Neues Event erstellen
          final event = await _createGoogleEvent(
            instance.subject,
            instance.startTime,
            instance.endTime,
            notes: instance.notes != null
                ? "${instance.notes}\n\n(Wiederkehrender Termin vom ${appointment.startTime != null ? appointment.startTime!.toIso8601String().split('T')[0] : 'unbekannt'})"
                : "(Wiederkehrender Termin vom ${appointment.startTime != null ? appointment.startTime!.toIso8601String().split('T')[0] : 'unbekannt'})",
            location: instance.location,
            isAllDay: instance.isAllDay,
            appointmentId: appointment.id,
            isRecurringInstance: true,
          );

          // Private Eigenschaften hinzufügen für die Zuordnung zum Haupttermin
          if (event.extendedProperties == null) {
            event.extendedProperties = gCal.EventExtendedProperties(
              private: {
                'muslimcalendarID': appointment.id.toString(),
                'instanceDate': originalDate,
              },
            );
          } else {
            event.extendedProperties!.private ??= {};
            event.extendedProperties!.private!
                .addAll({'muslimcalendarID': appointment.id.toString()});
            event.extendedProperties!.private!
                .addAll({'instanceDate': originalDate});
          }

          // debugPrint('Erstelle neue Instanz für $originalDate');
          final operation = _calendarApi!.events
              .insert(
            event,
            _selectedCalendarId!,
          )
              .then((createdEvent) {
            // debugPrint('Event für $originalDate erstellt: ${createdEvent.id}');
            return _mappingRepo.saveMapping(
              GoogleEventMapping(
                localAppointmentId: appointment.id!,
                originalDate: originalDate,
                googleEventId: createdEvent.id!,
                lastSyncedAt: DateTime.now(),
              ),
            );
          }).catchError((e) {
            debugPrint('Fehler beim Erstellen der Instanz $originalDate: $e');
          });

          batchOperations.add(operation);
        }

        // Batch-Verarbeitung nach konstanter Größe
        batchCount++;
        if (batchCount >= GoogleCalendarSyncConfig.maxBatchSize) {
          await Future.wait(batchOperations);
          batchOperations = [];
          batchCount = 0;
        }
      }

      // Restliche Operationen verarbeiten
      if (batchOperations.isNotEmpty) {
        await Future.wait(batchOperations);
      }

      // Verwende die bestehende Methode zum Löschen veralteter Mappings
      for (final mapping in existingMappings) {
        final isStillValid = limitedInstances.any((instance) =>
            instance.startTime.toIso8601String().split('T')[0] ==
            mapping.originalDate);

        if (!isStillValid) {
          // Mapping und Event löschen
          if (mapping.googleEventId.isNotEmpty) {
            try {
              await _calendarApi!.events
                  .delete(_selectedCalendarId!, mapping.googleEventId);
              // debugPrint('Veraltetes Event gelöscht: ${mapping.googleEventId}');
            } catch (e) {
              debugPrint(
                  'Fehler beim Löschen des Events ${mapping.googleEventId}: $e');
            }
          }

          // Mapping aus der Datenbank löschen
          if (mapping.id != null) {
            await _mappingRepo.deleteMapping(mapping.id!);
            // debugPrint('Veraltetes Mapping gelöscht: ID ${mapping.id}');
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint(
          'Fehler bei der Synchronisation des Termins ${appointment.subject}: $e');
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
  Future<gCal.Event> _createGoogleEvent(
    String subject,
    DateTime startTime,
    DateTime endTime, {
    String? notes,
    String? location,
    bool isAllDay = false,
    int? reminderMinutes,
    String? recurrenceRule,
    int? appointmentId,
    bool isRecurringInstance = false,
  }) async {
    // Zeitformatierung
    final event = gCal.Event();
    event.summary = subject;
    event.description = notes;
    event.location = location;

    // Lokale Zeitzone ermitteln
    final localTimeZone = await _getLocalTimeZone();

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
      event.start = gCal.EventDateTime(
        dateTime: startTime,
        timeZone: localTimeZone,
      );

      event.end = gCal.EventDateTime(
        dateTime: endTime,
        timeZone: localTimeZone,
      );

      // Debug-Ausgabe für Zeitzonenprobleme
      // debugPrint('Event Zeitzone für $subject:');
      // debugPrint('- Verwendete Zeitzone: $localTimeZone');
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

    // Erweiterte Eigenschaften für die Synchronisierung
    if (appointmentId != null) {
      // Berechne einen Hash aus relevanten Eigenschaften
      final appointmentHash = _calculateAppointmentHash(subject, startTime,
          endTime, notes ?? '', location ?? '', recurrenceRule ?? '');

      // Aktueller Zeitstempel für die letzte Synchronisierung
      final now = DateTime.now().toIso8601String();

      // Extended Properties setzen oder aktualisieren
      if (event.extendedProperties == null) {
        event.extendedProperties = gCal.EventExtendedProperties(
          private: {
            'localAppID': appointmentId.toString(),
            'isRecurringInstance': isRecurringInstance.toString(),
            'lastExported': now,
            'appointmentHash': appointmentHash,
          },
        );
      } else {
        event.extendedProperties!.private ??= {};
        event.extendedProperties!.private!.addAll({
          'localAppID': appointmentId.toString(),
          'isRecurringInstance': isRecurringInstance.toString(),
          'lastExported': now,
          'appointmentHash': appointmentHash,
        });
      }
    }

    return event;
  }

  // Hilfsmethode: Berechnet einen Hash der Appointment-Eigenschaften
  String _calculateAppointmentHash(String subject, DateTime startTime,
      DateTime endTime, String notes, String location, String recurrenceRule) {
    final hashInput =
        '$subject|${startTime.toIso8601String()}|${endTime.toIso8601String()}|$notes|$location|$recurrenceRule';

    // Einfacher Hash-Algorithmus (für komplexere Anwendungen könnte man crypto verwenden)
    int hash = 0;
    for (int i = 0; i < hashInput.length; i++) {
      hash = ((hash << 5) - hash) + hashInput.codeUnitAt(i);
      hash &= 0xFFFFFFFF; // 32-bit Integer Begrenzung
    }

    return hash.toRadixString(16); // Hexadezimale Darstellung
  }

  // Ermittelt die lokale Zeitzone
  Future<String> _getLocalTimeZone() async {
    try {
      final String timeZone = await FlutterTimezone.getLocalTimezone();

      // Prüfen, ob wir einen gültigen IANA-Namen haben
      if (timeZone == 'GMT' || timeZone.isEmpty) {
        // Deutschland ist standardmäßig in Europe/Berlin
        return 'Europe/Berlin';
      }

      // debugPrint('Verwendete IANA-Zeitzone: $timeZone');
      return timeZone;
    } catch (e) {
      // Fallback zur Standardzeitzone des Geräts
      debugPrint('Fehler beim Ermitteln der Zeitzone: $e');
      // Deutschland ist standardmäßig in Europe/Berlin
      return 'Europe/Berlin';
    }
  }

  // Periodische Synchronisierung planen
  void schedulePeriodicSync(Duration interval) {
    Timer.periodic(interval, (_) async {
      if (!_isSyncing) {
        await syncAllAppointments();
      }
    });
  }

  // Diese Methode kann verwendet werden, um Termine, die in Google existieren, aber lokal entfernt wurden, zu löschen
  Future<bool> deleteMissingLocalAppointments() async {
    try {
      // Prüfen, ob wir angemeldet sind und die API initialisiert ist
      if (_calendarApi == null || _selectedCalendarId == null) {
        // debugPrint('Google API nicht initialisiert. Initialisiere...');

        // Versuche die Initialisierung (ähnlich wie bei anderen Sync-Methoden)
        final GoogleSignInService _signInService = GoogleSignInService();
        final googleSignIn = _signInService.googleSignIn;

        // Versuche, aktuellen Benutzer zu bekommen oder neu anzumelden
        final account =
            await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
        if (account == null) {
          // debugPrint('Google-Anmeldung fehlgeschlagen');
          return false;
        }

        // API-Client initialisieren
        final authHeaders = await account.authentication;
        if (authHeaders.accessToken == null) {
          // debugPrint('Zugriffs-Token ist null');
          return false;
        }

        final httpClient = GoogleAuthClient(authHeaders.accessToken!);
        _calendarApi = calendar.CalendarApi(httpClient);

        // CalendarId laden oder 'primary' verwenden
        await _loadSelectedCalendarId();

        // Prüfen, ob wir jetzt initialisiert sind
        if (_calendarApi == null || _selectedCalendarId == null) {
          // debugPrint('Initialisierung war nicht erfolgreich');
          return false;
        }
      }

      // debugPrint('Suche nach Terminen in Google, die lokal gelöscht wurden...');

      // 1. Zeitspanne für die Synchronisierung festlegen
      final syncRange = GoogleCalendarSyncConfig.calculateSyncRange();
      final startDateTime = syncRange.start.toIso8601String();
      final endDateTime = syncRange.end.toIso8601String();

      // 2. Alle lokalen Appointment-IDs laden
      final localAppointmentIds = await _appointmentRepo.getAllAppointmentIds();
      final localIdsSet = Set<int>.from(localAppointmentIds);

      // debugPrint('Lokale Termin-IDs: $localIdsSet');

      // 3. Google Events im Zeitraum abrufen
      final events = await _calendarApi!.events.list(
        _selectedCalendarId!,
        timeMin: DateTime.parse(startDateTime),
        timeMax: DateTime.parse(endDateTime),
        singleEvents: true,
        maxResults: 2500, // Etwas höher als standardmäßig
      );

      // Zähler für die Statistik
      int deletedCount = 0;
      List<Future> batchOperations = [];
      int batchCount = 0;

      // 4. Für jedes Google Event prüfen, ob es eine lokale Entsprechung hat
      if (events.items != null) {
        debugPrint(
            '${events.items!.length} Events in Google Calendar gefunden');

        for (final event in events.items!) {
          // Prüfen, ob das Event die localAppID-Eigenschaft hat
          final localAppIdStr =
              event.extendedProperties?.private?['localAppID'];

          if (localAppIdStr != null) {
            final localAppId = int.tryParse(localAppIdStr);

            // Wenn die ID gültig ist und lokal nicht mehr existiert
            if (localAppId != null && !localIdsSet.contains(localAppId)) {
              debugPrint(
                  'Lokal gelöschter Termin in Google gefunden: ${event.summary} (ID: $localAppId)');

              // Löschoperation in Batch-Queue einreihen
              final operation = _calendarApi!.events
                  .delete(
                _selectedCalendarId!,
                event.id!,
              )
                  .then((_) {
                debugPrint('Google Event gelöscht: ${event.id}');
                deletedCount++;
              }).catchError((e) {
                debugPrint('Fehler beim Löschen des Events ${event.id}: $e');
              });

              batchOperations.add(operation);
              batchCount++;

              // Batch-Operationen ausführen, wenn maximale Größe erreicht ist
              if (batchCount >= GoogleCalendarSyncConfig.maxBatchSize) {
                await Future.wait(batchOperations);
                batchOperations = [];
                batchCount = 0;
              }
            }
          }
        }

        // Restliche Batch-Operationen ausführen
        if (batchOperations.isNotEmpty) {
          await Future.wait(batchOperations);
        }
      }

      debugPrint(
          'Bereinigung abgeschlossen: $deletedCount Termine in Google Calendar gelöscht');
      return true;
    } catch (e) {
      debugPrint('Fehler bei der Bereinigung gelöschter Termine: $e');
      return false;
    }
  }

  /// Exportiert alle als syncWithGoogleCalendar markierten Termine nach Google Calendar
  /// useCategoryMapping: Verwendet kategoriebasiertes Mapping für Kalenderauswahl
  Future<bool> exportToGoogleCalendarOnly(
      {bool useCategoryMapping = false}) async {
    try {
      debugPrint(
          "🔄 exportToGoogleCalendarOnly(useCategoryMapping: $useCategoryMapping) gestartet...");

      // Überprüfe API-Zugang
      if (_calendarApi == null) {
        await _initializeCalendarApi();
        if (_calendarApi == null) {
          debugPrint("❌ CalendarApi konnte nicht initialisiert werden");
          return false;
        }
      }

      // Hole alle Termine, die mit Google synchronisiert werden sollen
      final allAppointments = await _appointmentRepo.getAllAppointments();
      debugPrint("📋 Insgesamt ${allAppointments.length} Termine geladen");

      // NEU: Bereinige verwaiste Google-Termine (deren lokale Termine gelöscht wurden)
      await _cleanupOrphanedGoogleEvents(allAppointments);

      final syncAppointments =
          allAppointments.where((appt) => appt.syncWithGoogleCalendar).toList();
      debugPrint(
          "📋 Davon ${syncAppointments.length} Termine für Sync markiert");

      // Kategorie-zu-Kalender-Mapping laden
      Map<int, String> categoryCalendarMapping = {};
      if (useCategoryMapping) {
        categoryCalendarMapping = await _loadCategoryCalendarMapping();
        debugPrint(
            "🗂️ Geladen: ${categoryCalendarMapping.length} Kategorie-Kalender-Mappings");
      }

      if (syncAppointments.isEmpty) {
        debugPrint("ℹ️ Keine zu synchronisierenden Termine gefunden");
        return true; // Nichts zu tun, trotzdem Erfolg
      }

      // Erfolgs- und Fehlerzähler
      int successCount = 0;
      int errorCount = 0;

      // Bearbeite jeden Termin einzeln
      for (final appointment in syncAppointments) {
        try {
          // Wenn kategoriebasiertes Mapping aktiviert ist, finde den passenden Kalender
          String targetCalendarId = 'primary'; // Standardkalender

          if (useCategoryMapping && appointment.categoryId != null) {
            // Prüfe, ob es ein Mapping für diese Kategorie gibt
            final mappedCalendarId =
                categoryCalendarMapping[appointment.categoryId];
            if (mappedCalendarId != null && mappedCalendarId.isNotEmpty) {
              targetCalendarId = mappedCalendarId;
            }
          }

          debugPrint(
              "🎯 Verwende Kalender: $targetCalendarId für Termin: ${appointment.subject}");

          // Überprüfe, ob der Termin bereits in Google existiert
          final existingMapping = await _mappingRepo
              .getMappingForLocalAppointment(appointment.id!, 'google');

          if (existingMapping != null &&
              existingMapping.externalId.isNotEmpty) {
            // Termin aktualisieren
            final existingEvent = await _calendarApi!.events
                .get(targetCalendarId, existingMapping.externalId);

            // Konvertiere Appointment zu Google Event und aktualisiere
            final updatedEvent = await _createGoogleEvent(
              appointment.subject,
              appointment.startTime!,
              appointment.endTime!,
              notes: appointment.notes,
              location: appointment.location,
              isAllDay: appointment.isAllDay,
              reminderMinutes: appointment.reminderMinutesBefore,
              recurrenceRule: appointment.recurrenceRule,
              appointmentId: appointment.id,
            );
            await _calendarApi!.events.update(
                updatedEvent, targetCalendarId, existingMapping.externalId);

            // Aktualisiere Zeitstempel in der lokalen Datenbank
            await _appointmentRepo.updateSyncTimestamp(
                appointment.id!, DateTime.now().toIso8601String());

            debugPrint(
                "✅ Termin aktualisiert: ${appointment.subject} (ID: ${appointment.id})");
            successCount++;
          } else {
            // Neuer Termin, noch nicht in Google
            final newEvent = await _createGoogleEvent(
              appointment.subject,
              appointment.startTime!,
              appointment.endTime!,
              notes: appointment.notes,
              location: appointment.location,
              isAllDay: appointment.isAllDay,
              reminderMinutes: appointment.reminderMinutesBefore,
              recurrenceRule: appointment.recurrenceRule,
              appointmentId: appointment.id,
            );

            final createdEvent =
                await _calendarApi!.events.insert(newEvent, targetCalendarId);

            // Speichere das neue Mapping
            await _mappingRepo.addMapping(
              localId: appointment.id!,
              externalId: createdEvent.id!,
              source: 'google',
              sourceCalendarId: targetCalendarId,
            );

            // Aktualisiere externalIdGoogle im Appointment
            await _appointmentRepo.updateAppointment(appointment.copyWith(
              externalIdGoogle: createdEvent.id,
              lastSyncedAt: DateTime.now(),
            ));

            // Aktualisiere Zeitstempel
            await _appointmentRepo.updateSyncTimestamp(
                appointment.id!, DateTime.now().toIso8601String());

            debugPrint(
                "✅ Termin neu erstellt: ${appointment.subject} (ID: ${appointment.id})");
            successCount++;
          }
        } catch (e) {
          debugPrint("❌ Fehler bei Termin ${appointment.id}: $e");
          errorCount++;
        }
      }

      debugPrint(
          "🔄 Synchronisierung abgeschlossen: $successCount erfolgreich, $errorCount fehlgeschlagen");
      notifyListeners();

      return errorCount == 0;
    } catch (e) {
      debugPrint("❌ Fehler bei der Synchronisierung: $e");
      return false;
    }
  }

  /// Bereinigt verwaiste Google-Kalender-Einträge, deren lokale Termine gelöscht wurden
  Future<void> _cleanupOrphanedGoogleEvents(
      List<AppointmentModel> localAppointments) async {
    try {
      debugPrint(
          "🧹 Starte Bereinigung verwaister Google-Kalender-Einträge...");

      if (_calendarApi == null) {
        debugPrint(
            "❌ CalendarApi nicht initialisiert, Bereinigung wird übersprungen");
        return;
      }

      // Sammle alle lokalen Termin-IDs
      final Set<int> localAppointmentIds = localAppointments
          .where((appt) => appt.id != null)
          .map((appt) => appt.id!)
          .toSet();

      // Suche nach Google-Einträgen, die mit der App erstellt wurden
      final eventsResponse = await _calendarApi!.events.list(
        _selectedCalendarId ?? 'primary',
        showDeleted: false,
      );

      int deletedCount = 0;

      // Durchsuche alle Google-Events nach Extended Properties
      for (final event in eventsResponse.items ?? []) {
        // Prüfe, ob dieses Event von unserer App erstellt wurde
        final privateProps = event.extendedProperties?.private ?? {};
        final appIdString =
            privateProps['muslimcalendarID'] ?? privateProps['localAppID'];

        if (appIdString != null && appIdString.isNotEmpty) {
          try {
            // Konvertiere ID zu int und prüfe, ob der lokale Termin noch existiert
            final int appointmentId = int.parse(appIdString);

            if (!localAppointmentIds.contains(appointmentId)) {
              // Lokaler Termin existiert nicht mehr - lösche das Google-Event
              debugPrint(
                  "🗑️ Lösche verwaistes Google-Event: ${event.summary} (ID: ${event.id}, AppID: $appointmentId)");

              await _calendarApi!.events
                  .delete(_selectedCalendarId ?? 'primary', event.id!);
              deletedCount++;
            }
          } catch (e) {
            debugPrint("⚠️ Fehler beim Verarbeiten eines Google-Events: $e");
          }
        }
      }

      debugPrint(
          "✅ Bereinigung abgeschlossen, $deletedCount verwaiste Events gelöscht");
    } catch (e) {
      debugPrint("❌ Fehler bei der Bereinigung verwaister Events: $e");
    }
  }

  // Initialisiert die Google Calendar API mit OAuth2
  Future<void> _initializeCalendarApi() async {
    try {
      debugPrint("🔄 Initialisiere Google Calendar API");

      // Google SignIn-Instance aus dem Service verwenden
      final googleSignIn = _signInService.googleSignIn;

      // Prüfen, ob bereits angemeldet
      bool isSignedIn = await googleSignIn.isSignedIn();
      GoogleSignInAccount? account;

      if (isSignedIn) {
        // Versuchen, still anzumelden
        account = await googleSignIn.signInSilently();
      }

      // Wenn nicht erfolgreich, interaktive Anmeldung starten
      account ??= await googleSignIn.signIn();

      // Wenn immer noch null, ist die Anmeldung fehlgeschlagen
      if (account == null) {
        debugPrint("❌ Google Sign-In fehlgeschlagen");
        return;
      }

      // Auth-Token für die API abrufen
      final googleAuth = await account.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        debugPrint("❌ Konnte kein Access Token abrufen");
        return;
      }

      // HTTP-Client mit dem Access Token erstellen
      final httpClient = GoogleAuthClient(accessToken);
      _calendarApi = gCal.CalendarApi(httpClient);

      // Kalenderliste abrufen, um den primären Kalender zu finden
      final calendarList = await _calendarApi!.calendarList.list();

      // Standardmäßig den primären Kalender verwenden
      _selectedCalendarId = 'primary';

      // Den tatsächlichen primären Kalender finden
      for (var calendar in calendarList.items ?? []) {
        if (calendar.primary == true) {
          _selectedCalendarId = calendar.id;
          break;
        }
      }

      debugPrint("✅ Google Calendar API initialisiert: $_selectedCalendarId");
    } catch (e) {
      debugPrint("❌ Fehler bei API-Initialisierung: $e");
      _calendarApi = null;
    }
  }

  // Lädt die Kategorie-Kalender-Mappings aus der Datenbank
  Future<Map<int, String>> _loadCategoryCalendarMapping() async {
    try {
      debugPrint("🔄 Lade Kategorie-Kalender-Mappings");
      final Map<int, String> result = {};

      // Mappings aus SharedPreferences laden
      final prefs = await SharedPreferences.getInstance();
      final mappingKeys =
          prefs.getKeys().where((key) => key.startsWith('category_calendar_'));

      for (final key in mappingKeys) {
        try {
          final categoryId =
              int.parse(key.replaceFirst('category_calendar_', ''));
          final calendarId = prefs.getString(key) ?? 'primary';
          result[categoryId] = calendarId;
        } catch (e) {
          debugPrint("⚠️ Fehler beim Parsen von $key: $e");
        }
      }

      debugPrint("✅ ${result.length} Mappings geladen");
      return result;
    } catch (e) {
      debugPrint("❌ Fehler beim Laden der Mappings: $e");
      return {};
    }
  }
}

// Hilfsklasse für die Google API-Authentifizierung
class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
