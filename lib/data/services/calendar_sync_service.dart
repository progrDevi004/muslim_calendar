// lib/data/services/calendar_sync_service.dart

import 'package:flutter/cupertino.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/models/selected_calendar.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/data/services/google_calendar_service.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/utils/recurrence_rule_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/data/services/google_calendar_sync_service.dart';
import 'package:flutter/foundation.dart';

/// CalendarSyncService - Fassade (Facade) für alle Kalendersynchronisierungsdienste
///
/// Dieser Service dient als zentraler Koordinator für die Kalendersynchronisierung
/// und verwendet spezialisierte Services für konkrete Implementierungen:
///
/// 1. GoogleCalendarService für API-Aufrufe und Authentifizierung
/// 2. RecurrenceService für Wiederholungsberechnung
/// 3. PrayerTimeService für gebetszeitbezogene Termine
///
/// Die Hauptaufgaben dieses Dienstes sind:
/// - Verfügbare Kalender abrufen und verwalten
/// - Import/Export von Terminen zwischen lokaler Datenbank und externen Kalendern
/// - Kategorie-Mapping zwischen App-Kategorien und externen Kalendern
/// - Korrektur von Wiederholungsregeln
///
/// Alle UI-Komponenten sollten diesen Service verwenden, statt direkt mit den
/// spezialisierten Services zu interagieren.
class CalendarSyncService extends ChangeNotifier {
  /// Takvim sağlayıcısı; ileride Outlook, Apple gibi sağlayıcılar için de ortak interface tanımlanabilir.
  final GoogleCalendarService calendarProvider;
  final AppointmentRepository appointmentRepository;
  final CategoryRepository categoryRepository;
  final RecurrenceService recurrenceService;
  final PrayerTimeService prayerTimeService;
  final GoogleCalendarSyncService? googleCalendarSyncService;

  // Callback-Funktion für Kategorieänderungen
  final Function? onCategoriesChanged;

  CalendarSyncService({
    required this.calendarProvider,
    required this.appointmentRepository,
    required this.categoryRepository,
    required this.recurrenceService,
    required this.prayerTimeService,
    this.googleCalendarSyncService,
    this.onCategoriesChanged,
  });

  /// Benachrichtigt Listener über Änderungen an Kategorien
  void notifyCategoryChanges() {
    if (onCategoriesChanged != null) {
      onCategoriesChanged!();
    }
    notifyListeners(); // Benachrichtigt alle Provider-Listener
  }

  /// Holt die Liste aller verfügbaren Kalender
  Future<List<SelectedCalendar>> getAvailableCalendars() async {
    await calendarProvider.autoSignIn();
    final calendarList = await calendarProvider.fetchCalendarList();

    // Lade gespeicherte Kalender-Auswahl
    final prefs = await SharedPreferences.getInstance();
    final selectedCalendarIds =
        prefs.getStringList('selectedCalendarIds') ?? ['primary'];

    return calendarList.map((calendar) {
      return SelectedCalendar(
        id: calendar.id ?? 'primary',
        title: calendar.summary ?? 'Kalender',
        isSelected: selectedCalendarIds.contains(calendar.id),
      );
    }).toList();
  }

  /// Speichert die ausgewählten Kalender
  Future<void> saveSelectedCalendars(List<SelectedCalendar> calendars) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIds = calendars
        .where((calendar) => calendar.isSelected)
        .map((calendar) => calendar.id)
        .toList();

