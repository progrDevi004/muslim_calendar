// lib/ui/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_dialog.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_list_tile.dart';
import 'package:Taqvimi/ui/components/app_drawer.dart';

// Repositories & Services
import 'package:Taqvimi/data/repositories/appointment_repository.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/data/repositories/prayer_time_repository.dart';
import 'package:Taqvimi/data/services/prayer_time_service.dart';
import 'package:Taqvimi/data/services/recurrence_service.dart';
import 'package:Taqvimi/data/services/calendar_sync_service.dart';
import 'package:Taqvimi/data/services/import_settings_service.dart';

// Models & Widgets
import 'package:Taqvimi/models/appointment_model.dart';
import 'package:Taqvimi/models/category_model.dart';
import 'package:Taqvimi/models/enums.dart';
import 'package:Taqvimi/ui/widgets/prayer_time_appointment_adapter.dart';

// Ausgelagerte Widgets
import 'package:Taqvimi/ui/widgets/home/calendar_view_widget.dart';
import 'package:Taqvimi/ui/widgets/home/category_filter_dialog.dart';
import 'package:Taqvimi/ui/widgets/home/navigation_bar_widget.dart';
import 'package:Taqvimi/ui/widgets/home/home_app_bar_widget.dart';
import 'package:Taqvimi/ui/widgets/home/add_appointment_fab.dart';

// Pages
import 'package:Taqvimi/ui/pages/settings_page.dart';
import 'package:Taqvimi/ui/pages/dashboard_page.dart';
import 'package:Taqvimi/ui/pages/appointment_creation_page.dart';

// Dialogs

// Localization
import 'package:Taqvimi/localization/app_localizations.dart';

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

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

