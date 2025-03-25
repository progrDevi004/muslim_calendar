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
import 'package:Taqvimi/ui/components/platform_adaptive_navigation.dart';
import 'package:Taqvimi/ui/components/app_drawer.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_scaffold_fab.dart';

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
import 'package:Taqvimi/ui/pages/qibla_compass_page.dart';
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

  // Referenz auf den PrayerTimeService hinzufügen
  PrayerTimeService? _prayerTimeService;

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

      // Prüfen, ob die Import-Option bereits gesetzt wurde
      _checkImportSettingsInitialized();

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
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _prayerTimeService!.addListener(_onPrayerTimesChanged);

    // Listener hinzufügen, um auf Kategorieänderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);

    // PrayerTimeService Listener entfernen
    _prayerTimeService!.removeListener(_onPrayerTimesChanged);

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
        // Nur Termine der ausgewählten Kategorien hinzufügen
        if (appointment.categoryId != null &&
            _selectedCategoryIds.contains(appointment.categoryId)) {
          final appointmentList = await _adapter.getAppointmentsForRange(
            appointment,
            DateTime.now().subtract(const Duration(days: 365)),
            DateTime.now().add(const Duration(days: 365)),
          );
          allAppointments.addAll(appointmentList);
        }
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
    // Wichtig: Längere Verzögerung hinzufügen, um Fokus-Probleme zu vermeiden
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Explizit den aktuellen Fokus zurücksetzen
      FocusManager.instance.primaryFocus?.unfocus();

      // WidgetsBinding verwenden, um sicherzustellen, dass der Fokus-Reset abgeschlossen ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final localizations =
            Provider.of<AppLocalizations>(context, listen: false);

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
      });
    });
  }

  /// Zeigt einen Dialog mit Google Calendar Synchronisationsoptionen
  void _showGoogleSyncDialog(BuildContext context) {
    // Wichtig: Längere Verzögerung hinzufügen, um Fokus-Probleme zu vermeiden
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Explizit den aktuellen Fokus zurücksetzen
      FocusManager.instance.primaryFocus?.unfocus();

      // WidgetsBinding verwenden, um sicherzustellen, dass der Fokus-Reset abgeschlossen ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final localizations =
            Provider.of<AppLocalizations>(context, listen: false);

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
                Platform.isIOS
                    ? CupertinoIcons.arrow_down_circle
                    : Icons.download,
                color: logoColor,
              ),
              title: localizations.importOnly,
              subtitle: localizations.importFromCalendar,
              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
              onTap: () {
                Navigator.pop(context);
                _performGoogleImport(context);
              },
            ),

            // Nur exportieren
            PlatformAdaptiveListTile(
              leading: Icon(
                Platform.isIOS ? CupertinoIcons.arrow_up_circle : Icons.upload,
                color: logoColor,
              ),
              title: localizations.exportOnly,
              subtitle: localizations.exportToCalendar,
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
      });
    });
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

      // Vollständige Synchronisation durchführen ohne expliziten categoryOption-Wert,
      // damit die gespeicherte Option aus den SharedPreferences verwendet wird
      await _calendarSyncService.syncGoogleCalendarNow();

      // Nach erfolgreicher Synchronisation Termine neu laden
      await loadAllAppointments();

      if (currentMounted) {
        scaffold.clearSnackBars();
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync-Fehler: $e');

      if (currentMounted) {
        scaffold.clearSnackBars();
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.syncSyncError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Führt einen direkten Import ohne weitere Dialogabfrage durch
  /// Verwendet die bereits gespeicherte Import-Option, die gleiche Funktion wie bei der vollständigen Synchronisation
  void _performGoogleImport(BuildContext context) async {
    debugPrint("📥 HomePage: Google Import gestartet");

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

      debugPrint(
          "📥 Starte importAppointments über den CalendarSyncService...");
      // Import durchführen mit der zentral gespeicherten Option
      // Verwendet die gleiche Logik wie die vollständige Synchronisationsfunktion
      await _calendarSyncService.importAppointments();
      debugPrint("📥 importAppointments abgeschlossen");

      // Nach erfolgreichem Import Termine neu laden
      await loadAllAppointments();
      debugPrint("📥 Termine wurden neu geladen");

      if (currentMounted) {
        scaffold.clearSnackBars();
        scaffold.showSnackBar(
          SnackBar(
            content: Text(localizations.importCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        debugPrint("📥 Import erfolgreich abgeschlossen");
      }
    } catch (e) {
      debugPrint('🔄 Import-Fehler: $e');

      if (currentMounted) {
        scaffold.clearSnackBars();
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

  /// Prüft, ob die Import-Option bereits initialisiert wurde und zeigt ggf. eine Abfrage an
  Future<void> _checkImportSettingsInitialized() async {
    final importOption = await ImportSettingsService.getImportOption();
    final hasBeenInitialized = await _hasImportOptionBeenInitialized();

    // Wenn wir noch keine Import-Option gespeichert haben oder diese noch nicht
    // explizit initialisiert wurde, zeigen wir den Dialog an
    if (!hasBeenInitialized) {
      if (mounted) {
        // Warte kurz, damit die UI vollständig geladen ist
        await Future.delayed(const Duration(milliseconds: 500));
        // Dialog anzeigen
        _showInitialImportOptionsDialog(context);
      }
    }
  }

  /// Prüft, ob die Import-Option bereits explizit initialisiert wurde
  Future<bool> _hasImportOptionBeenInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('import_option_initialized') ?? false;
  }

  /// Markiert die Import-Option als initialisiert
  Future<void> _markImportOptionAsInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('import_option_initialized', true);
  }

  /// Zeigt den initialen Dialog für Import-Optionen an (nur bei erster App-Nutzung)
  void _showInitialImportOptionsDialog(BuildContext context) {
    debugPrint("HomePage: Initialer Import-Options-Dialog wird angezeigt");

    // Wichtig: Längere Verzögerung hinzufügen, um Fokus-Probleme zu vermeiden
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Explizit den aktuellen Fokus zurücksetzen
      FocusManager.instance.primaryFocus?.unfocus();

      // WidgetsBinding verwenden, um sicherzustellen, dass der Fokus-Reset abgeschlossen ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final localizations =
            Provider.of<AppLocalizations>(context, listen: false);

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
              title: localizations.useGoogleCalendarCategories,
              subtitle: localizations.searchForMatchingCategories,
              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
              onTap: () async {
                Navigator.pop(context);
                // Option 2 = Kalendernamen als Kategorien verwenden
                await ImportSettingsService.saveImportOption(2);
                await _markImportOptionAsInitialized();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.importOptionSaved)),
                  );
                  debugPrint(
                      "🛠️ Import-Option 2 gespeichert und initialisiert");
                }
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
              title: localizations.useDefaultCategory,
              subtitle: localizations.importedAppointmentsToDefaultCategory,
              titleStyle: const TextStyle(fontWeight: FontWeight.bold),
              onTap: () async {
                Navigator.pop(context);
                // Option 0 = Standardkategorie verwenden
                await ImportSettingsService.saveImportOption(0);
                await _markImportOptionAsInitialized();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.importOptionSaved)),
                  );
                  debugPrint(
                      "🛠️ Import-Option 0 gespeichert und initialisiert");
                }
              },
            ),
          ],
        );

        // Dialog-Aktionen erstellen
        final actions = [
          PlatformAdaptiveDialog.adaptiveDialogAction(
            context: context,
            text: localizations.cancel,
            onPressed: () {
              Navigator.pop(context);
              // Bei Abbruch trotzdem als initialisiert markieren (Option 0 standardmäßig verwenden)
              _markImportOptionAsInitialized();
            },
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
      });
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
      ),
    );
  }
}