    await prefs.setStringList('selectedCalendarIds', selectedIds);
  }

  /// Gemeinsame Import-Funktion: Ruft Events vom Anbieter (z.B. Google) ab und fügt sie in die lokale Datenbank ein.
  Future<void> importAppointments({int categoryOption = 0}) async {
    // Debug-Ausgabe für den Beginn des Imports
    debugPrint(
        "🔄 Importiere Termine aus Google Calendar (Kategorie-Option: $categoryOption)");

    await calendarProvider.autoSignIn();

    // Lade ausgewählte Kalender
    final prefs = await SharedPreferences.getInstance();
    final selectedCalendarIds =
        prefs.getStringList('selectedCalendarIds') ?? ['primary'];

    // Lade Kalender-Informationen für Kategorie-Mapping
    final calendarList = await calendarProvider.fetchCalendarList();
    final calendarNamesById = {
      for (var calendar in calendarList)
        calendar.id ?? 'primary': calendar.summary ?? 'Kalender'
    };

    // Log für Debugging
    debugPrint("📅 Verfügbare Kalender für Mapping:");
    calendarNamesById.forEach((id, name) {
      debugPrint("   - $id: $name");
    });

    List<Event> allEvents = [];

    // Events aus allen ausgewählten Kalendern abrufen
    for (String calendarId in selectedCalendarIds) {
      debugPrint(
          "📅 Lade Termine aus Kalender: $calendarId (${calendarNamesById[calendarId] ?? 'Unbekannt'})");
      final events =
          await calendarProvider.fetchCalendarEvents(calendarId: calendarId);

      // Jedem Event den Kalender-ID als Property hinzufügen
      for (var event in events) {
        // Speichere den tatsächlichen Kalender-ID als zusätzliche Information zum Event
        // Wir verwenden source.title für die Kalenderzuordnung
        event.source = EventSource(title: calendarId);
      }

      allEvents.addAll(events);
      debugPrint(
          "📊 ${events.length} Termine aus Kalender $calendarId abgerufen");
    }

    // Debug: Anzahl der abgerufenen Events
    debugPrint(
        "📊 Insgesamt ${allEvents.length} Termine aus Google Calendar abgerufen");

    // Zähler für die Erfolgsstatistik
    int importCount = 0;
    int updateCount = 0;
    int skippedCount = 0;
    int newCategoryCount = 0;

    // Kategorie-Option 0: Standard-Kategorie (1)
    // Kategorie-Option 1: Google-Farben als Kategorien
    // Kategorie-Option 2: Automatisches Mapping nach Kalendername (neu)

    // Lade verfügbare Kategorien für jede Option
    List<CategoryModel> categories = [];
    categories = await categoryRepository.getAllCategories();
    debugPrint("📂 ${categories.length} Kategorien in der App geladen");

    // Standard-Import-Kategorie (für Option 0)
    const int defaultCategoryId = 1;

    // Set zur Verfolgung eindeutiger Event-IDs um Duplikate zu vermeiden
    final Set<String> processedEventIds = {};

    for (var event in allEvents) {
      // Debug: Event-Details
      debugPrint("📅 Verarbeite Event: ${event.summary} (ID: ${event.id})");

      // Prüfe, ob dieses Event bereits verarbeitet wurde
      if (event.id != null && processedEventIds.contains(event.id)) {
        debugPrint(
            "🔄 Event überschlagen: Bereits verarbeitet (ID: ${event.id})");
        skippedCount++;
        continue;
      }

      // Leere Events überspringen
      if (event.summary == null || event.summary!.trim().isEmpty) {
        debugPrint("🚫 Event übersprungen: Leerer Titel");
        skippedCount++;
        continue;
      }

      // Fehlende Start- oder Endzeit
      if (event.start?.dateTime == null && event.start?.date == null) {
        debugPrint("🚫 Event übersprungen: Keine Startzeit");
        skippedCount++;
        continue;
      }

      if (event.end?.dateTime == null && event.end?.date == null) {
        debugPrint("🚫 Event übersprungen: Keine Endzeit");
        skippedCount++;
        continue;
      }

      // Wenn Event gültig ist, zur Liste der verarbeiteten IDs hinzufügen
      if (event.id != null) {
        processedEventIds.add(event.id!);
      }

      // Filtern wir automatisch generierte Events wie Geburtstage.
      if ((event.organizer != null &&
              event.organizer!.email!
                  .toLowerCase()
                  .contains('group.v.calendar.google.com')) ||
          (event.summary != null &&
              (event.summary!.toLowerCase().contains('birthday') ||
                  event.summary!.toLowerCase().contains('doğum günü')))) {
        debugPrint(
            "🚫 Event übersprungen: Automatisch erstelltes Event (z.B. Geburtstag)");
        skippedCount++;
        continue;
      }

      // Überprüfen wir die zugehörige extended property.
      String? muslimCalendarId =
          event.extendedProperties?.private?['muslimcalendarID'];
      AppointmentModel? existingAppointment;

      if (muslimCalendarId == null) {
        // Normaler Termin: Abgleich über externalIdGoogle.
        existingAppointment = await appointmentRepository
            .getAppointmentByExternalIdGoogle(event.id!);
      } else {
        // Gebetszeiten-bezogener Termin: Verwende die ID aus den erweiterten Eigenschaften.
        int? masterId = int.tryParse(muslimCalendarId);
        if (masterId != null) {
          existingAppointment =
              await appointmentRepository.getAppointment(masterId);
        }
      }

      if (event.recurrence != null) {
        if (event.recurrence!.first == 'RRULE:FREQ=WEEKLY;WKST=TU') {
          event.recurrence?.first = recurrenceService.modifyRecurrenceRule(
              event.recurrence!.first.toString(), event.start!.dateTime!);
        } else {
          event.recurrence!.first =
              RecurrenceRuleConverter.convertGoogleToICalendar(
                  event.recurrence!.first.toString());
        }
      }

      // Kategorie-ID je nach gewählter Option ermitteln
      int appointmentCategoryId = defaultCategoryId;

      if (categoryOption == 1) {
        // Option 1: Google Calendar Farben als Kategorien verwenden
        if (event.colorId != null) {
          final colorIndex = int.tryParse(event.colorId!);
          if (colorIndex != null &&
              colorIndex > 0 &&
              colorIndex <= categories.length) {
            appointmentCategoryId = colorIndex;
            debugPrint("🎨 Verwende Google-Farbe als Kategorie: $colorIndex");
          }
        }
      } else if (categoryOption == 2) {
        // Option 2: Verwende den Kalendernamen als Kategorie
        // Source-Kalender-ID des Events ermitteln
        String calendarId = event.source?.title ?? 'primary';
        String calendarName = calendarNamesById[calendarId] ?? 'Unbekannt';

        debugPrint("🔍 Event stammt aus Kalender: $calendarId ($calendarName)");

        try {
          // Suche nach einer Kategorie mit dem Kalendernamen
          CategoryModel? matchingCategory;
          for (var category in categories) {
            if (category.name.toLowerCase() == calendarName.toLowerCase()) {
              matchingCategory = category;
              debugPrint(
                  "✓ Kategorie mit Name '${category.name}' gefunden - ID: ${category.id}");
              break;
            }
          }

          if (matchingCategory != null) {
            // Verwende existierende Kategorie
            appointmentCategoryId = matchingCategory.id ?? defaultCategoryId;
            debugPrint(
                "✅ Existierende Kategorie gefunden: ${matchingCategory.name} (ID: ${matchingCategory.id})");
          } else {
            // Erstelle neue Kategorie mit dem Kalendernamen
            Color? calendarColor;

            // Wenn das Event eine Farbe hat, verwende diese
            if (event.colorId != null) {
              final colorIndex = int.tryParse(event.colorId!);
              if (colorIndex != null) {
                const colors = [
                  Color(0xFF5484ED), // Blau
                  Color(0xFFA4BDFC), // Hellblau
                  Color(0xFF7AE7BF), // Türkis
                  Color(0xFF51B749), // Grün
                  Color(0xFFFBD75B), // Gelb
                  Color(0xFFFFB878), // Orange
                  Color(0xFFFF887C), // Rot
                  Color(0xFFDC2127), // Dunkelrot
                  Color(0xFFDBDBDB), // Grau
                  Color(0xFFE1E1E1), // Hellgrau
                ];

                final index = colorIndex % colors.length;
                calendarColor = colors[index];
              }
            }

            //debugPrint("🆕 Erstelle neue Kategorie mit Namen: '$calendarName'");
            final category = await categoryRepository.getCategoryByNameOrCreate(
              calendarName,
              color: calendarColor,
            );

            // Überprüfen, ob die Kategorie korrekt erstellt wurde
            if (category.id != null && category.id! > 0) {
              appointmentCategoryId = category.id!;
              // debugPrint(
              //     "✅ Neue Kategorie erstellt: ${category.name} (ID: ${category.id})");
            } else {
              // Fallback auf Standard-Kategorie, falls die ID ungültig ist
              appointmentCategoryId = defaultCategoryId;
              debugPrint(
                  "⚠️ Fehler bei Kategorieerstellung, verwende Standard-Kategorie");
            }

            newCategoryCount++;

            // Aktualisiere die lokale Kategorie-Liste
            categories = await categoryRepository.getAllCategories();
            // debugPrint(
            //     "📂 Kategorieliste aktualisiert: ${categories.length} Kategorien");

            // Benachrichtige über Änderungen an den Kategorien
            notifyCategoryChanges();
          }
        } catch (e) {
          // debugPrint("⚠️ Fehler beim Erstellen der Kategorie: $e");
          // Fallback auf Standard-Kategorie
          appointmentCategoryId = defaultCategoryId;
        }
      }

      // VERBESSERTE Zeithandhabung: Korrekte Konvertierung zwischen Zeitzonen
      DateTime? finalStartTime;
      DateTime? finalEndTime;

      if (event.start?.dateTime != null) {
        // Für Termine mit Zeitangabe: Zeitzone korrekt übernehmen
        // Wir nehmen die UTC-Zeit und konvertieren sie in lokale Zeit
        finalStartTime = event.start!.dateTime!.toLocal();
        debugPrint(
            'Google Import - Original Startzeit (UTC): ${event.start!.dateTime}');
        debugPrint('Google Import - Konvertierte lokale Zeit: $finalStartTime');
      } else {
        // Für ganztägige Termine: Keine Zeitanpassung notwendig
        finalStartTime = event.start?.date != null ? event.start!.date! : null;
      }

      if (event.end?.dateTime != null) {
        // Für Termine mit Zeitangabe: Zeitzone korrekt übernehmen
        finalEndTime = event.end!.dateTime!.toLocal();
      } else {
        // Für ganztägige Termine: Keine Zeitanpassung oder +1 Minute für die App
        finalEndTime = event.end?.date != null
            ? event.start!.date!.add(const Duration(minutes: 1))
            : null;
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
        recurrenceRule:
            event.recurrence != null ? event.recurrence!.join(',') : null,
        recurrenceExceptionDates: null,
        color: const Color(0xFF2196F3),
        startTime: finalStartTime,
        endTime: finalEndTime,
        categoryId: appointmentCategoryId,
        reminderMinutesBefore: null,
        lastSyncedAt: DateTime.now(),
      );

      if (muslimCalendarId == null) {
        appointment = appointment.copyWith(externalIdGoogle: event.id);
      }

      // Überprüfe, ob die Kategorie-ID korrekt gesetzt wurde
      if (appointment.categoryId != appointmentCategoryId) {
        debugPrint(
            "⚠️ WARNUNG: Kategorie-ID ($appointmentCategoryId) wurde nicht korrekt im Appointment-Modell gesetzt (${appointment.categoryId})");
        // Korrigiere die Kategorie-ID explizit
        appointment = appointment.copyWith(categoryId: appointmentCategoryId);
      }

      // Debug-Info: Zeige die genauen Daten des zu speichernden Termins
      debugPrint("📝 Termin-Details vor Speicherung:");
      debugPrint("   - Titel: ${appointment.subject}");
      debugPrint("   - Kategorie-ID: ${appointment.categoryId}");
      debugPrint("   - Start: ${appointment.startTime}");
      debugPrint("   - Ende: ${appointment.endTime}");

      if (existingAppointment == null) {
        debugPrint(
            "➕ Neuer Termin hinzugefügt: ${appointment.subject} (Kategorie: ${appointment.categoryId})");
        await appointmentRepository.insertAppointment(appointment);
        importCount++;
      } else {
        debugPrint(
            "🔄 Termin aktualisiert: ${appointment.subject} (Kategorie: ${appointment.categoryId})");
        await appointmentRepository.updateAppointment(appointment);
        updateCount++;
      }
    }

    // Alte Termine löschen, die nicht mehr existieren
    // Diese Funktion überprüft, welche Termine in der lokalen Datenbank vorhanden sind,
    // aber nicht mehr im Google Kalender existieren, und löscht diese.
    List<AppointmentModel> existingAppointments =
        await appointmentRepository.getAllAppointments();
    int deleteCount = 0;

    // Durchlaufe alle lokalen Termine
    for (var existingAppointment in existingAppointments) {
      bool foundMatchingEvent = false;
      // Überprüfe nur Termine, die eine Google-ID haben (also aus Google importiert wurden)
      if (existingAppointment.externalIdGoogle != null) {
        // Suche in allen abgerufenen Google-Events nach einem passenden Event
        for (var event in allEvents) {
          // Wenn die Google-ID übereinstimmt, existiert der Termin noch in Google
          if (event.id == existingAppointment.externalIdGoogle.toString()) {
            foundMatchingEvent = true;
            break;
          }
        }
        // Wenn kein passendes Event gefunden wurde, wurde der Termin in Google gelöscht
        // und sollte daher auch lokal gelöscht werden
        if (!foundMatchingEvent) {
          debugPrint(
              "🗑️ Termin gelöscht: ${existingAppointment.subject} (ID: ${existingAppointment.id})");
          await appointmentRepository
              .deleteAppointment(existingAppointment.id!);
          deleteCount++;
        }
      }
    }

    debugPrint(
        "✅ Import abgeschlossen: $importCount neue Termine, $updateCount aktualisiert, $deleteCount gelöscht, $skippedCount übersprungen, $newCategoryCount neue Kategorien erstellt");
  }

  /// Gemeinsame Export-Funktion: Überträgt Termine aus der lokalen Datenbank zum Provider (Google).
  Future<void> exportAppointments() async {
    // debugPrint("🔄 Exportiere Termine zu Google Calendar");
    await calendarProvider.autoSignIn();

    // Lade ausgewählten Hauptkalender für den Export (standardmäßig 'primary')
    final prefs = await SharedPreferences.getInstance();
    final selectedCalendarIds =
        prefs.getStringList('selectedCalendarIds') ?? ['primary'];
    final exportCalendarId =
        selectedCalendarIds.isNotEmpty ? selectedCalendarIds.first : 'primary';

    List<AppointmentModel> appointments =
        await appointmentRepository.getAllAppointments();
    // debugPrint("📊 ${appointments.length} Termine zum Export gefunden");
    // debugPrint("📅 Export in Kalender: $exportCalendarId");

    for (var appointment in appointments) {
      if (appointment.isRelatedToPrayerTimes) {
        //TODO Aziz
        // Für prayer-related Termine: Berechnung der wiederkehrenden Tage mit RecurrenceService.
        DateTime startRange = DateTime.now();
        DateTime endRange =
            startRange.add(const Duration(days: 90)); // Erweitert auf 90 Tage
        List<DateTime> recurrenceDates = recurrenceService.getRecurrenceDates(
            appointment, startRange, endRange);

        // debugPrint(
        //     "🕌 Prayer-related Termin: ${appointment.subject} mit ${recurrenceDates.length} Terminen");

        for (var date in recurrenceDates) {
          DateTime? calculatedStart =
              await prayerTimeService.getCalculatedStartTime(appointment, date);
          DateTime? calculatedEnd =
              await prayerTimeService.getCalculatedEndTime(appointment, date);
          if (calculatedStart == null || calculatedEnd == null) {
            debugPrint(
                "⚠️ Konnte Start/End-Zeit nicht berechnen für Datum: $date");
            continue;
          }

          // Wichtig: Erstelle für jeden Termin eine KOPIE ohne Wiederholungsregel
          // und mit eindeutiger ID basierend auf dem Original-Termin und dem Datum
          final formattedDate =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final uniqueId = "prayer_${appointment.id}_$formattedDate";

          debugPrint(
              "📅 Exportiere Einzeltermin für Datum $formattedDate: ${calculatedStart.toIso8601String()}");

          await calendarProvider.syncAppointmentEvent(
            appointment: appointment.copyWith(
              // Keine Wiederholungsregel für die einzelnen Instanzen
              recurrenceRule: null,
              // Zusätzliche Informationen über den Ursprungstermin in die Notiz
              notes: appointment.notes != null
                  ? "${appointment.notes}\n\n(Wiederkehrender Termin vom ${appointment.startTime?.toIso8601String().split('T')[0]})"
                  : "(Wiederkehrender Termin vom ${appointment.startTime?.toIso8601String().split('T')[0]})",
            ),
            startTime: calculatedStart,
            endTime: calculatedEnd,
            prayerRelated: true,
            calendarId: exportCalendarId,
          );
        }

        // Events, die außerhalb der gültigen Wiederholungstermine liegen, werden gelöscht.
        await calendarProvider.deleteEventsNotInDates(
          appointmentId: appointment.id!,
          validDates: recurrenceDates,
          calendarId: exportCalendarId,
        );
      } else {
        // Für normale Termine ohne Gebetszeitenbezug
        if (appointment.startTime == null || appointment.endTime == null) {
          debugPrint(
              "⚠️ Termin ohne Start/End-Zeit übersprungen: ${appointment.subject}");
          continue;
        }

        debugPrint(
            "📆 Exportiere Termin: ${appointment.subject} (${appointment.startTime} - ${appointment.endTime})");
        Event event = await calendarProvider.syncAppointmentEvent(
          appointment: appointment,
          startTime: appointment.startTime!,
          endTime: appointment.endTime!,
          prayerRelated: false,
          calendarId: exportCalendarId,
        );

        if (appointment.externalIdGoogle == null) {
          debugPrint("🆕 Neuer Termin in Google erstellt: ${event.id}");
          // Hier muss ein copyWith verwendet werden, da wir nur ein Feld ändern wollen
          AppointmentModel updatedAppointment =
              appointment.copyWith(externalIdGoogle: event.id);
          await appointmentRepository.updateAppointment(updatedAppointment);
        }
      }
    }

    debugPrint("✅ Export abgeschlossen");
  }

  /// Korrigiert ungültige Wiederholungsregeln in der Datenbank
  Future<void> fixInvalidRecurrenceRules() async {
    //debugPrint("🔍 Prüfe auf ungültige Wiederholungsregeln in der Datenbank");

    // Alle Termine aus der Datenbank laden
    List<AppointmentModel> appointments =
        await appointmentRepository.getAllAppointments();

    for (var appointment in appointments) {
      if (appointment.recurrenceRule != null) {
        // Verwende den verbesserten RecurrenceService zur Korrektur
        String correctedRule = recurrenceService.fixRecurrenceRule(
            appointment.recurrenceRule, appointment.startTime);

        // Wenn die Regel geändert wurde, aktualisiere den Termin
        if (correctedRule != appointment.recurrenceRule) {
          // Termin aktualisieren
          AppointmentModel updatedAppointment =
              appointment.copyWith(recurrenceRule: correctedRule);

          await appointmentRepository.updateAppointment(updatedAppointment);

          debugPrint(
              "🛠️ Wiederholungsregel korrigiert für Termin ${appointment.id} (${appointment.subject}): $correctedRule");
        }
      }
    }

    //debugPrint("✅ Wiederholungsregel-Prüfung abgeschlossen: $fixedCount Termine korrigiert");
  }

  /// Führt sofort einen vollständigen Synchronisierungsprozess durch
  /// (Import und Export nacheinander)
  Future<void> syncGoogleCalendarNow({int categoryOption = 0}) async {
    debugPrint("Starte vollständige Synchronisierung mit Google Calendar");

    // Zuerst fehlerhafte Wiederholungsregeln korrigieren
    await fixInvalidRecurrenceRules();

    try {
      // Aktiviere das Sync-Flag für alle Termine automatisch
      final updatedCount =
          await appointmentRepository.enableSyncForAllAppointments();
      debugPrint("Sync-Flag für $updatedCount Termine aktiviert");

      // 1. Import durchführen
      debugPrint("Starte Import von Google Calendar Terminen...");
      await importAppointments(categoryOption: categoryOption);
      debugPrint("Import von Google Calendar abgeschlossen");

      // 2. Export durchführen
      debugPrint("Starte Export zu Google Calendar...");
      bool exportSuccess = false;

      // Wenn der optimierte GoogleCalendarSyncService verfügbar ist, verwende diesen für den Export
      if (googleCalendarSyncService != null) {
        exportSuccess = await efficientSyncWithGoogle();
        if (!exportSuccess) {
          // Fallback auf Standard-Export-Methode
          debugPrint(
              "Optimierter Export fehlgeschlagen, verwende Standard-Export");
          await exportAppointments();
        }
      } else {
        // Standard-Export-Methode verwenden
        await exportAppointments();
      }

      debugPrint("Export zu Google Calendar abgeschlossen");
    } catch (e) {
      debugPrint("Fehler bei der Synchronisierung: $e");
    }

    debugPrint(
        "Vollständige Synchronisierung mit Google Calendar abgeschlossen");
  }

  /// Führt nur einen Import von Google Calendar durch
  Future<void> importFromGoogleCalendarOnly({int categoryOption = 0}) async {
    debugPrint("Starte Import von Google Calendar");

    try {
      // Importiere Termine von Google
      await importAppointments(categoryOption: categoryOption);
      debugPrint("Import von Google Calendar abgeschlossen");
    } catch (e) {
      debugPrint("Fehler beim Import: $e");
    }
  }

  /// Führt nur einen Export zu Google Calendar durch
  Future<void> exportToGoogleCalendarOnly() async {
    debugPrint("Starte Export zu Google Calendar");

    // Zuerst fehlerhafte Wiederholungsregeln korrigieren
    await fixInvalidRecurrenceRules();

    try {
      // Aktiviere das Sync-Flag für alle Termine automatisch
      final updatedCount =
          await appointmentRepository.enableSyncForAllAppointments();
      debugPrint("Sync-Flag für $updatedCount Termine aktiviert");

      // Export durchführen
      bool exportSuccess = false;

      // Wenn der optimierte GoogleCalendarSyncService verfügbar ist, verwende diesen für den Export
      if (googleCalendarSyncService != null) {
        exportSuccess = await efficientSyncWithGoogle();
        if (!exportSuccess) {
          // Fallback auf Standard-Export-Methode
          debugPrint(
              "Optimierter Export fehlgeschlagen, verwende Standard-Export");
          await exportAppointments();
        }
      } else {
        // Standard-Export-Methode verwenden
        await exportAppointments();
      }

      debugPrint("Export zu Google Calendar abgeschlossen");
    } catch (e) {
      debugPrint("Fehler beim Export: $e");
    }
  }

  /// Verwendet den optimierten GoogleCalendarSyncService für effizientere Synchronisierung
  ///
  /// Diese Methode nutzt Batch-Operationen und intelligente Mappings, um die Synchronisierung
  /// erheblich zu beschleunigen und die API-Aufrufe zu reduzieren.
  /// Hinweis: Diese Methode führt NUR den Export durch. Der Import muss separat aufgerufen werden.
  Future<bool> efficientSyncWithGoogle() async {
    if (googleCalendarSyncService == null) {
      debugPrint("GoogleCalendarSyncService nicht verfügbar");
      return false;
    }

    try {
      // Wir können nicht direkt auf _initializeApiClient zugreifen,
      // aber syncAllAppointments versucht dies intern
      final result = await googleCalendarSyncService!.syncAllAppointments();

      if (result) {
        debugPrint("Synchronisierung erfolgreich abgeschlossen");
      } else {
        debugPrint("Synchronisierung fehlgeschlagen");
      }

      return result;
    } catch (e) {
      debugPrint("Fehler bei der Synchronisierung: $e");
      return false;
    }
  }

  /// Löscht alle lokalen Termine und führt einen vollständigen Neuimport durch
  Future<void> clearAppointmentsAndReimport() async {
    //debugPrint("🧹 Lösche alle lokalen Termine für Neuimport");

    // Alle lokalen Termine aus der Datenbank laden
    List<AppointmentModel> allAppointments =
        await appointmentRepository.getAllAppointments();

    // Termine löschen
    for (var appointment in allAppointments) {
      if (appointment.id != null) {
        await appointmentRepository.deleteAppointment(appointment.id!);
      }
    }

    //debugPrint("🗑️ $deleteCount Termine gelöscht");

    // Neu synchronisieren
    await importAppointments();
    //debugPrint("✅ Neuimport abgeschlossen");
  }
}

