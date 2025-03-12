// lib/ui/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repositories & Services
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';

// Models & Widgets
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/ui/widgets/create_events.dart';
import 'package:muslim_calendar/ui/widgets/prayer_time_appointment_adapter.dart';

// Pages
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';
import 'package:muslim_calendar/ui/pages/settings_page.dart';
import 'package:muslim_calendar/ui/pages/dashboard_page.dart';
import 'package:muslim_calendar/ui/pages/appointment_details_page.dart';
import 'package:muslim_calendar/ui/pages/qibla_compass_page.dart';
import 'package:muslim_calendar/ui/pages/category_management_page.dart';

// Dialogs
import 'package:muslim_calendar/ui/dialogs/category_edit_dialog.dart';

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';

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
  late CalendarController _calendarController;
  EventDataSource? _dataSource;

  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final PrayerTimeAppointmentAdapter _adapter = PrayerTimeAppointmentAdapter(
    prayerTimeService: PrayerTimeService(PrayerTimeRepository()),
    recurrenceService: RecurrenceService(),
  );

  DateTime? _selectedDate;
  List<CategoryModel> _allCategories = [];
  Set<int> _selectedCategoryIds = {};

  final GlobalKey<DashboardPageState> _dashboardKey =
      GlobalKey<DashboardPageState>();
  late final _dashboardPage = DashboardPage(key: _dashboardKey);

  bool _use24hFormat = false;

  // Referenz auf den CalendarSyncService
  late CalendarSyncService _calendarSyncService;

  // Dezenter Farbton für Gebetszeiten (BlueGrey 300)
  static const Color _prayerTimeColor = Color(0xFF90A4AE);

  // Flags aus den Settings (für Daily/Weekly und ggf. Dashboard-Gebetszeiten)
  bool _showPrayerSlotsInDashboard = true;
  bool _showPrayerTimesInDayView = true;
  bool _showPrayerTimesInWeekView = true;
  bool _showPrayerTimesInMonthView = false;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController();
    _selectedNavIndex = 0; // Standard: Dashboard

    // Standardmäßig heute auswählen
    _selectedDate = DateTime.now();
    _calendarController.selectedDate = _selectedDate;
    _calendarController.displayDate = _selectedDate;

    // Zuerst die Benutzereinstellungen laden
    _loadUserPrefs().then((_) {
      // Dann die Kalenderansicht aktualisieren
      _updateCalendarViewFromNavIndex();

      // Kategorien laden
      _loadAllCategories();

      // Gebetszeiten für das ganze Jahr laden, falls nötig
      _fetchYearlyPrayerTimesIfNeeded().then((_) {
        // Termine laden, nachdem alle Vorbereitungen abgeschlossen sind
        loadAllAppointments();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // CalendarSyncService registrieren
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);

    // Listener hinzufügen, um auf Kategorieänderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);
    super.dispose();
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    if (!mounted) return;

    debugPrint("🔄 HomePage: Kategorien wurden geändert, lade Termine neu...");
    // Kategorien neu laden
    _loadAllCategories().then((_) {
      if (!mounted) return;

      // Kategorien-Cache leeren, damit die aktualisierten Farben verwendet werden
      _adapter.clearCategoryCache();
      // Termine neu laden mit den aktualisierten Kategorien
      loadAllAppointments();
      // Dashboard aktualisieren
      _dashboardKey.currentState?.reloadData();
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

    debugPrint('📱 Gebetszeiten-Einstellungen geladen:');
    debugPrint(' - 24h Format: $use24h');
    debugPrint(' - Im Dashboard anzeigen: $showInDashboard');
    debugPrint(' - In Tagesansicht anzeigen: $showInDayView');
    debugPrint(' - In Wochenansicht anzeigen: $showInWeekView');

    setState(() {
      _use24hFormat = use24h;
      _showPrayerSlotsInDashboard = showInDashboard;
      _showPrayerTimesInDayView = showInDayView;
      _showPrayerTimesInWeekView = showInWeekView;
      // In der Monatsansicht sollen keine Gebetszeiten angezeigt werden.
      _showPrayerTimesInMonthView = false;
    });
  }

  /// Prüft, ob bereits das ganze Jahr an Gebetszeiten gespeichert wurde.
  Future<void> _fetchYearlyPrayerTimesIfNeeded(
      {bool forceReload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    String? country = prefs.getString('defaultCountry');
    String? city = prefs.getString('defaultCity');

    // Prüfen, ob die Standorteinstellungen fehlen
    if (country == null || city == null) {
      debugPrint(
          "⚠️ FEHLER: Land oder Stadt nicht in SharedPreferences gesetzt!");
      // Da diese Methode von verschiedenen Stellen aufgerufen werden kann,
      // können wir hier keine UI-Fehlermeldung anzeigen
      // Die aufrufende Methode muss sich darum kümmern
      return; // Abbrechen, bis die Einstellungen gesetzt sind
    }

    final location = '${city.trim()},${country.trim()}'.toLowerCase();
    final now = DateTime.now();
    await _prayerTimeRepo.fetchAndSaveYearlyPrayerTimes(now.year, location,
        forceReload: forceReload);
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
      // Nach dem Aktualisieren der Ansicht laden wir die Termine neu
      loadAllAppointments();
    }
  }

  Future<void> _loadAllCategories() async {
    final cats = await _categoryRepo.getAllCategories();
    setState(() {
      _allCategories = cats;
      _selectedCategoryIds = cats.map((e) => e.id!).toSet();
    });
  }

  // Wandelt einen DB-Wert in int? um.
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Lädt alle normalen Appointments plus Gebetszeiten (falls aktiviert)
  Future<void> loadAllAppointments() async {
    try {
      List<Appointment> allAppointments = [];

      // Termine aus der Datenbank laden
      final appointments = await _appointmentRepo.getAllAppointments();

      // Adapter verwenden, um Termine zu konvertieren
      for (var appointment in appointments) {
        final appointmentList = await _adapter.getAppointmentsForRange(
          appointment,
          DateTime.now().subtract(const Duration(days: 365)),
          DateTime.now().add(const Duration(days: 365)),
        );
        allAppointments.addAll(appointmentList);
      }

      // Die aktuelle Kalenderansicht bestimmen
      CalendarView currentView = _selectedView;

      debugPrint("🕌 loadAllAppointments: View = $currentView");
      debugPrint("🕌 showPrayerTimesInDayView = $_showPrayerTimesInDayView");
      debugPrint("🕌 showPrayerTimesInWeekView = $_showPrayerTimesInWeekView");

      // Gebetszeiten nur hinzufügen, wenn sie für die aktuelle Ansicht aktiviert sind
      bool addPrayers = false; // Default: keine Gebetszeiten anzeigen

      if (_selectedView == CalendarView.day) {
        // In Tagesansicht nur anzeigen, wenn die entsprechende Einstellung aktiviert ist
        addPrayers = _showPrayerTimesInDayView;
        debugPrint(
            "🕌 Tagesansicht: addPrayers = $addPrayers (basierend auf _showPrayerTimesInDayView)");
      } else if (_selectedView == CalendarView.week) {
        // In Wochenansicht nur anzeigen, wenn die entsprechende Einstellung aktiviert ist
        addPrayers = _showPrayerTimesInWeekView;
        debugPrint(
            "🕌 Wochenansicht: addPrayers = $addPrayers (basierend auf _showPrayerTimesInWeekView)");
      } else {
        // In anderen Ansichten (z.B. Monatsansicht) keine Gebetszeiten anzeigen
        addPrayers = false;
        debugPrint("🕌 Andere Ansicht: addPrayers = false");
      }

      debugPrint("🕌 Finale Entscheidung: addPrayers = $addPrayers");

      if (addPrayers && _selectedNavIndex != 0) {
        final now = DateTime.now();
        // Für Tag- und Wochenansicht brauchen wir nicht so viele Daten, nur einen begrenzten Zeitraum
        final int daysBack = currentView == CalendarView.day ? 7 : 30;
        final int daysForward = currentView == CalendarView.day ? 7 : 30;

        final startRange = now.subtract(Duration(days: daysBack));
        final endRange = now.add(Duration(days: daysForward));

        final prayerTimeEntries = await _prayerTimeRepo.getPrayerTimesInRange(
          startRange,
          endRange,
        );

        final prefs = await SharedPreferences.getInstance();
        String? country = prefs.getString('defaultCountry');
        String? city = prefs.getString('defaultCity');

        // Prüfen, ob die Standorteinstellungen fehlen
        if (country == null || city == null) {
          debugPrint(
              "⚠️ FEHLER: Land oder Stadt nicht in SharedPreferences gesetzt!");
          // Zeige eine Fehlermeldung an
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Standorteinstellungen fehlen. Bitte in den Einstellungen konfigurieren."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }

          // Einstellungen öffnen, damit der Benutzer die Standorteinstellungen setzen kann
          await _openSettings();
          return; // Keine Termine laden, bis die Einstellungen gesetzt sind
        }

        final userLocation = '${city.trim()},${country.trim()}'.toLowerCase();
        final filteredEntries = prayerTimeEntries.where((row) {
          final dbLoc = (row['location'] as String).toLowerCase();
          return dbLoc == userLocation;
        }).toList();

        debugPrint(
            "Gefundene Gebetszeiten für den aktuellen Standort: ${filteredEntries.length}");

        // Lade die Islam-Kategorie (ID 2) für Gebetszeiten
        final islamCategory = await _categoryRepo.getCategory(2);
        final prayerTimeColor = islamCategory?.color ?? _prayerTimeColor;

        int gebetszeitenAnzahl = 0;

        for (var row in filteredEntries) {
          final dateStr = row['date'].toString();
          final parts = dateStr.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final baseDay = DateTime(year, month, day);

          // Dauer von 15 Minuten für Gebetszeiten-Slots
          const gebetszeitDuration = 15;

          Appointment? createPrayerAppointment(String name, int? minutes) {
            if (minutes == null) return null;
            final start = baseDay.add(Duration(minutes: minutes));
            final end = start.add(const Duration(minutes: gebetszeitDuration));
            return Appointment(
              id: 'prayer_${name}_${baseDay.toIso8601String()}',
              subject: name,
              notes: 'prayerTime',
              startTime: start,
              endTime: end,
              isAllDay: false,
              color: Colors.grey
                  .shade400, // Verwende ein deutlicheres Grau statt prayerTimeColor
            );
          }

          final fajrApp = createPrayerAppointment('Fajr', _toInt(row['fajr']));
          if (fajrApp != null) {
            allAppointments.add(fajrApp);
            gebetszeitenAnzahl++;
          }

          final dhuhrApp =
              createPrayerAppointment('Dhuhr', _toInt(row['dhuhr']));
          if (dhuhrApp != null) {
            allAppointments.add(dhuhrApp);
            gebetszeitenAnzahl++;
          }

          final asrApp = createPrayerAppointment('Asr', _toInt(row['asr']));
          if (asrApp != null) {
            allAppointments.add(asrApp);
            gebetszeitenAnzahl++;
          }

          final maghribApp =
              createPrayerAppointment('Maghrib', _toInt(row['maghrib']));
          if (maghribApp != null) {
            allAppointments.add(maghribApp);
            gebetszeitenAnzahl++;
          }

          final ishaApp = createPrayerAppointment('Isha', _toInt(row['isha']));
          if (ishaApp != null) {
            allAppointments.add(ishaApp);
            gebetszeitenAnzahl++;
          }
        }

        debugPrint(
            "Insgesamt ${gebetszeitenAnzahl} Gebetszeiten zum Kalender hinzugefügt");
      }

      setState(() {
        _dataSource = EventDataSource(allAppointments);
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
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
    debugPrint("🔄 Zurück von Einstellungen: Lade alle Daten neu");

    // Einstellungen neu laden
    await _loadUserPrefs();

    // Vergleiche alte und neue Einstellungen für Debugging
    debugPrint("⚙️ Gebetszeiten-Einstellungen Änderung:");
    debugPrint(
        " - Tagesansicht: $oldDayViewSetting -> $_showPrayerTimesInDayView");
    debugPrint(
        " - Wochenansicht: $oldWeekViewSetting -> $_showPrayerTimesInWeekView");

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
      debugPrint("📅 Erzwinge Neuladung der Gebetszeiten für $location");
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
      _dashboardKey.currentState?.reloadData();
    }

    // Termine neu laden mit den aktualisierten Einstellungen
    await loadAllAppointments();

    // UI aktualisieren
    setState(() {});

    // Debug-Ausgabe nach der Neuladung
    debugPrint("✅ Daten nach Einstellungsänderung neu geladen");
    if (_dataSource != null) {
      debugPrint(
          " - Anzahl Termine im DataSource: ${_dataSource!.appointments!.length}");

      // Zähle Gebetszeiteinträge
      int prayerTimeCount = 0;
      for (var appointment in _dataSource!.appointments!) {
        if (appointment.notes == 'prayerTime') {
          prayerTimeCount++;
        }
      }
      debugPrint(" - Davon Gebetszeiten: $prayerTimeCount");
    } else {
      debugPrint(" - DataSource ist null!");
    }
  }

  Future<void> _openQiblaCompass() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QiblaCompassPage()),
    );
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

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    final bool showFab = (_selectedNavIndex >= 1);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            onPressed: _openQiblaCompass,
            tooltip: 'Qibla Compass',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: loc.settings,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategoryFilterDialog,
            tooltip: loc.filterCategories,
          ),
        ],
      ),
      body: _selectedNavIndex == 0
          ? _dashboardPage
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              child: Localizations.override(
                context: context,
                locale: Locale(languageCode),
                child: SfCalendar(
                  headerStyle: const CalendarHeaderStyle(
                    backgroundColor: Colors.transparent,
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  view: _selectedView,
                  controller: _calendarController,
                  dataSource: _dataSource,
                  allowAppointmentResize: true,
                  showDatePickerButton: true,
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.indicator,
                    showAgenda: true,
                    agendaItemHeight: 50,
                    monthCellStyle: MonthCellStyle(
                      trailingDatesBackgroundColor:
                          Color.fromARGB(0, 165, 165, 165),
                    ),
                  ),
                  // Hier wird timeSlotViewSettings dynamisch erstellt,
                  // sodass das 24-Stunden-Format berücksichtigt wird.
                  timeSlotViewSettings: TimeSlotViewSettings(
                    timeIntervalHeight: 80,
                    timeFormat: _use24hFormat ? 'HH' : 'h a',
                  ),
                  appointmentBuilder: (BuildContext context,
                      CalendarAppointmentDetails details) {
                    if (details.appointments.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final Appointment appointment = details.appointments.first;

                    // Für Gebetszeiten spezielles Styling
                    final bool isPrayerTime = appointment.notes == 'prayerTime';

                    debugPrint(
                        "Appointment: ${appointment.subject}, isPrayerTime: $isPrayerTime");

                    // In jedem Fall überprüfen wir die aktuelle Ansicht und die entsprechenden Einstellungen
                    bool shouldShowPrayerTime = false;

                    if (isPrayerTime) {
                      if (_selectedView == CalendarView.day) {
                        shouldShowPrayerTime = _showPrayerTimesInDayView;
                        debugPrint(
                            "Gebetszeit in Tagesansicht: ${appointment.subject}, anzeigen: $shouldShowPrayerTime");
                      } else if (_selectedView == CalendarView.week) {
                        shouldShowPrayerTime = _showPrayerTimesInWeekView;
                        debugPrint(
                            "Gebetszeit in Wochenansicht: ${appointment.subject}, anzeigen: $shouldShowPrayerTime");
                      } else {
                        // In anderen Ansichten keine Gebetszeiten anzeigen
                        shouldShowPrayerTime = false;
                        debugPrint(
                            "Gebetszeit in anderen Ansichten: ${appointment.subject}, anzeigen: false");
                      }

                      // Wenn Gebetszeit nicht angezeigt werden soll, leeres Widget zurückgeben
                      if (!shouldShowPrayerTime) {
                        return const SizedBox.shrink();
                      }
                    }

                    // Spezielles Styling für Gebetszeiten, wenn sie angezeigt werden sollen
                    if (isPrayerTime) {
                      debugPrint(
                          "Gebetszeit wird angezeigt: ${appointment.subject}");
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey[
                              400], // Dunkleres Grau für bessere Sichtbarkeit
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors
                                .black26, // Dunklere Ränder für besseren Kontrast
                            width: 1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            appointment.subject,
                            style: TextStyle(
                              color: Colors
                                  .black87, // Sehr dunkles Grau für gute Lesbarkeit
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // Für die Monatsansicht
                    if (_selectedView == CalendarView.month) {
                      return Container(
                        decoration: BoxDecoration(
                          color: appointment.color,
                          shape: BoxShape.rectangle,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: appointment.isAllDay
                            ? Text(
                                appointment.subject,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.subject,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }

                    // Für normale Termine in Tag- und Wochenansicht
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: appointment.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          appointment.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  },
                  onSelectionChanged: (details) {
                    _selectedDate = details.date;
                  },
                  onViewChanged: (ViewChangedDetails details) {
                    // Wenn sich die Ansicht ändert, aktualisieren wir die Variablen
                    // und laden die Termine neu
                    if (_calendarController.view != null) {
                      CalendarView newView = _calendarController.view!;

                      // Nur wenn sich die Ansicht tatsächlich geändert hat
                      if (newView != _selectedView) {
                        _selectedView = newView;

                        // Synchronisiere _selectedNavIndex mit der neuen Ansicht
                        if (newView == CalendarView.day) {
                          _selectedNavIndex = 1;
                        } else if (newView == CalendarView.week) {
                          _selectedNavIndex = 2;
                        } else if (newView == CalendarView.month) {
                          _selectedNavIndex = 3;
                        }

                        // UI aktualisieren und Termine neu laden
                        setState(() {});
                        loadAllAppointments();
                      }
                    }
                  },
                  onTap: (calendarTapDetails) async {
                    if (calendarTapDetails.targetElement ==
                        CalendarElement.appointment) {
                      final app = calendarTapDetails.appointments?.first;
                      if (app == null) return;
                      if (app.notes == 'prayerTime') return;
                      if (app.id is int) {
                        final appointmentId = app.id as int;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AppointmentDetailsPage(
                              appointmentId: appointmentId,
                            ),
                          ),
                        );
                        loadAllAppointments();
                      }
                    } else if (calendarTapDetails.targetElement ==
                        CalendarElement.calendarCell) {
                      if (calendarTapDetails.date == _selectedDate) {
                        setState(() {
                          _selectedNavIndex = 1;
                          _updateCalendarViewFromNavIndex();
                        });
                      }
                    }
                  },
                ),
              ),
            ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              tooltip: loc.addNewAppointment,
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
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (int index) {
          debugPrint("⏭️ Navigation: Wechsel zu Index $index");
          setState(() {
            _selectedNavIndex = index;
          });
          _updateCalendarViewFromNavIndex();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard),
            label: loc.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_day),
            label: loc.day,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week),
            label: loc.week,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: loc.month,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    final languageCode = _mapAppLanguageToCode(
        Provider.of<AppLocalizations>(context, listen: false).currentLanguage);
    return DateFormat(pattern, languageCode).format(dt);
  }

  /// Speichert die ausgewählten Kategorien in SharedPreferences.
  Future<void> _saveSelectedCategoryIdsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final catList = _selectedCategoryIds.map((id) => id.toString()).toList();
    await prefs.setStringList('selectedCategoryIds', catList);
  }

  void _showCategoryFilterDialog() {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(loc.filterCategories),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var cat in _allCategories)
                      CheckboxListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(child: Text(cat.name)),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Bearbeiten',
                              onPressed: () async {
                                Navigator.of(context).pop();

                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) =>
                                      CategoryEditDialog(category: cat),
                                );

                                if (result == true) {
                                  await _loadAllCategories();
                                  // Cache leeren, damit die aktualisierten Kategoriefarben verwendet werden
                                  _adapter.clearCategoryCache();
                                  loadAllAppointments();
                                  _dashboardKey.currentState?.reloadData();

                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   SnackBar(
                                  //     content: Text(
                                  //         'Kategorie "${cat.name}" wurde aktualisiert'),
                                  //     duration: const Duration(seconds: 2),
                                  //   ),
                                  // );
                                }
                              },
                            ),
                            if (!cat.isDefault)
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  // Bestätigungsdialog anzeigen
                                  final confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Kategorie löschen'),
                                      content: Text(
                                          'Möchten Sie die Kategorie "${cat.name}" wirklich löschen?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: Text('Abbrechen'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: Text('Löschen',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    try {
                                      await _categoryRepo
                                          .deleteCategory(cat.id!);

                                      // Cache leeren
                                      _adapter.clearCategoryCache();

                                      // UI aktualisieren
                                      await _loadAllCategories();
                                      if (mounted) {
                                        setStateDialog(
                                            () {}); // Dialog aktualisieren

                                        // Snackbar anzeigen
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Kategorie "${cat.name}" gelöscht'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Fehler: ${e.toString()}'),
                                            duration:
                                                const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                        value: _selectedCategoryIds.contains(cat.id),
                        onChanged: (val) {
                          setStateDialog(() {
                            if (val == true) {
                              _selectedCategoryIds.add(cat.id!);
                            } else {
                              _selectedCategoryIds.remove(cat.id!);
                            }
                          });
                        },
                      ),
                    const Divider(),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showAddCategoryDialog();
                      },
                      child: Text(loc.addNewCategory),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(loc.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveSelectedCategoryIdsToPrefs();
                    loadAllAppointments();
                    _dashboardKey.currentState?.reloadData();
                  },
                  child: Text(loc.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    // Vorschlag verschiedener Farben zur Auswahl
    final List<Color> colorOptions = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(loc.addNewCategory),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.titleLabel,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Farbe auswählen:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = colorOptions[index];
                      final isSelected = color.value == selectedColor.value;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4)
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    debugPrint(
                        "Erstelle Kategorie: $name mit Farbe: $selectedColor");

                    final newCategory = CategoryModel.newCategory(
                      name: name,
                      color: selectedColor,
                    );
                    await _categoryRepo.insertCategory(newCategory);
                    await _loadAllCategories();
                    Navigator.of(ctx).pop();
                    loadAllAppointments();

                    // Zeige Bestätigung an
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kategorie "$name" erstellt'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(loc.save),
              ),
            ],
          );
        });
      },
    );
  }

  // Öffnet die Kategorieverwaltungsseite
  void _openCategoryManagement() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CategoryManagementPage(),
      ),
    )
        .then((_) {
      // Aktualisiere den Kalender, wenn wir zurückkehren
      setState(() {
        // Kalender neu laden
        if (_dataSource != null) {
          loadAllAppointments();
        }
      });
    });
  }

  // Drawer (Menü) der App
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Muslim Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Kategorien-Verwaltung',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Kalender'),
            onTap: () {
              Navigator.pop(context);
              // Bereits auf der Kalenderseite, nichts tun
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategorien verwalten'),
            onTap: () {
              Navigator.pop(context);
              _openCategoryManagement();
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Qibla Kompass'),
            onTap: () {
              Navigator.pop(context);
              _openQiblaCompass();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Einstellungen'),
            onTap: () {
              Navigator.pop(context);
              _openSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Über'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Muslim Calendar',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Muslim Calendar',
              );
            },
          ),
        ],
      ),
    );
  }
}