// EventDataSource Klasse, falls nicht in create_events.dart definiert
class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  /// Navigation:
  /// 0 => Dashboard, 1 => Day, 2 => Week, 3 => Month
  int _selectedNavIndex = 0;

  CalendarView _selectedView = CalendarView.month;
  CalendarController _calendarController = CalendarController();
  CalendarDataSource? _dataSource;

  // Kalenderdatum (immer aktuelles Datum als Default)
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _allCategories = [];
  Set<int> _selectedCategoryIds = {};

  // Flag, ob Termine gerade geladen werden
  bool _isLoadingAppointments = false;

  // Repositories und Services
  late PrayerTimeAppointmentAdapter _adapter;
  late AppointmentRepository _appointmentRepo;
  late PrayerTimeRepository _prayerTimeRepo;
  late PrayerTimeService _prayerTimeService;
  late CategoryRepository _categoryRepo;
  late CalendarSyncService _calendarSyncService;

  DashboardPageState? _dashboardPageState;

  bool _use24hFormat = false;

  // Dezenter Farbton für Gebetszeiten (BlueGrey 300)
  static const Color _prayerTimeColor = Color(0xFF90A4AE);

  // Flags aus den Settings (für Daily/Weekly und ggf. Dashboard-Gebetszeiten)
  bool _showPrayerSlotsInDashboard = true;
  bool _showPrayerTimesInDayView = true;
  bool _showPrayerTimesInWeekView = true;
  bool _showPrayerTimesInMonthView = false;

  // Key für Scaffolding (für Drawer-Zugriff)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<TimeRegion> _prayerTimeRegions = <TimeRegion>[];

  @override

  /// Initialisiert Kalender-Controller, Standardansicht, lädt Benutzereinstellungen,
  /// Kategorien, Gebetszeiten und Termine für die App-Startansicht
  void initState() {
    super.initState();
    debugPrint('📅 HomePage initState');

    // Setze Standardansicht auf Tag
    _selectedView = CalendarView.day;
    // Controller mit der ausgewählten Ansicht initialisieren
    _calendarController.view = _selectedView;

    // Datum im Controller setzen
    _calendarController.selectedDate = _selectedDate;
    _calendarController.displayDate = _selectedDate;

    // Lade Benutzerpräferenzen
    _loadUserPrefs();

    // Die ersten Termine direkt laden, weitere Initialisierung in didChangeDependencies
    Future.microtask(() {
      // Sichere Methode, die nur mit lokalen Daten arbeitet
      _loadStaticAppointments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('📅 HomePage didChangeDependencies');

    try {
      // Services und Repositories initialisieren
      _prayerTimeRepo =
          Provider.of<PrayerTimeRepository>(context, listen: false);
      _appointmentRepo =
          Provider.of<AppointmentRepository>(context, listen: false);
      _categoryRepo = Provider.of<CategoryRepository>(context, listen: false);
      _prayerTimeService =
          Provider.of<PrayerTimeService>(context, listen: false);
      _calendarSyncService =
          Provider.of<CalendarSyncService>(context, listen: false);

      // RecurrenceService für den Adapter holen
      final recurrenceService =
          Provider.of<RecurrenceService>(context, listen: false);

      // Adapter für die Terminumwandlung erstellen
      _adapter = PrayerTimeAppointmentAdapter(
        prayerTimeService: _prayerTimeService,
        recurrenceService: recurrenceService,
      );

      // Jetzt können wir sicher die Gebetszeiten laden
      _fetchYearlyPrayerTimesIfNeeded();

      // PrayerTimeService Listener hinzufügen
      _prayerTimeService.addListener(_onPrayerTimesChanged);

      // Listener hinzufügen, um auf Kategorieänderungen zu reagieren
      _calendarSyncService.addListener(_onCategoriesChanged);

      // Komplette Termindaten laden
      loadAllAppointments();
    } catch (e) {
      debugPrint(
          '❌ Fehler bei der Initialisierung in didChangeDependencies: $e');
    }
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);

    // PrayerTimeService Listener entfernen
    _prayerTimeService.removeListener(_onPrayerTimesChanged);

    super.dispose();
  }

  // Wird aufgerufen, wenn sich Gebetszeiten ändern
  void _onPrayerTimesChanged() {
    debugPrint(
        '📅 _onPrayerTimesChanged: Gebetszeiten haben sich geändert, lade Termine neu');
    // Wenn sich die Gebetszeiten ändern (z.B. durch Location-Änderung),
    // sollten wir die Termine neu laden
    if (mounted) {
      loadAllAppointments();
    }
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    if (!mounted) return;

    // Kategorien neu laden
    _loadAllCategories().then((_) {
      if (!mounted) return;

      // Kategorien-Cache leeren, damit die aktualisierten Farben verwendet werden
      _adapter.clearCategoryCache();
      // Termine neu laden mit den aktualisierten Kategorien
      loadAllAppointments();
      // Dashboard aktualisieren
      _dashboardPageState?.reloadData();
    });
  }

  /// Hilfsmethode zum korrekten Addieren/Subtrahieren von Monaten mit Jahresübergang
  DateTime addMonths(DateTime date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year + (newMonth - 1) ~/ 12;
    newMonth = ((newMonth - 1) % 12) + 1;
    return DateTime(newYear, newMonth, date.day);
  }

  /// Lädt Zeitformat- und Gebetszeiteinstellungen aus SharedPreferences
  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final use24h = prefs.getBool('use24hFormat') ?? false;
    final showInDashboard = prefs.getBool('showPrayerSlotsInDashboard') ?? true;
    final showInDayView = prefs.getBool('showPrayerTimesInDayView') ?? true;
    final showInWeekView = prefs.getBool('showPrayerTimesInWeekView') ?? true;

    setState(() {
      _use24hFormat = use24h;
      _showPrayerSlotsInDashboard = showInDashboard;
      _showPrayerTimesInDayView = showInDayView;
      _showPrayerTimesInWeekView = showInWeekView;
      // In der Monatsansicht sollen keine Gebetszeiten angezeigt werden.
      _showPrayerTimesInMonthView = false;
    });
  }

  /// Lädt die Gebetszeiten für ein Jahr, falls sie noch nicht in der Datenbank sind
  Future<void> _fetchYearlyPrayerTimesIfNeeded(
      {bool forceReload = false}) async {
    try {
      debugPrint(
          '📅 Prüfe, ob Gebetszeiten für das ganze Jahr geladen werden müssen');

      if (_prayerTimeRepo == null) {
        debugPrint(
            '❌ _fetchYearlyPrayerTimesIfNeeded: _prayerTimeRepo ist noch nicht initialisiert');
        return;
      }

      // Aktuelle Zeit
      final now = DateTime.now();

      // Wir laden Gebetszeiten für 3 Monate vor dem aktuellen Monat bis Ende des nächsten Jahres
      final currentYear = now.year;
      final currentMonth = now.month;

      // Berechne Startjahr und -monat (3 Monate zurück)
      final startYear = currentMonth <= 3 ? currentYear - 1 : currentYear;
      final startMonth =
          currentMonth <= 3 ? currentMonth + 9 : currentMonth - 3;

      debugPrint(
          '📅 Lade Gebetszeiten von $startYear/$startMonth bis ${currentYear + 1}/$currentMonth');

      // Standort aus SharedPreferences holen
      final prefs = await SharedPreferences.getInstance();
      final country = prefs.getString('defaultCountry');
      final city = prefs.getString('defaultCity');

      if (country == null || city == null) {
        debugPrint(
            '❌ Land oder Stadt nicht definiert - keine jährlichen Gebetszeiten geladen');
        return;
      }

      final location = "${city.trim()},${country.trim()}";

      // Lade Gebetszeiten für das Vorjahr, falls unser Startdatum ins Vorjahr reicht
      if (startYear < currentYear) {
        await _prayerTimeRepo!.fetchAndSaveYearlyPrayerTimes(
          startYear,
          location,
          forceReload: forceReload,
        );
        debugPrint(
            '✅ Gebetszeiten für Vorjahr $startYear wurden geladen (forceReload: $forceReload)');
      }

      // Lade Gebetszeiten für das aktuelle Jahr
      await _prayerTimeRepo!.fetchAndSaveYearlyPrayerTimes(
        currentYear,
        location,
        forceReload: forceReload,
      );

      // Lade Gebetszeiten für das nächste Jahr
      await _prayerTimeRepo!.fetchAndSaveYearlyPrayerTimes(
        currentYear + 1,
        location,
        forceReload: forceReload,
      );

      debugPrint(
          '✅ Gebetszeiten für den Zeitraum $startYear bis ${currentYear + 1} wurden erfolgreich geladen');
    } catch (e) {
      debugPrint('❌ Fehler in _fetchYearlyPrayerTimesIfNeeded: $e');
    }
  }

  /// Updated den CalendarView und lädt neu
  void _updateCalendarViewFromNavIndex() {
    switch (_selectedNavIndex) {
      case 0:
        // Dashboard – kein CalendarView
        break;
      case 1:
        _selectedView = CalendarView.day;
        break;
      case 2:
        _selectedView = CalendarView.week;
        break;
      case 3:
        _selectedView = CalendarView.month;
        break;
    }

    // Kalenderansicht aktualisieren, falls notwendig
    if (_calendarController.view != _selectedView) {
      _calendarController.view = _selectedView;
    }

    setState(() {});

    if (_selectedNavIndex != 0) {
      // Nach dem Aktualisieren der Ansicht laden wir die Termine neu,
      // aber verzögert, um nicht während des Build-Prozesses den State zu ändern
      Future.microtask(() {
        loadAllAppointments();
      });
    }
  }

  Future<void> _loadAllCategories() async {
    final cats = await _categoryRepo.getAllCategories();

    // Gespeicherte Kategorieauswahl aus SharedPreferences laden
    final prefs = await SharedPreferences.getInstance();
    final savedCategoryList = prefs.getStringList('selectedCategoryIds');

    Set<int> selectedIds;
    if (savedCategoryList != null && savedCategoryList.isNotEmpty) {
      // Konvertiere die gespeicherten String-IDs zurück zu ints
      selectedIds = savedCategoryList
          .map((idStr) => int.tryParse(idStr))
          .where((id) => id != null)
          .map((id) => id!)
          .toSet();

      // Stelle sicher, dass nur gültige Kategorien ausgewählt sind
      selectedIds =
          selectedIds.where((id) => cats.any((cat) => cat.id == id)).toSet();
    } else {
      // Standard: Alle Kategorien auswählen
      selectedIds = cats.map((e) => e.id!).toSet();
    }

    if (mounted) {
      setState(() {
        _allCategories = cats;
        _selectedCategoryIds = selectedIds;
      });
    }
  }

  // Wandelt einen DB-Wert in int? um.
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Lädt alle normalen Appointments plus Gebetszeiten (falls aktiviert)
  Future<void> loadAllAppointments({bool addPrayers = true}) async {
    debugPrint('📅 loadAllAppointments aufgerufen (addPrayers: $addPrayers)');
    if (_isLoadingAppointments) {
      debugPrint('📅 loadAllAppointments: Bereits am Laden, überspringe...');
      return;
    }
    _isLoadingAppointments = true;

    try {
      // Normale Termine laden (aus dem Appointment Repository)
      final repo = Provider.of<AppointmentRepository>(context, listen: false);
      final appointments = await repo.getAllAppointments();
      debugPrint('📅 ${appointments.length} normale Termine geladen');

      // Kategoriefilter anwenden
      final filteredAppointments = _selectedCategoryIds.isEmpty
          ? appointments
          : appointments
              .where((a) =>
                  a.categoryId != null &&
                  _selectedCategoryIds.contains(a.categoryId))
              .toList();
      debugPrint(
          '📅 ${filteredAppointments.length} Termine nach Kategoriefilter');

      // Variable für das DataSource
      List<Appointment> allAppointments = [];

      // Gebetszeiten-Region Liste leeren
      _prayerTimeRegions.clear();

      // Zugriff auf PrayerTimeService sicherstellen
      final prayerTimeService =
          Provider.of<PrayerTimeService>(context, listen: false);

      // Termin-Start- und Endzeiten berechnen
      for (final appointment in filteredAppointments) {
        // Startzeit ist null => überspringen
        if (appointment.startTime == null) continue;

        // Gebetszeitbezogene Termine berechnen (unverändert)
        if (appointment.isRelatedToPrayerTimes) {
          final date = appointment.startTime!;
          final baseDate = DateTime(date.year, date.month, date.day);
          DateTime? start =
              await prayerTimeService.getCalculatedStartTime(appointment, date);
          DateTime? end =
              await prayerTimeService.getCalculatedEndTime(appointment, date);

          if (start != null && end != null) {
            allAppointments.add(Appointment(
              id: appointment.id,
              subject: appointment.subject,
              startTime: start,
              endTime: end,
              color: appointment.color,
              isAllDay: appointment.isAllDay,
              notes: appointment.notes,
              location: appointment.location,
              recurrenceRule: appointment.recurrenceRule,
              recurrenceExceptionDates: appointment.recurrenceExceptionDates,
            ));
          }
        } else {
          // Wenn kein gebetszeitbezogener Termin, direkt übernehmen
          allAppointments.add(Appointment(
            id: appointment.id,
            subject: appointment.subject,
            startTime: appointment.startTime!,
            endTime: appointment.endTime ?? appointment.startTime!,
            color: appointment.color,
            isAllDay: appointment.isAllDay,
            notes: appointment.notes,
            location: appointment.location,
            recurrenceRule: appointment.recurrenceRule,
            recurrenceExceptionDates: appointment.recurrenceExceptionDates,
          ));
        }
      }

      // Gebetszeiten als TimeRegions, wenn aktiviert
      List<TimeRegion> newPrayerTimeRegions = <TimeRegion>[];
      int gebetszeitenAnzahl = 0;
      if (addPrayers) {
        final currentView = _calendarController.view ?? _selectedView;
        debugPrint('📅 Aktuelle Kalenderansicht: $currentView');

        // Bestimmen, ob Gebetszeiten in der aktuellen Ansicht angezeigt werden sollen
        bool shouldShowPrayerTimes = false;
        if (currentView == CalendarView.day) {
          shouldShowPrayerTimes = _showPrayerTimesInDayView;
        } else if (currentView == CalendarView.week) {
          shouldShowPrayerTimes = _showPrayerTimesInWeekView;
        } else {
          shouldShowPrayerTimes = false; // Keine Gebetszeiten in Monatsansicht
        }

        // Nur laden, wenn sie angezeigt werden sollen
        if (shouldShowPrayerTimes) {
          debugPrint('📅 Erzeuge TimeRegions für Gebetszeiten');

          // Gebetszeiten aus der Datenbank laden
          DateTime now = DateTime.now();
          DateTime today = DateTime(now.year, now.month, now.day);

          // Die Namen der Gebetszeiten
          List<String> prayerNames = [
            'Fajr',
            'Dhuhr',
            'Asr',
            'Maghrib',
            'Isha'
          ];
          List<PrayerTime> prayerEnums = [
            PrayerTime.fajr,
            PrayerTime.dhuhr,
            PrayerTime.asr,
            PrayerTime.maghrib,
            PrayerTime.isha
          ];

          // Bei Wochenansicht für jede sichtbare Woche Gebetszeiten anlegen
          List<DateTime> daysToProcess = [];

          if (currentView == CalendarView.week) {
            // Verwende das angezeigte Datum als Referenz
            DateTime displayDate = _calendarController.displayDate ?? today;

            // Berechne den ersten und letzten Tag der sichtbaren Woche
            DateTime firstDay =
                displayDate.subtract(Duration(days: displayDate.day - 90));
            DateTime lastDay = firstDay.add(Duration(days: 250));

            // Für jeden Tag der Woche (Montag bis Sonntag) Gebetszeiten erstellen
            for (int i = 0; i < 340; i++) {
              daysToProcess.add(firstDay.add(Duration(days: i)));
            }
            debugPrint(
                '📅 Erzeuge Gebetszeiten für alle ${daysToProcess.length} Tage der Woche (${firstDay.toIso8601String().split('T')[0]} bis ${lastDay.toIso8601String().split('T')[0]})');
          } else {
            // Für Tagesansicht nur den ausgewählten Tag verwenden
            daysToProcess.add(_calendarController.displayDate ?? today);
            debugPrint('📅 Erzeuge Gebetszeiten nur für den aktuellen Tag');
          }

          // Standort aus SharedPreferences holen
          final prefs = await SharedPreferences.getInstance();
          final country = prefs.getString('defaultCountry');
          final city = prefs.getString('defaultCity');

          if (country == null || city == null) {
            debugPrint(
                '❌ Land oder Stadt nicht definiert - keine Gebetszeiten geladen');
            return;
          }

          final location = "${city.trim()},${country.trim()}";

          // Für jeden Tag Gebetszeiten aus der Datenbank laden
          for (DateTime day in daysToProcess) {
            for (int i = 0; i < prayerNames.length; i++) {
              try {
                // Tatsächliche Gebetsminuten aus der Datenbank laden
                final minutes = await _prayerTimeRepo.getPrayerTimeMinutes(
                    day, location, prayerEnums[i]);

                if (minutes != null) {
                  // Berechne Stunden und Minuten
                  final hours = minutes ~/ 60;
                  final mins = minutes % 60;

                  // Erstelle die Zeit mit den tatsächlichen Gebetszeiten
                  DateTime startTime =
                      DateTime(day.year, day.month, day.day, hours, mins);

                  // Gebetszeit geht 15 Minuten
                  DateTime endTime = startTime.add(const Duration(minutes: 15));

                  newPrayerTimeRegions.add(TimeRegion(
                    startTime: startTime,
                    endTime: endTime,
                    enablePointerInteraction: false,
                    color: Colors.grey.withOpacity(0.4),
                    text: prayerNames[i],
                    textStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ));

                  gebetszeitenAnzahl++;

                  debugPrint(
                      '📅 Gebetszeit ${prayerNames[i]} für ${day.toString().split(' ')[0]} geladen: ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}');
                } else {
                  debugPrint(
                      '❌ Keine ${prayerNames[i]}-Zeit für ${day.toString().split(' ')[0]} gefunden');
                }
              } catch (e) {
                debugPrint(
                    '❌ Fehler beim Laden der Gebetszeit ${prayerNames[i]} für ${day.toString().split(' ')[0]}: $e');
              }
            }
          }

          debugPrint(
              '📅 ${newPrayerTimeRegions.length} TimeRegions für Gebetszeiten erstellt');
        }
      }

      if (mounted) {
        setState(() {
          _dataSource = EventDataSource(allAppointments);
          // Übernehme neue TimeRegions und löse einen Neuaufbau aus
          _prayerTimeRegions.clear();
          _prayerTimeRegions.addAll(newPrayerTimeRegions);
          // Debugging-Meldung zur Bestätigung, dass die State-Aktualisierung durchgeführt wird
          debugPrint(
              '📅 State aktualisiert: ${allAppointments.length} Termine, ${_prayerTimeRegions.length} Gebetszeit-Regionen');
        });
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Termine: $e');
    } finally {
      _isLoadingAppointments = false;
    }

    // Dashboard aktualisieren, falls es aktiv ist
    if (_selectedNavIndex == 0 && _dashboardPageState != null) {
      _dashboardPageState!.reloadData();
    }
  }

  Future<void> _openSettings() async {
    // Speichere alte Einstellungen für Debugging
    final oldDayViewSetting = _showPrayerTimesInDayView;
    final oldWeekViewSetting = _showPrayerTimesInWeekView;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    // Ausführliche Aktualisierung nach Rückkehr von den Einstellungen
    // debugPrint("🔄 Zurück von Einstellungen: Lade alle Daten neu");

    // Einstellungen neu laden
    await _loadUserPrefs();

    // Vergleiche alte und neue Einstellungen für Debugging
    // debugPrint("⚙️ Gebetszeiten-Einstellungen Änderung:");
    // debugPrint(
    //     " - Tagesansicht: $oldDayViewSetting -> $_showPrayerTimesInDayView");
    // debugPrint(
    //     " - Wochenansicht: $oldWeekViewSetting -> $_showPrayerTimesInWeekView");

    // WICHTIG: Vollständige Neuladung der Daten erzwingen, indem wir den dataSource zurücksetzen
    setState(() {
      _dataSource = null;
    });

    // Erzwinge Neuladung der Gebetszeiten durch Direktaufruf statt _fetchYearlyPrayerTimesIfNeeded
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('defaultCountry');
    final city = prefs.getString('defaultCity');
    if (country != null && city != null) {
      final location = '${city.trim()},${country.trim()}'.toLowerCase();
      // debugPrint("📅 Erzwinge Neuladung der Gebetszeiten für $location");
      // Statt direktem Aufruf verwenden wir die Methode mit forceReload
      await _fetchYearlyPrayerTimesIfNeeded(forceReload: true);
    }

    // Aktuelle Ansicht explizit neu initialisieren
    setState(() {
      // Setze _selectedView explizit, um Neuinitialisierung zu erzwingen
      if (_selectedNavIndex == 1) {
        _selectedView = CalendarView.day;
      } else if (_selectedNavIndex == 2) {
        _selectedView = CalendarView.week;
      } else if (_selectedNavIndex == 3) {
        _selectedView = CalendarView.month;
      }
    });

    // Aktualisiere Controller mit der aktuellen Ansicht
    _calendarController.view = _selectedView;

    // Dashboard aktualisieren, falls wir uns im Dashboard befinden
    if (_selectedNavIndex == 0) {
      _dashboardPageState?.reloadData();
    }

    // Termine neu laden mit den aktualisierten Einstellungen
    await loadAllAppointments();

    // UI aktualisieren
    setState(() {});
  }

  /// Verarbeitet Änderungen der Kalenderansicht
  void _handleViewChanged(CalendarView newView) {
    debugPrint('📅 _handleViewChanged: $newView');

    if (_selectedView != newView) {
      setState(() {
        _selectedView = newView;
      });

      // Ansichtswechsel kann bedeuten, dass wir andere Gebetszeiten laden müssen
      loadAllAppointments();
    }
  }

  /// Verarbeitet Änderungen des ausgewählten Datums im Kalender
  void _handleSelectedDateChanged(DateTime? date) {
    if (date == null) return;

    debugPrint('📅 _handleSelectedDateChanged: $date');
    final oldDate = _selectedDate;
    setState(() {
      _selectedDate = date;
    });

    // Nur neu laden, wenn sich Jahr, Monat oder Tag geändert haben, um unnötige Ladevorgänge zu vermeiden
    if (oldDate.year != date.year ||
        oldDate.month != date.month ||
        oldDate.day != date.day) {
      // Gebetszeiten für das neue Datum neu laden
      _prayerTimeRegions.clear(); // Alte Regionen löschen
      loadAllAppointments();
    }
  }

  /// Wandelt den internen AppLanguage-Wert in einen Locale-Code (String) um.
  String _mapAppLanguageToCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.german:
        return 'de';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
      default:
        return 'en';
    }
  }

  /// Formatiert eine Uhrzeit unter Berücksichtigung der Spracheinstellungen.
  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    final languageCode = _mapAppLanguageToCode(
        Provider.of<AppLocalizations>(context, listen: false).currentLanguage);
    return DateFormat(pattern, languageCode).format(dt);
  }

  void _showCategoryFilterDialog(BuildContext context) {
    // Drawer schließen, falls er offen ist
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    // Wichtig: Längere Verzögerung hinzufügen, um Fokus-Probleme zu vermeiden
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Explizit den aktuellen Fokus zurücksetzen
      FocusManager.instance.primaryFocus?.unfocus();

      // WidgetsBinding verwenden, um sicherzustellen, dass der Fokus-Reset abgeschlossen ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return CategoryFilterDialog(
              categories: _allCategories,
              selectedCategoryIds: _selectedCategoryIds,
              onCategoriesSelected: (selectedIds) {
                if (!mounted) return;
                setState(() {
                  _selectedCategoryIds = selectedIds;
                });
                _saveSelectedCategoryIdsToPrefs();
                loadAllAppointments();
              },
              onCategoriesChanged: () {
                if (!mounted) return;
                _loadAllCategories();
                // Cache leeren, damit die aktualisierten Kategoriefarben verwendet werden
                _adapter.clearCategoryCache();
                loadAllAppointments();
              },
            );
          },
        );
      });
    });
  }

  /// Speichert die ausgewählten Kategorien in SharedPreferences.
  Future<void> _saveSelectedCategoryIdsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final catList = _selectedCategoryIds.map((id) => id.toString()).toList();
    await prefs.setStringList('selectedCategoryIds', catList);
  }

  void _handleNavigationChange(int index) {
    if (_selectedNavIndex == index) return; // Keine Änderung nötig, wenn gleich

    setState(() {
      _selectedNavIndex = index;
    });

    _updateCalendarViewFromNavIndex();
  }

  /// Zeigt ein Popup-Menü mit Synchronisationsoptionen an
  void _showSyncOptionsMenu(BuildContext context, RenderBox button) {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.calendarSync),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Platform.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(localizations.googleCalendar),
              subtitle: Text(localizations.syncImportExport),
              onTap: () {
                Navigator.pop(ctx);
                _performGoogleSync(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }

  /// Führt eine Synchronisation mit Google Calendar durch
  void _performGoogleSync(BuildContext context) {
    debugPrint('📅 Starte Google Calendar Synchronisation');
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.syncingWithGoogleCalendar)),
    );

    // Wir verwenden hier direkt die vereinfachte Implementierung für den Test
    _calendarSyncService.syncGoogleCalendarNow().then((_) {
      // Termine neu laden nach erfolgreicher Synchronisation
      loadAllAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.syncCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((e) {
      debugPrint('❌ Synchronisationsfehler: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Sicherheitsfunktion, die nur mit hartkodierten Daten arbeitet
  void _loadStaticAppointments() {
    debugPrint('📅 Lade statische Appointments für initiale Anzeige');

    // Zunächst prüfen, ob _prayerTimeRepo bereits initialisiert ist
    if (_prayerTimeRepo == null) {
      debugPrint(
          '❌ _loadStaticAppointments: _prayerTimeRepo ist noch nicht initialisiert');
      // Einfache Fallback-Lösung mit hartkodierten Zeiten
      _loadFallbackPrayerTimes();
      return;
    }

    // Wir wechseln zu einem Future-basierten Ansatz, um asynchrone Operationen zu ermöglichen
    Future<void> loadPrayerTimes() async {
      try {
        // Aktuelle Ansicht bestimmen
        final currentView = _calendarController.view ?? _selectedView;

        // Gebetszeiten-Anzeige je nach Ansicht steuern
        bool shouldShowPrayerTimes = false;
        if (currentView == CalendarView.day) {
          shouldShowPrayerTimes = _showPrayerTimesInDayView;
        } else if (currentView == CalendarView.week) {
          shouldShowPrayerTimes = _showPrayerTimesInWeekView;
        } else {
          shouldShowPrayerTimes = false; // Keine Gebetszeiten in Monatsansicht
        }

        if (!shouldShowPrayerTimes) {
          debugPrint('📅 Gebetszeiten sind für diese Ansicht ausgeschaltet');
          return;
        }

        // Zuerst sicherstellen, dass Gebetszeiten für einen längeren Zeitraum geladen sind
        await _fetchYearlyPrayerTimesIfNeeded();

        // Gebetszeiten aus der Datenbank laden
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        // Die Namen der Gebetszeiten
        List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        List<PrayerTime> prayerEnums = [
          PrayerTime.fajr,
          PrayerTime.dhuhr,
          PrayerTime.asr,
          PrayerTime.maghrib,
          PrayerTime.isha
        ];

        // Gebetszeiten-Region Liste leeren
        List<TimeRegion> newPrayerTimeRegions = [];

        // Bei Wochenansicht für jede sichtbare Woche Gebetszeiten anlegen
        List<DateTime> daysToProcess = [];

        if (currentView == CalendarView.week) {
          // Verwende das angezeigte Datum als Referenz
          DateTime displayDate = _calendarController.displayDate ?? today;

          // Berechne den ersten und letzten Tag der sichtbaren Woche
          DateTime firstDay =
              displayDate.subtract(Duration(days: displayDate.weekday - 1));
          DateTime lastDay = firstDay.add(Duration(days: 6));

          // Für jeden Tag der Woche (Montag bis Sonntag) Gebetszeiten erstellen
          for (int i = 0; i < 7; i++) {
            daysToProcess.add(firstDay.add(Duration(days: i)));
          }
          debugPrint(
              '📅 Erzeuge statische Gebetszeiten für alle ${daysToProcess.length} Tage der Woche (${firstDay.toIso8601String().split('T')[0]} bis ${lastDay.toIso8601String().split('T')[0]})');
        } else {
          // Für Tagesansicht nur den ausgewählten Tag verwenden
          daysToProcess.add(_calendarController.displayDate ?? today);
          debugPrint(
              '📅 Erzeuge statische Gebetszeiten nur für den aktuellen Tag');
        }

        // Standort aus SharedPreferences holen
        final prefs = await SharedPreferences.getInstance();
        final country = prefs.getString('defaultCountry');
        final city = prefs.getString('defaultCity');

        if (country == null || city == null) {
          debugPrint(
              '❌ Land oder Stadt nicht definiert - keine statischen Gebetszeiten geladen');
          return;
        }

        final location = "${city.trim()},${country.trim()}";

        // Für jeden Tag Gebetszeiten aus der Datenbank laden
        for (DateTime day in daysToProcess) {
          for (int i = 0; i < prayerNames.length; i++) {
            try {
              // Tatsächliche Gebetsminuten aus der Datenbank laden
              final minutes = await _prayerTimeRepo.getPrayerTimeMinutes(
                  day, location, prayerEnums[i]);

              if (minutes != null) {
                // Berechne Stunden und Minuten
                final hours = minutes ~/ 60;
                final mins = minutes % 60;

                // Erstelle die Zeit mit den tatsächlichen Gebetszeiten
                DateTime startTime =
                    DateTime(day.year, day.month, day.day, hours, mins);

                // Gebetszeit geht 15 Minuten
                DateTime endTime = startTime.add(const Duration(minutes: 15));

                newPrayerTimeRegions.add(TimeRegion(
                  startTime: startTime,
                  endTime: endTime,
                  enablePointerInteraction: false,
                  color: Colors.grey.withOpacity(0.4),
                  text: prayerNames[i],
                  textStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ));

                debugPrint(
                    '📅 Statische Gebetszeit ${prayerNames[i]} für ${day.toString().split(' ')[0]} geladen: ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}');
              } else {
                debugPrint(
                    '❌ Keine statische ${prayerNames[i]}-Zeit für ${day.toString().split(' ')[0]} gefunden');
              }
            } catch (e) {
              debugPrint(
                  '❌ Fehler beim Laden der statischen Gebetszeit ${prayerNames[i]} für ${day.toString().split(' ')[0]}: $e');
            }
          }
        }

        // State aktualisieren, wenn noch montiert
        if (mounted) {
          setState(() {
            _prayerTimeRegions.clear();
            _prayerTimeRegions.addAll(newPrayerTimeRegions);
            debugPrint(
                '📅 ${_prayerTimeRegions.length} statische TimeRegions erstellt');
          });
        }
      } catch (e) {
        debugPrint('❌ Fehler in loadPrayerTimes: $e');
        // Bei Fehlern auf Fallback zurückgreifen
        if (mounted) {
          _loadFallbackPrayerTimes();
        }
      }
    }

    // Starte den Ladevorgang
    loadPrayerTimes();
  }

  // Fallback-Methode mit hartkodierten Zeiten
  void _loadFallbackPrayerTimes() {
    setState(() {
      // Gebetszeiten als TimeRegions für die erste Anzeige
      _prayerTimeRegions.clear();

      // Aktuelle Ansicht bestimmen
      final currentView = _calendarController.view ?? _selectedView;

      // Gebetszeiten-Anzeige je nach Ansicht steuern
      bool shouldShowPrayerTimes = false;
      if (currentView == CalendarView.day) {
        shouldShowPrayerTimes = _showPrayerTimesInDayView;
      } else if (currentView == CalendarView.week) {
        shouldShowPrayerTimes = _showPrayerTimesInWeekView;
      } else {
        shouldShowPrayerTimes = false; // Keine Gebetszeiten in Monatsansicht
      }

      if (!shouldShowPrayerTimes) {
        debugPrint('📅 Gebetszeiten sind für diese Ansicht ausgeschaltet');
        return;
      }

      // Test-TimeRegion für erste Anzeige
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      // Testweise 5 TimeRegions für Gebetszeiten erstellen
      List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
      List<int> prayerHours = [
        5,
        12,
        15,
        19,
        21
      ]; // Ungefähre Stunden für Tests

      // Bei Wochenansicht für jeden Tag der Woche Gebetszeiten anlegen
      List<DateTime> daysToProcess = [];

      if (currentView == CalendarView.week) {
        // Berechne den ersten Tag der aktuellen Woche (Montag)
        DateTime displayDate = _calendarController.displayDate ?? today;
        DateTime firstDay =
            displayDate.subtract(Duration(days: displayDate.weekday - 1));

        // Für jeden Tag der Woche (Montag bis Sonntag) Gebetszeiten erstellen
        for (int i = 0; i < 7; i++) {
          daysToProcess.add(firstDay.add(Duration(days: i)));
        }
        debugPrint(
            '📅 Erzeuge Fallback-Gebetszeiten für alle ${daysToProcess.length} Tage der Woche');
      } else {
        // Für Tagesansicht nur den aktuellen Tag verwenden
        daysToProcess.add(_calendarController.displayDate ?? today);
        debugPrint(
            '📅 Erzeuge Fallback-Gebetszeiten nur für den aktuellen Tag');
      }

      // Für jeden Tag Gebetszeiten anlegen
      for (DateTime day in daysToProcess) {
        for (int i = 0; i < prayerNames.length; i++) {
          DateTime startTime =
              DateTime(day.year, day.month, day.day, prayerHours[i]);
          DateTime endTime = startTime.add(const Duration(minutes: 15));

          _prayerTimeRegions.add(TimeRegion(
            startTime: startTime,
            endTime: endTime,
            enablePointerInteraction: false,
            color: Colors.grey.withOpacity(0.4),
            text: prayerNames[i],
            textStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ));
        }
      }

      debugPrint(
          '📅 ${_prayerTimeRegions.length} Fallback-TimeRegions erstellt');
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedNavIndex != 0
          ? HomeAppBar(
              onSettingsPressed: () => _openSettings(),
              onCategoryFilterPressed: () => _showCategoryFilterDialog(context),
              onSyncPressed: () {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                _showSyncOptionsMenu(context, button);
              },
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              localizations: localizations,
            )
          : null,
      drawer: AppDrawer(
        onSettingsOpen: () async {
          // Einstellungen wurden aktualisiert
          await _loadUserPrefs();

          // WICHTIG: Vollständige Neuladung der Daten erzwingen, indem wir den dataSource zurücksetzen
          setState(() {
            _dataSource = null;
          });

          await _fetchYearlyPrayerTimesIfNeeded(forceReload: true);

          // Aktuelle Ansicht explizit neu initialisieren
          setState(() {
            // Setze _selectedView explizit, um Neuinitialisierung zu erzwingen
            if (_selectedNavIndex == 1) {
              _selectedView = CalendarView.day;
            } else if (_selectedNavIndex == 2) {
              _selectedView = CalendarView.week;
            } else if (_selectedNavIndex == 3) {
              _selectedView = CalendarView.month;
            }
          });

          // Aktualisiere Controller mit der aktuellen Ansicht
          _calendarController.view = _selectedView;

          // Dashboard aktualisieren, falls wir uns im Dashboard befinden
          if (_selectedNavIndex == 0) {
            _dashboardPageState?.reloadData();
          }

          // Termine neu laden mit den aktualisierten Einstellungen
          await loadAllAppointments();
        },
        onCategoriesSelected: (selectedIds) {
          setState(() {
            _selectedCategoryIds = selectedIds;
          });
          _saveSelectedCategoryIdsToPrefs();
          loadAllAppointments();
        },
        onReloadAppointments: () {
          _loadAllCategories();
          // Cache leeren, damit die aktualisierten Kategoriefarben verwendet werden
          _adapter.clearCategoryCache();
          loadAllAppointments();
        },
        categories: _allCategories,
        selectedCategoryIds: _selectedCategoryIds,
      ),
      body: _selectedNavIndex == 0
          ? DashboardPage(
              key: const ValueKey('dashboard'),
              onStateCreated: (state) {
                _dashboardPageState = state;
              },
            )
          : _buildCalendarView(),
      floatingActionButton: _selectedNavIndex >= 1 && !Platform.isIOS
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AppointmentCreationPage(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
                if (result == true) {
                  loadAllAppointments();
                }
              },
              backgroundColor: logoColor,
              child: Icon(
                Platform.isIOS ? CupertinoIcons.add : Icons.add,
                color: Colors.white,
              ),
            )
          : null,
      bottomNavigationBar: HomeNavigationBar(
        selectedIndex: _selectedNavIndex,
        onIndexSelected: _handleNavigationChange,
        localizations: localizations,
        onAppointmentAdded: loadAllAppointments,
      ),
    );
  }

  Widget _buildCalendarView() {
    if (_isLoadingAppointments) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    debugPrint(
        '📅 _buildCalendarView aufgerufen - ${_prayerTimeRegions.length} Gebetszeit-Regionen');

    // Mindestens eine TimeRegion zur Überprüfung
    if (_prayerTimeRegions.isEmpty) {
      // Hinzufügen einer Beispiel-TimeRegion, um zu testen, ob es grundsätzlich funktioniert
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      _prayerTimeRegions.add(TimeRegion(
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 10, minutes: 30)),
        enablePointerInteraction: false,
        color: Colors.red.withOpacity(0.5),
        text: "TEST-REGION",
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
      debugPrint('📅 Testregion hinzugefügt');
    }

    return CalendarViewWidget(
      selectedView: _selectedView,
      calendarController: _calendarController,
      dataSource: _dataSource,
      selectedDate: _selectedDate,
      use24hFormat: _use24hFormat,
      showPrayerTimesInDayView: _showPrayerTimesInDayView,
      showPrayerTimesInWeekView: _showPrayerTimesInWeekView,
      languageCode: _mapAppLanguageToCode(
          Provider.of<AppLocalizations>(context, listen: false)
              .currentLanguage),
      onViewChanged: _handleViewChanged,
      onSelectedDateChanged: _handleSelectedDateChanged,
      onAppointmentsChanged: loadAllAppointments,
      specialTimeRegions: _prayerTimeRegions,
    );
  }
}