// Erweiterung für AppointmentModel - copyWith Methode hinzufügen
extension AppointmentModelExtension on AppointmentModel {
  AppointmentModel copyWith({
    int? id,
    String? subject,
    String? notes,
    bool? isAllDay,
    bool? isRelatedToPrayerTimes,
    PrayerTime? prayerTime,
    TimeRelation? timeRelation,
    int? minutesBeforeAfter,
    Duration? duration,
    String? location,
    String? recurrenceRule,
    List<DateTime>? recurrenceExceptionDates,
    Color? color,
    DateTime? startTime,
    DateTime? endTime,
    int? categoryId,
    int? reminderMinutesBefore,
    String? externalIdGoogle,
    String? externalIdOutlook,
    String? externalIdApple,
    DateTime? lastSyncedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      notes: notes ?? this.notes,
      isAllDay: isAllDay ?? this.isAllDay,
      isRelatedToPrayerTimes:
          isRelatedToPrayerTimes ?? this.isRelatedToPrayerTimes,
      prayerTime: prayerTime ?? this.prayerTime,
      timeRelation: timeRelation ?? this.timeRelation,
      minutesBeforeAfter: minutesBeforeAfter ?? this.minutesBeforeAfter,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceExceptionDates:
          recurrenceExceptionDates ?? this.recurrenceExceptionDates,
      color: color ?? this.color,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      externalIdGoogle: externalIdGoogle ?? this.externalIdGoogle,
      externalIdOutlook: externalIdOutlook ?? this.externalIdOutlook,
      externalIdApple: externalIdApple ?? this.externalIdApple,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
