// lib/ui/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_dialog.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_list_tile.dart';

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
import 'package:muslim_calendar/ui/widgets/prayer_time_appointment_adapter.dart';

// Ausgelagerte Widgets
import 'package:muslim_calendar/ui/widgets/home/calendar_view_widget.dart';
import 'package:muslim_calendar/ui/widgets/home/category_filter_dialog.dart';
import 'package:muslim_calendar/ui/widgets/home/navigation_bar_widget.dart';
import 'package:muslim_calendar/ui/widgets/home/home_app_bar_widget.dart';
import 'package:muslim_calendar/ui/widgets/home/add_appointment_fab.dart';

// Pages
import 'package:muslim_calendar/ui/pages/settings_page.dart';
import 'package:muslim_calendar/ui/pages/dashboard_page.dart';
import 'package:muslim_calendar/ui/pages/qibla_compass_page.dart';

// Dialogs

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
  late CalendarController _calendarController;
  CalendarDataSource? _dataSource;

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

  DashboardPageState? _dashboardPageState;

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

  // Variablen am Anfang der HomePageState-Klasse hinzufügen
  bool _isLoadingAppointments = false;

  // Schlüssel für den Scaffold, um den Drawer zu öffnen
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // PrayerTimeService registrieren und Listener hinzufügen
    final prayerTimeService =
        Provider.of<PrayerTimeService>(context, listen: false);
    prayerTimeService.addListener(_onPrayerTimesChanged);

    // Listener hinzufügen, um auf Kategorieänderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);

    // PrayerTimeService Listener entfernen
    final prayerTimeService =
        Provider.of<PrayerTimeService>(context, listen: false);
    prayerTimeService.removeListener(_onPrayerTimesChanged);

    super.dispose();
  }

  // Wird aufgerufen, wenn sich Gebetszeiten ändern
  void _onPrayerTimesChanged() {
    if (!mounted) return;

    debugPrint(
        "🕌 HomePage: Gebetszeiten wurden geändert, lade Termine neu...");

    // Gebetszeiten für das ganze Jahr neu laden, falls nötig
    _fetchYearlyPrayerTimesIfNeeded(forceReload: true).then((_) {
      // Termine neu laden
      loadAllAppointments();

      // Dashboard aktualisieren, falls es aktiv ist
      if (_selectedNavIndex == 0) {
        _dashboardPageState?.reloadData();
      }
    });
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

  /// Prüft, ob bereits das ganze Jahr an Gebetszeiten gespeichert wurde.
  Future<void> _fetchYearlyPrayerTimesIfNeeded(
      {bool forceReload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    String? country = prefs.getString('defaultCountry');
    String? city = prefs.getString('defaultCity');

    // Prüfen, ob die Standorteinstellungen fehlen
    if (country == null || city == null) {
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
      // Nach dem Aktualisieren der Ansicht laden wir die Termine neu,
      // aber verzögert, um nicht während des Build-Prozesses den State zu ändern
      Future.microtask(() {
        loadAllAppointments();
      });
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
    // Verhindere mehrfache gleichzeitige Aufrufe
    if (_isLoadingAppointments) return;
    _isLoadingAppointments = true;

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

      // Gebetszeiten nur hinzufügen, wenn sie für die aktuelle Ansicht aktiviert sind
      bool addPrayers = false; // Default: keine Gebetszeiten anzeigen

      if (_selectedView == CalendarView.day) {
        // In Tagesansicht nur anzeigen, wenn die entsprechende Einstellung aktiviert ist
        addPrayers = _showPrayerTimesInDayView;
      } else if (_selectedView == CalendarView.week) {
        // In Wochenansicht nur anzeigen, wenn die entsprechende Einstellung aktiviert ist
        addPrayers = _showPrayerTimesInWeekView;
      } else if (_selectedView == CalendarView.month) {
        // In Monatsansicht explizit keine Gebetszeiten anzeigen
        addPrayers = false;
      }

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
          _isLoadingAppointments = false;
          return; // Keine Termine laden, bis die Einstellungen gesetzt sind
        }

        final userLocation = '${city.trim()},${country.trim()}'.toLowerCase();
        final filteredEntries = prayerTimeEntries.where((row) {
          final dbLoc = (row['location'] as String).toLowerCase();
          return dbLoc == userLocation;
        }).toList();

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
      }

      if (mounted) {
        setState(() {
          _dataSource = EventDataSource(allAppointments);
        });
      }
    } catch (e) {
      // debugPrint('Error loading appointments: $e');
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

  void _showCategoryFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CategoryFilterDialog(
          categories: _allCategories,
          selectedCategoryIds: _selectedCategoryIds,
          onCategoriesSelected: (selectedIds) {
            setState(() {
              _selectedCategoryIds = selectedIds;
            });
            _saveSelectedCategoryIdsToPrefs();
            loadAllAppointments();
          },
          onCategoriesChanged: () {
            _loadAllCategories();
            // Cache leeren, damit die aktualisierten Kategoriefarben verwendet werden
            _adapter.clearCategoryCache();
            loadAllAppointments();
          },
        );
      },
    );
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

  void _handleViewChanged(CalendarView newView) {
    if (_selectedView == newView) return; // Keine Änderung nötig, wenn gleich

    // Zuerst merken wir uns die alte Ansicht, um Änderungen zu erkennen
    final oldView = _selectedView;

    setState(() {
      _selectedView = newView;

      // Synchronisiere _selectedNavIndex mit der neuen Ansicht
      if (newView == CalendarView.day) {
        _selectedNavIndex = 1;
      } else if (newView == CalendarView.week) {
        _selectedNavIndex = 2;
      } else if (newView == CalendarView.month) {
        _selectedNavIndex = 3;
      }
    });

    // Spezielles Handling für den Wechsel zur Monatsansicht
    // Wenn wir zur Monatsansicht wechseln, stellen wir sicher, dass keine Gebetszeiten angezeigt werden
    if (newView == CalendarView.month) {
      debugPrint("Wechsel zur Monatsansicht: Keine Gebetszeiten anzeigen");
      _showPrayerTimesInMonthView = false;
    }

    // UI aktualisieren und Termine neu laden - mit Verzögerung
    Future.microtask(() {
      loadAllAppointments();
    });
  }

  /// Zeigt ein Popup-Menü mit Synchronisationsoptionen an
  void _showSyncOptionsMenu(BuildContext context, RenderBox button) {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    // Dialog-Inhalt erstellen, der für beide Plattformen passt
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Google Kalender Option
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
            color: logoColor,
          ),
          title: localizations.googleCalendar,
          subtitle: localizations.syncImportExport,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context); // Dialog schließen
            _showGoogleSyncDialog(context);
          },
        ),

        // Outlook Option (deaktiviert)
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS
                ? CupertinoIcons.calendar_badge_plus
                : Icons.calendar_month,
            color: Colors.grey,
          ),
          title: localizations.outlookCalendar,
          subtitle: localizations.comingSoon,
          enabled: false, // Deaktiviert, da noch nicht implementiert
        ),
      ],
    );

    // Dialog-Aktionen erstellen
    final actions = [
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.cancel,
        onPressed: () => Navigator.pop(context),
        color: logoColor,
      ),
    ];

    // Plattformspezifischen Dialog anzeigen
    PlatformAdaptiveDialog.showAdaptiveDialog(
      context: context,
      title: 'Kalender Synchronisation',
      content: content,
      actions: actions,
    );
  }

  /// Zeigt einen Dialog mit Google Calendar Synchronisationsoptionen
  void _showGoogleSyncDialog(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    // Dialog-Inhalt erstellen, der für beide Plattformen passt
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vollständig synchronisieren
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.arrow_2_circlepath : Icons.sync,
            color: logoColor,
          ),
          title: localizations.fullSync,
          subtitle: localizations.importAndExport,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context);
            _performGoogleSync(context);
          },
        ),

        // Nur importieren
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.arrow_down_circle : Icons.download,
            color: logoColor,
          ),
          title: localizations.importOnly,
          subtitle: localizations.importFromGoogleCalendar,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context);
            _showImportOptionsDialog(context);
          },
        ),

        // Nur exportieren
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.arrow_up_circle : Icons.upload,
            color: logoColor,
          ),
          title: localizations.exportOnly,
          subtitle: localizations.exportToGoogleCalendar,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context);
            _performGoogleExport(context);
          },
        ),
      ],
    );

    // Dialog-Aktionen erstellen
    final actions = [
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.cancel,
        onPressed: () => Navigator.pop(context),
        color: logoColor,
      ),
    ];

    // Plattformspezifischen Dialog anzeigen
    PlatformAdaptiveDialog.showAdaptiveDialog(
      context: context,
      title: localizations.googleCalendar,
      content: content,
      actions: actions,
    );
  }

  /// Führt eine vollständige Synchronisation mit Google Calendar durch
  void _performGoogleSync(BuildContext context) async {
    // Referenzen speichern, bevor asynchrone Operationen beginnen
    final scaffold = ScaffoldMessenger.of(context);
    final localizations = Provider.of<AppLocalizations>(context, listen: false);
    final currentMounted = mounted;

    try {
      if (currentMounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text(localizations.syncingWithGoogleCalendar)),
        );
      }

      // Vollständige Synchronisation durchführen
      await _calendarSyncService.importAppointments(categoryOption: 0);
      await _calendarSyncService.exportAppointments();

      // Nach erfolgreicher Synchronisation Termine neu laden
      await loadAllAppointments();

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔄 Sync-Fehler: $e');

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncSyncError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Zeigt einen Dialog für Import-Optionen an
  void _showImportOptionsDialog(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    // Dialog-Inhalt erstellen, der für beide Plattformen passt
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformAdaptiveListTile(
          title: localizations.howToHandleCategories,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        // Bestehende Kategorien verwenden
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.tag : Icons.category_outlined,
            color: logoColor,
          ),
          title: localizations.useExistingCategories,
          subtitle: localizations.searchForMatchingCategories,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context);
            _performGoogleImport(context, categoryOption: 0);
          },
        ),

        // Neue Kategorien erstellen
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS
                ? CupertinoIcons.add_circled
                : Icons.add_circle_outline,
            color: logoColor,
          ),
          title: localizations.createNewCategories,
          subtitle: localizations.forEachNewAppointment,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () {
            Navigator.pop(context);
            _performGoogleImport(context, categoryOption: 1);
          },
        ),
      ],
    );

    // Dialog-Aktionen erstellen
    final actions = [
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.cancel,
        onPressed: () => Navigator.pop(context),
        color: logoColor,
      ),
    ];

    // Plattformspezifischen Dialog anzeigen
    PlatformAdaptiveDialog.showAdaptiveDialog(
      context: context,
      title: localizations.importOptions,
      content: content,
      actions: actions,
    );
  }

  /// Führt einen Import von Google Calendar durch
  void _performGoogleImport(BuildContext context,
      {required int categoryOption}) async {
    // Referenzen speichern, bevor asynchrone Operationen beginnen
    final scaffold = ScaffoldMessenger.of(context);
    final localizations = Provider.of<AppLocalizations>(context, listen: false);
    final currentMounted = mounted;

    try {
      if (currentMounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text(localizations.importingFromGoogleCalendar)),
        );
      }

      // Import durchführen
      await _calendarSyncService.importAppointments(
          categoryOption: categoryOption);

      // Nach erfolgreichem Import Termine neu laden
      await loadAllAppointments();

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncImportCompleted ??
                localizations.importCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔄 Import-Fehler: $e');

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.importError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Führt einen Export nach Google Calendar durch
  void _performGoogleExport(BuildContext context) async {
    // Referenzen speichern, bevor asynchrone Operationen beginnen
    final scaffold = ScaffoldMessenger.of(context);
    final localizations = Provider.of<AppLocalizations>(context, listen: false);
    final currentMounted = mounted;

    try {
      if (currentMounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text(localizations.exportingToGoogleCalendar)),
        );
      }

      // Export durchführen
      await _calendarSyncService.exportAppointments();

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncExportCompleted ??
                localizations.exportCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔄 Export-Fehler: $e');

      if (currentMounted) {
        scaffold.clearSnackBars(); // Bestehende Snackbars löschen
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.exportError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              onQiblaCompassPressed: () => _openQiblaCompass(),
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
      drawer: _buildDrawer(localizations),
      body: _selectedNavIndex == 0
          ? DashboardPage(
              key: const ValueKey('dashboard'),
              onStateCreated: (state) {
                _dashboardPageState = state;
              },
            )
          : CalendarViewWidget(
              selectedView: _selectedView,
              calendarController: _calendarController,
              dataSource: _dataSource,
              selectedDate: _selectedDate,
              use24hFormat: _use24hFormat,
              showPrayerTimesInDayView: _showPrayerTimesInDayView,
              showPrayerTimesInWeekView: _showPrayerTimesInWeekView,
              showPrayerTimesInMonthView: _showPrayerTimesInMonthView,
              languageCode:
                  _mapAppLanguageToCode(localizations.currentLanguage),
              onViewChanged: _handleViewChanged,
              onSelectedDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              onAppointmentsChanged: loadAllAppointments,
            ),
      floatingActionButton: _selectedNavIndex >= 1
          ? AddAppointmentFAB(
              selectedDate: _selectedDate,
              onAppointmentAdded: loadAllAppointments,
              logoColor: logoColor,
              localizations: localizations,
            )
          : null,
      bottomNavigationBar: HomeNavigationBar(
        selectedIndex: _selectedNavIndex,
        onIndexSelected: _handleNavigationChange,
        localizations: localizations,
      ),
    );
  }

  // Baut den Drawer mit den Menüoptionen
  Widget _buildDrawer(AppLocalizations loc) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerColor =
        isDark ? Colors.grey.shade800 : logoColor.withOpacity(0.1);
    final Color iconColor = logoColor;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Muslim Calendar',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : logoColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menü',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          // Einstellungen
          ListTile(
            leading: Icon(Icons.settings, color: iconColor),
            title: Text(loc.settings),
            onTap: () => _openSettings(),
          ),

          // Qibla Kompass
          ListTile(
            leading: Icon(Icons.explore, color: iconColor),
            title: const Text('Qibla Compass'),
            onTap: () => _openQiblaCompass(),
          ),

          // Kategorien
          ListTile(
            leading: Icon(Icons.category, color: iconColor),
            title: const Text('Kategorien'),
            onTap: () => _showCategoryFilterDialog(context),
          ),

          const Divider(),

          // Synchronisation
          ListTile(
            leading: Icon(Icons.sync, color: iconColor),
            title: const Text('Synchronisation'),
            onTap: () {
              Navigator.pop(context); // Drawer schließen
              final RenderBox box = context.findRenderObject() as RenderBox;
              _showSyncOptionsMenu(context, box);
            },
          ),

          // Weitere Trennlinie am Ende
          const Divider(),
        ],
      ),
    );
  }
}
