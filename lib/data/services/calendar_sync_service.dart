// lib/data/services/calendar_sync_service.dart
import 'package:flutter/cupertino.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:intl/intl.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/data/services/google_calendar_service.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';

class CalendarSyncService {
  /// Takvim sağlayıcısı; ileride Outlook, Apple gibi sağlayıcılar için de ortak interface tanımlanabilir.
  final GoogleCalendarService calendarProvider;
  final AppointmentRepository appointmentRepository;
  final CategoryRepository categoryRepository;
  final RecurrenceService recurrenceService;
  final PrayerTimeService prayerTimeService;

  CalendarSyncService({
    required this.calendarProvider,
    required this.appointmentRepository,
    required this.categoryRepository,
    required this.recurrenceService,
    required this.prayerTimeService,
  });

  /// Ortak import fonksiyonu: Sağlayıcı (örneğin Google) üzerinden event'leri çekip yerel veritabanına ekler.
  Future<void> importAppointments({int categoryOption = 0}) async {
    // Debug-Ausgabe für den Beginn des Imports
    debugPrint(
        "🔄 Importiere Termine aus Google Calendar (Kategorie-Option: $categoryOption)");

    await calendarProvider.autoSignIn();
    List<Event> events = await calendarProvider.fetchCalendarEvents();

    // Debug: Anzahl der abgerufenen Events
    debugPrint("📊 ${events.length} Termine aus Google Calendar abgerufen");

    // Zähler für die Erfolgsstatistik
    int importCount = 0;
    int updateCount = 0;

    // Kategorie-Option 0: Standard-Kategorie (1)
    // Kategorie-Option 1: Google-Farben als Kategorien
    // Kategorie-Option 2: Automatisches Matching nach Namen

    // Lade verfügbare Kategorien für Option 1 und 2
    List<CategoryModel> categories = [];
    if (categoryOption > 0) {
      categories = await appointmentRepository.getAllCategories();
      debugPrint("📂 ${categories.length} Kategorien geladen");
    }

    // Standard-Import-Kategorie (für Option 0)
    const int defaultCategoryId = 1;

    for (var event in events) {
      // Debug: Event-Details
      debugPrint("📅 Verarbeite Event: ${event.summary} (ID: ${event.id})");

      // Doğum günü gibi otomatik oluşturulan eventleri filtreleyelim.
      // Örneğin, bazı hesaplarda doğum günü event'leri organizer email'i "addressbook#contacts@group.v.calendar.google.com" olarak gelebilir.
      // Ayrıca, summary içerisinde "birthday" veya "doğum günü" gibi ifadeler varsa, onları da atlayabiliriz.
      if ((event.organizer != null &&
              event.organizer!.email!
                  .toLowerCase()
                  .contains('group.v.calendar.google.com')) ||
          (event.summary != null &&
              (event.summary!.toLowerCase().contains('birthday') ||
                  event.summary!.toLowerCase().contains('doğum günü')))) {
        // Bu event doğum günü gibi otomatik oluşturulan bir eventse, atla.
        debugPrint(
            "🚫 Event übersprungen: Automatisch erstelltes Event (z.B. Geburtstag)");
        continue;
      }

      // İlgili extended property var mı kontrol edelim.
      String? muslimCalendarId =
          event.extendedProperties?.private?['muslimcalendarID'];
      AppointmentModel? existingAppointment;
      if (muslimCalendarId == null) {
        // Normal appointment: externalIdGoogle üzerinden eşleştir.
        existingAppointment = await appointmentRepository
            .getAppointmentByExternalIdGoogle(event.id!);
      } else {
        // Namaz vakitlerine bağlı appointment: extended property içerisindeki id'yi kullan.
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
              convertGoogleToICalendarRRule(event.recurrence!.first.toString());
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
        // Option 2: Erstelle oder finde Kategorien basierend auf dem Titel des Termins
        final eventTitle = event.summary ?? '';

        if (eventTitle.isNotEmpty) {
          // Einfache Version: Verwende den kompletten Titel als Kategorienamen
          // oder alternativ den ersten Teil des Titels bis zum Doppelpunkt als Kategorie
          String categoryName = eventTitle;

          // Wenn der Titel einen Doppelpunkt enthält, nimm den ersten Teil als Kategorie
          if (eventTitle.contains(':')) {
            categoryName = eventTitle.split(':').first.trim();
          }

          // Länge der Kategorie begrenzen
          if (categoryName.length > 30) {
            categoryName = categoryName.substring(0, 30);
          }

          // Wenn Google eine Farbe für den Termin definiert hat, nutze diese
          Color? eventColor;
          if (event.colorId != null) {
            final colorIndex = int.tryParse(event.colorId!);
            if (colorIndex != null) {
              // Hier könnten wir ein Mapping der Google Calendar Farben haben
              // Einfache Version: Erzeuge eine Farbe basierend auf der colorId
              final colors = [
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
              eventColor = colors[index];
            }
          }

          // Finde oder erstelle die Kategorie und nutze ihre ID
          try {
            final category = await categoryRepository.getCategoryByNameOrCreate(
              categoryName,
              color: eventColor,
            );
            appointmentCategoryId = category.id;
            debugPrint(
                "✅ Neue oder bestehende Kategorie verwendet: ${category.name} (ID: ${category.id})");
          } catch (e) {
            debugPrint("⚠️ Fehler beim Erstellen der Kategorie: $e");
            // Fallback auf Standard-Kategorie
            appointmentCategoryId = defaultCategoryId;
          }
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
        recurrenceRule:
            event.recurrence != null ? event.recurrence!.join(',') : null,
        recurrenceExceptionDates: null,
        color: const Color(0xFF2196F3),
        startTime: event.start?.dateTime != null
            ? event.start!.dateTime!.toLocal()
            : (event.start?.date != null ? event.start!.date! : null),
        endTime: event.end?.dateTime != null
            ? event.end!.dateTime!.toLocal()
            : (event.end?.date != null
                ? event.start!.date!.add(const Duration(minutes: 1))
                : null),
        categoryId: appointmentCategoryId,
        reminderMinutesBefore: null,
        lastSyncedAt: DateTime.now(),
      );

      if (muslimCalendarId == null) {
        appointment = appointment.copyWith(externalIdGoogle: event.id);
      }

      if (existingAppointment == null) {
        debugPrint(
            "➕ Neuer Termin hinzugefügt: ${appointment.subject} (Kategorie: $appointmentCategoryId)");
        await appointmentRepository.insertAppointment(appointment);
        importCount++;
      } else {
        debugPrint(
            "🔄 Termin aktualisiert: ${appointment.subject} (Kategorie: $appointmentCategoryId)");
        await appointmentRepository.updateAppointment(appointment);
        updateCount++;
      }
    }

    // Alte Termine löschen, die nicht mehr existieren
    List<AppointmentModel> existingAppointments =
        await appointmentRepository.getAllAppointments();
    int deleteCount = 0;

    for (var existingAppointment in existingAppointments) {
      bool foundMatchingEvent = false;
      if (existingAppointment.externalIdGoogle != null) {
        for (var event in events) {
          if (event.id == existingAppointment.externalIdGoogle.toString()) {
            foundMatchingEvent = true;
            break;
          }
        }
        if (!foundMatchingEvent) {
          // Eğer eşleşen ein event yoksa, diesen appointment'ı sil.
          debugPrint(
              "🗑️ Termin gelöscht: ${existingAppointment.subject} (ID: ${existingAppointment.id})");
          await appointmentRepository
              .deleteAppointment(existingAppointment.id!);
          deleteCount++;
        }
      }
    }

    // Debug-Ausgabe für die Importstatistik
    debugPrint(
        "✅ Import abgeschlossen: $importCount neue Termine, $updateCount aktualisiert, $deleteCount gelöscht");

    // Liste aller Termine in der Datenbank ausgeben
    List<AppointmentModel> allAppointments =
        await appointmentRepository.getAllAppointments();
    debugPrint(
        "📋 Aktuelle Termine in der Datenbank: ${allAppointments.length}");
    for (var app in allAppointments) {
      debugPrint(
          "  - ${app.subject} (ID: ${app.id}, Kategorie: ${app.categoryId}, Start: ${app.startTime})");
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

  /// Ortak export fonksiyonu: Yerel veritabanındaki appointment'ları sağlayıcıya (Google) aktarır.
  Future<void> exportAppointments() async {
    debugPrint("🔄 Exportiere Termine zu Google Calendar");
    await calendarProvider.autoSignIn();
    List<AppointmentModel> appointments =
        await appointmentRepository.getAllAppointments();
    debugPrint("📊 ${appointments.length} Termine zum Export gefunden");

    int exportCount = 0;
    int updateCount = 0;

    for (var appointment in appointments) {
      if (appointment.isRelatedToPrayerTimes) {
        // Prayer-related appointment'lar için: RecurrenceService ile tekrarlanan tarihler hesaplanır.
        DateTime startRange = DateTime.now();
        DateTime endRange = startRange.add(Duration(days: 30));
        List<DateTime> recurrenceDates = recurrenceService.getRecurrenceDates(
            appointment, startRange, endRange);

        debugPrint(
            "🕌 Prayer-related Termin: ${appointment.subject} mit ${recurrenceDates.length} Terminen");
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

          await calendarProvider.syncAppointmentEvent(
            appointment: appointment,
            startTime: calculatedStart,
            endTime: calculatedEnd,
            prayerRelated: true,
          );
          exportCount++;
        }
        // Silinmesi gereken event'ler, geçerli tekrarlanan tarihler dışında kalmış ise silinir.
        await calendarProvider.deleteEventsNotInDates(
          appointmentId: appointment.id!,
          validDates: recurrenceDates,
        );
      } else {
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
        );

        if (appointment.externalIdGoogle == null) {
          debugPrint("🆕 Neuer Termin in Google erstellt: ${event.id}");
          // Hier muss ein copyWith verwendet werden, da wir nur ein Feld ändern wollen
          AppointmentModel updatedAppointment =
              appointment.copyWith(externalIdGoogle: event.id);
          await appointmentRepository.updateAppointment(updatedAppointment);
          exportCount++;
        } else {
          debugPrint("🔄 Termin in Google aktualisiert: ${event.id}");
          updateCount++;
        }
      }
    }

    debugPrint(
        "✅ Export abgeschlossen: $exportCount neue Termine exportiert, $updateCount aktualisiert");
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
