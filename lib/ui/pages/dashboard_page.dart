// lib/pages/dashboard.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Localization & Models
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/models/dashboard_task.dart';
import 'package:muslim_calendar/models/category_model.dart';

// Detailseite
import 'package:muslim_calendar/ui/pages/appointment_details_page.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';

// Andere Pages
import 'package:muslim_calendar/ui/pages/home_page.dart';
import 'package:muslim_calendar/ui/pages/settings_page.dart';
import 'package:muslim_calendar/ui/pages/qibla_compass_page.dart';

// Dashboard Widgets
import 'package:muslim_calendar/ui/widgets/dashboard/dashboard_content.dart';
import 'package:muslim_calendar/ui/widgets/home/category_filter_dialog.dart';

// Platform-Adaptive Komponenten
import 'package:muslim_calendar/ui/components/platform_adaptive_dialog.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_list_tile.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_app_bar.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_navigation.dart';

import 'package:muslim_calendar/data/services/prayer_time_service.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

class DashboardPage extends StatefulWidget {
  final Function(DashboardPageState)? onStateCreated;

  const DashboardPage({super.key, this.onStateCreated});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool _isWeatherLoading = false;
  bool _isPrayerTimesLoading = false;
  bool _isAppointmentsLoading = false;

  String? _weatherTemp;
  String? _weatherLocation;
  String? _weatherSymbol;
  String? _weatherErrorMessage;

  Map<String, String> _todayPrayerTimesDisplay = {};
  String? _prayerTimeErrorMessage;
  Map<PrayerTime, int?> _todayPrayerTimesMinutes = {};

  // Hier sammeln wir ausschließlich die heutigen Termine / Slots
  List<DashboardTask> _todayTasks = [];

  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  PrayerTimeService? _prayerTimeService;
  late CalendarSyncService _calendarSyncService;

  bool _use24hFormat = false;
  bool _showPrayerSlotsInDashboard = true;

  int? _hoveredTaskId;

  // Liste der Kategorien für den Kategoriefilter
  List<CategoryModel> _allCategories = [];
  Set<int> _selectedCategoryIds = {};

  // Variable für Reload-Tracking
  bool _isReloading = false;

  // Schlüssel für den Scaffold, um den Drawer zu öffnen
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initData();
    _loadAllCategories();

    // Callback zur Weitergabe der State-Referenz
    widget.onStateCreated?.call(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // CalendarSyncService registrieren
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);

    // PrayerTimeService als Listener registrieren
    if (_prayerTimeService != null) {
      _prayerTimeService!.removeListener(_onPrayerTimesChanged);
    }
    _prayerTimeService = Provider.of<PrayerTimeService>(context, listen: false);
    _prayerTimeService!.addListener(_onPrayerTimesChanged);

    // Listener hinzufügen, um auf Kategorieänderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);
    if (_prayerTimeService != null) {
      _prayerTimeService!.removeListener(_onPrayerTimesChanged);
    }
    super.dispose();
  }

  // Wird aufgerufen, wenn sich die Gebetszeiten ändern
  void _onPrayerTimesChanged() {
    if (!mounted) return;

    debugPrint(
        "🕌 DashboardPage: Gebetszeiten wurden geändert, lade Daten neu...");
    reloadData();
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    if (!mounted) return;

    debugPrint(
        "🔄 DashboardPage: Kategorien wurden geändert, lade Termine neu...");
    _loadAllCategories();
    reloadData();
  }

  /// Ermöglicht Reload von außen
  Future<void> reloadData() async {
    // Verhindere mehrfache gleichzeitige Aufrufe
    if (_isReloading) return;
    _isReloading = true;

    // Verzögere die Ausführung um setState-Aufrufe während des Build-Prozesses zu vermeiden
    await Future.microtask(() async {
      try {
        if (mounted) {
          await _initData();
        }
      } catch (e) {
        debugPrint("Fehler bei reloadData: $e");
        // Stille Fehlerbehandlung, damit die App nicht abstürzt
      } finally {
        _isReloading = false;
      }
    });
  }

  /// Lädt alle Kategorien für den Kategoriefilter
  Future<void> _loadAllCategories() async {
    final cats = await _categoryRepo.getAllCategories();
    setState(() {
      _allCategories = cats;
      _selectedCategoryIds = cats.map((e) => e.id!).toSet();
    });
  }

  /// Speichert die ausgewählten Kategorien in SharedPreferences.
  Future<void> _saveSelectedCategoryIdsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final catList = _selectedCategoryIds.map((id) => id.toString()).toList();
    await prefs.setStringList('selectedCategoryIds', catList);
  }

  /// Öffnet die Einstellungsseite
  Future<void> _openSettings() async {
    // Schließe den Drawer, falls er offen ist
    Navigator.pop(context);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    // Einstellungen neu laden
    final prefs = await SharedPreferences.getInstance();
    _use24hFormat = prefs.getBool('use24hFormat') ?? false;
    _showPrayerSlotsInDashboard =
        prefs.getBool('showPrayerSlotsInDashboard') ?? true;

    // Daten neu laden
    await reloadData();

    // HomePage aktualisieren falls nötig
    final homePageState = context.findAncestorStateOfType<HomePageState>();
    homePageState?.loadAllAppointments();
  }

  /// Öffnet den Qibla-Kompass
  Future<void> _openQiblaCompass() async {
    // Schließe den Drawer, falls er offen ist
    Navigator.pop(context);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QiblaCompassPage()),
    );
  }

  /// Zeigt den Dialog zum Filtern nach Kategorien an
  void _showCategoryFilterDialog(BuildContext context) {
    // Schließe den Drawer, falls er offen ist
    Navigator.pop(context);

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

            // Daten neu laden
            reloadData();

            // HomePage aktualisieren falls nötig
            final homePageState =
                context.findAncestorStateOfType<HomePageState>();
            homePageState?.loadAllAppointments();
          },
          onCategoriesChanged: () {
            _loadAllCategories();
            reloadData();
          },
        );
      },
    );
  }

  /// Zeigt das Synchronisationsmenü an
  void _showSyncOptionsDialog(BuildContext context) {
    // Schließe den Drawer, falls er offen ist
    Navigator.pop(context);

    final localizations = Provider.of<AppLocalizations>(context, listen: false);
    final scaffold = ScaffoldMessenger.of(context);

    final Color iconColor = logoColor;

    // Dialog-Inhalt erstellen, der für beide Plattformen passt
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vollständig synchronisieren
        PlatformAdaptiveListTile(
          leading: Icon(
              Platform.isIOS ? CupertinoIcons.arrow_2_circlepath : Icons.sync,
              color: iconColor),
          title: localizations.fullSync,
          subtitle: localizations.importAndExport,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);

            try {
              // Fortschritt anzeigen
              scaffold.showSnackBar(
                SnackBar(
                    content: Text(localizations.syncingWithGoogleCalendar)),
              );

              // Vollständige Synchronisation durchführen
              await _calendarSyncService.importAppointments(categoryOption: 0);
              await _calendarSyncService.exportAppointments();

              // Nach erfolgreicher Synchronisation neu laden
              await reloadData();

              // Auch HomePage aktualisieren falls nötig
              final homePageState =
                  context.findAncestorStateOfType<HomePageState>();
              homePageState?.loadAllAppointments();

              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.syncCompleted),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              debugPrint('Sync-Fehler: $e');
              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.syncSyncError(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),

        // Nur importieren
        PlatformAdaptiveListTile(
          leading: Icon(
              Platform.isIOS
                  ? CupertinoIcons.arrow_down_circle
                  : Icons.download,
              color: iconColor),
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
              color: iconColor),
          title: localizations.exportOnly,
          subtitle: localizations.exportToGoogleCalendar,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);

            try {
              // Fortschritt anzeigen
              scaffold.showSnackBar(
                SnackBar(
                    content: Text(localizations.exportingToGoogleCalendar)),
              );

              // Export durchführen
              await _calendarSyncService.exportAppointments();

              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.syncExportCompleted ??
                      localizations.exportCompleted),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              debugPrint('Export-Fehler: $e');
              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.exportError(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
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

  /// Zeigt einen Dialog für Import-Optionen an
  void _showImportOptionsDialog(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);
    final scaffold = ScaffoldMessenger.of(context);

    final Color iconColor = logoColor;

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
              color: iconColor),
          title: localizations.useExistingCategories,
          subtitle: localizations.searchForMatchingCategories,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);

            try {
              // Fortschritt anzeigen
              scaffold.showSnackBar(
                SnackBar(
                    content: Text(localizations.importingFromGoogleCalendar)),
              );

              // Import durchführen mit Option: bestehende Kategorien verwenden
              await _calendarSyncService.importAppointments(categoryOption: 0);

              // Nach erfolgreichem Import neu laden
              await reloadData();

              // Auch HomePage aktualisieren falls nötig
              final homePageState =
                  context.findAncestorStateOfType<HomePageState>();
              homePageState?.loadAllAppointments();

              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.syncImportCompleted ??
                      localizations.importCompleted),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              debugPrint('Import-Fehler: $e');
              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.importError(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),

        // Neue Kategorien erstellen
        PlatformAdaptiveListTile(
          leading: Icon(
              Platform.isIOS
                  ? CupertinoIcons.add_circled
                  : Icons.add_circle_outline,
              color: iconColor),
          title: localizations.createNewCategories,
          subtitle: localizations.forEachNewAppointment,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);

            try {
              // Fortschritt anzeigen
              scaffold.showSnackBar(
                SnackBar(
                    content: Text(localizations.importingFromGoogleCalendar)),
              );

              // Import durchführen mit Option: neue Kategorien erstellen
              await _calendarSyncService.importAppointments(categoryOption: 1);

              // Nach erfolgreichem Import neu laden
              await reloadData();

              // Auch HomePage aktualisieren falls nötig
              final homePageState =
                  context.findAncestorStateOfType<HomePageState>();
              homePageState?.loadAllAppointments();

              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.syncImportCompleted ??
                      localizations.importCompleted),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              debugPrint('Import-Fehler: $e');
              scaffold.clearSnackBars();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(localizations.importError(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
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

  /// Lädt alle Daten für das Dashboard: Wetter, Gebetszeiten, heutige Termine
  Future<void> _initData() async {
    if (!mounted) return;

    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    await initializeDateFormatting(languageCode, null);

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    final prefs = await SharedPreferences.getInstance();
    _use24hFormat = prefs.getBool('use24hFormat') ?? false;
    _showPrayerSlotsInDashboard =
        prefs.getBool('showPrayerSlotsInDashboard') ?? true;

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    setState(() {
      _isWeatherLoading = true;
      _isPrayerTimesLoading = true;
      _isAppointmentsLoading = true;
    });

    final defaultCountry = prefs.getString('defaultCountry') ?? 'Turkey';
    final defaultCity = prefs.getString('defaultCity') ?? 'Istanbul';
    final locationString = '$defaultCity,$defaultCountry';

    // 1) Wetter
    await _fetchWeather(defaultCity);

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    // 2) Gebetszeiten
    await _fetchPrayerTimesForToday(locationString);

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    // 3) Nur heutige Termine
    await _loadTodayAppointments();

    if (!mounted) return;

    setState(() {});
  }

  /// Wetter abrufen
  Future<void> _fetchWeather(String city) async {
    if (!mounted) return; // Sicherheitsprüfung am Anfang

    setState(() {
      _isWeatherLoading = true;
      _weatherErrorMessage = null;
    });

    const apiKey = 'ea71a51c210c3fa6760039a8b592c19c';
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Netzwerk-Timeout beim Abrufen der Wetterdaten');
        },
      );

      if (!mounted) return; // Wichtige Prüfung nach asynchronem Aufruf

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final temp = jsonData['main']['temp'];
        final tempStr = '${temp.toStringAsFixed(1)}°C';

        final mainCondition =
            (jsonData['weather'] != null && jsonData['weather'].isNotEmpty)
                ? (jsonData['weather'][0]['main'] as String?) ?? ''
                : '';

        final symbol = _mapWeatherSymbol(mainCondition);

        setState(() {
          _weatherTemp = tempStr;
          _weatherSymbol = symbol;
          _weatherLocation = city;
          _weatherErrorMessage = null;
          _isWeatherLoading = false;
        });
      } else {
        setState(() {
          _weatherErrorMessage = 'Weather error: ${response.statusCode}';
          _isWeatherLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Wichtige Prüfung vor setState im catch-Block

      setState(() {
        _weatherErrorMessage =
            'Weather error:\nClientException with SocketException:\nFailed host lookup: \'openweathermap.org\'';
        _isWeatherLoading = false;
      });
    }
  }

  /// Gebetszeiten nur für HEUTE
  Future<void> _fetchPrayerTimesForToday(String location) async {
    if (!mounted) return; // Sicherheitsprüfung am Anfang

    setState(() {
      _isPrayerTimesLoading = true;
      _prayerTimeErrorMessage = null;
    });

    final now = DateTime.now();
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    try {
      final fajr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.fajr);
      final dhuhr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.dhuhr);
      final asr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.asr);
      final maghrib = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.maghrib);
      final isha = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.isha);

      if (!mounted) return; // Wichtige Prüfung nach asynchronen Aufrufen

      _todayPrayerTimesDisplay = {
        loc.getPrayerTimeLabel(PrayerTime.fajr):
            _formatTimeFromMinutes(fajr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.dhuhr):
            _formatTimeFromMinutes(dhuhr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.asr):
            _formatTimeFromMinutes(asr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.maghrib):
            _formatTimeFromMinutes(maghrib ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.isha):
            _formatTimeFromMinutes(isha ?? -1),
      };

      _todayPrayerTimesMinutes = {
        PrayerTime.fajr: fajr,
        PrayerTime.dhuhr: dhuhr,
        PrayerTime.asr: asr,
        PrayerTime.maghrib: maghrib,
        PrayerTime.isha: isha,
      };

      setState(() {
        _prayerTimeErrorMessage = null;
        _isPrayerTimesLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Wichtige Prüfung vor setState im catch-Block

      setState(() {
        _prayerTimeErrorMessage =
            'Error fetching prayer times:\nClientException with SocketException:\nFailed host lookup: \'api.aladhan.com\'';
        _isPrayerTimesLoading = false;
      });
    }
  }

  /// **Nur** die Termine des heutigen Tages laden
  Future<void> _loadTodayAppointments() async {
    if (!mounted) return; // Sicherheitsprüfung am Anfang

    setState(() {
      _isAppointmentsLoading = true;
    });

    // Locale für Datumsformatierung
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    await initializeDateFormatting(
        _mapAppLanguageToCode(loc.currentLanguage), null);

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    final now = DateTime.now();
    // Start und Ende des heutigen Tages (bis 23:59)
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    final all = await _appointmentRepo.getAllAppointments();

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    final tasks = <DashboardTask>[];

    // Lade alle Kategorien einmalig
    final allCategories = await _categoryRepo.getAllCategories();

    if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

    // Map für schnelleren Zugriff nach ID
    final Map<int, Color> categoryColors = {};
    for (var category in allCategories) {
      if (category.id != null) {
        categoryColors[category.id!] = category.color;
      }
    }

    // Set zum Nachverfolgen bereits hinzugefügter Termine, um Duplikate zu vermeiden
    final Set<int?> addedAppointmentIds = {};

    // 1) Normale Termine
    for (var ap in all) {
      if (!mounted) return; // Regelmäßige Überprüfung in der Schleife

      // Überspringe Termine ohne ID oder mit leeren Titeln
      if (ap.id == null || ap.subject.trim().isEmpty) {
        continue;
      }

      // Überspringe Termine, die bereits hinzugefügt wurden
      if (addedAppointmentIds.contains(ap.id)) {
        continue;
      }

      try {
        // Berechnete Start-/Endzeit (für Gebetszeitabhängige Termine)
        final calculatedStart = await _prayerTimeService!
            .getCalculatedStartTime(ap, DateTime.now(),
                useAppointmentDate: true);

        if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

        final start = calculatedStart ?? (ap.startTime ?? now);

        final calculatedEnd =
            await _prayerTimeService!.getCalculatedEndTime(ap, now);

        if (!mounted) return; // Prüfung nach dem asynchronen Aufruf

        final end = calculatedEnd ??
            (ap.endTime ?? start.add(const Duration(minutes: 30)));

        // BUGFIX: Zeige nur Termine an, die tatsächlich am heutigen Tag beginnen
        if (start.year == now.year &&
            start.month == now.month &&
            start.day == now.day) {
          final diff = end.difference(start).inMinutes;
          final desc = ap.notes ?? '';

          // Neues DashboardTask-Model verwenden
          final task = DashboardTask(
            appointmentId: ap.id,
            isPrayerSlot: false,
            title: ap.subject,
            start: start,
            end: end,
            durationInMinutes: diff,
            description: desc,
            color: categoryColors[ap.categoryId] ?? Colors.grey,
            isAllDay: ap.isAllDay, // WICHTIG
          );

          // Formatierte Zeiten setzen
          task.setFormattedTimes(_formatDateTime(start), _formatDateTime(end));

          tasks.add(task);

          // Termin als hinzugefügt markieren
          addedAppointmentIds.add(ap.id);
        }
      } catch (e) {
        debugPrint("Fehler beim Laden des Termins ${ap.id}: $e");
        // Continue with next appointment
        continue;
      }
    }

    // 2) Gebetszeiten-Slots (falls gewünscht)
    if (_showPrayerSlotsInDashboard) {
      final baseDay = DateTime(now.year, now.month, now.day);
      for (final entry in _todayPrayerTimesMinutes.entries) {
        final prayerTime = entry.key;
        final minutes = entry.value;
        if (minutes == null || minutes < 0) continue;

        final dtStart = baseDay.add(Duration(minutes: minutes));
        // Prüfen, ob sie wirklich in den Tag fällt
        if (dtStart.isBefore(startOfDay) || dtStart.isAfter(endOfDay)) {
          continue;
        }

        final dtEnd = dtStart.add(const Duration(minutes: 1));

        // Neues DashboardTask-Model verwenden
        final task = DashboardTask(
          appointmentId: null,
          isPrayerSlot: true,
          title: loc.getPrayerTimeLabel(prayerTime),
          start: dtStart,
          end: dtEnd,
          durationInMinutes: 1,
          description: '',
          color: Colors.teal,
          isAllDay: false,
        );

        // Formatierte Zeit setzen
        task.setFormattedTimes(
            _formatDateTime(dtStart), _formatDateTime(dtEnd));

        tasks.add(task);
      }
    }

    // **Neuer Sortiermechanismus**:
    //  1) All-Day nach oben
    //  2) Sonst nach Startzeit
    tasks.sort((a, b) {
      // All-Day => ganz oben
      if (a.isAllDay && !b.isAllDay) return -1;
      if (!a.isAllDay && b.isAllDay) return 1;
      // Falls beide allDay oder beide normal => sortiere nach Zeit
      return a.start.compareTo(b.start);
    });

    if (!mounted) return; // Letzte Prüfung vor setState

    setState(() {
      _todayTasks = tasks;
      _isAppointmentsLoading = false;
    });
  }

  String _formatTimeFromMinutes(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes < 0) {
      return '--:--';
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

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

  String _mapWeatherSymbol(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain')) {
      return '🌧';
    } else if (lower.contains('cloud')) {
      return '☁';
    } else if (lower.contains('clear')) {
      return '☀';
    } else if (lower.contains('snow')) {
      return '❄';
    } else {
      return '🌤';
    }
  }

  void _createQuickAppointment() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AppointmentCreationPage(),
      ),
    );
    if (result == true) {
      // Lokales Reload
      await reloadData();
      // + Kalender in der HomePage updaten
      final homePageState = context.findAncestorStateOfType<HomePageState>();
      homePageState?.loadAllAppointments();
    }
  }

  // Callback für das Hover-Event
  void _onHoverEnter(int taskId) {
    setState(() {
      _hoveredTaskId = taskId;
    });
  }

  // Callback für das Ende des Hover-Events
  void _onHoverExit(int taskId) {
    setState(() {
      if (_hoveredTaskId == taskId) {
        _hoveredTaskId = null;
      }
    });
  }

  // Callback für das Tippen auf einen Task
  Future<void> _onTaskTap(int appointmentId) async {
    // Termin-Details öffnen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AppointmentDetailsPage(
          appointmentId: appointmentId,
        ),
      ),
    );

    // Daten neu laden
    reloadData();

    // Auch HomePage aktualisieren
    final homePageState = context.findAncestorStateOfType<HomePageState>();
    homePageState?.loadAllAppointments();
  }

  String _formatDateTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
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
                  loc.appTitle,
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
            title: Text(loc.qiblaCompass),
            onTap: () => _openQiblaCompass(),
          ),

          // Kategorien
          ListTile(
            leading: Icon(Icons.category, color: iconColor),
            title: Text(loc.categoryLabel),
            onTap: () => _showCategoryFilterDialog(context),
          ),

          const Divider(),

          // Synchronisation
          ListTile(
            leading: Icon(Icons.sync, color: iconColor),
            title: Text(loc.synchronization),
            onTap: () => _showSyncOptionsDialog(context),
          ),

          // Weitere Trennlinie am Ende
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final now = DateTime.now();

    final dateFormatter =
        DateFormat('d MMMM yyyy', _mapAppLanguageToCode(loc.currentLanguage));
    final weekdayFormatter =
        DateFormat('EEEE', _mapAppLanguageToCode(loc.currentLanguage));
    final dateString = dateFormatter.format(now);
    final weekdayString = weekdayFormatter.format(now);

    final Color mainColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PlatformAdaptiveAppBar(
        title: loc.dashboard,
        leading: Icon(
          Platform.isIOS ? CupertinoIcons.line_horizontal_3 : Icons.menu,
        ),
        onLeadingPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        centerTitle: Platform.isIOS, // Auf iOS zentrieren, auf Android links
      ),
      drawer: _buildDrawer(loc),
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: _createQuickAppointment,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: DashboardContent(
          // Datum
          dateString: dateString,
          weekdayString: weekdayString,

          // Wetter
          weatherTemp: _weatherTemp,
          weatherLocation: _weatherLocation,
          weatherSymbol: _weatherSymbol,
          weatherErrorMessage: _weatherErrorMessage,
          isWeatherLoading: _isWeatherLoading,

          // Gebetszeiten
          prayerTimesDisplay: _todayPrayerTimesDisplay,
          prayerTimeErrorMessage: _prayerTimeErrorMessage,
          isPrayerTimesLoading: _isPrayerTimesLoading,

          // Aufgaben/Termine
          todayTasks: _todayTasks,
          isTasksLoading: _isAppointmentsLoading,
          hoveredTaskId: _hoveredTaskId,

          // Callbacks
          onHoverEnter: _onHoverEnter,
          onHoverExit: _onHoverExit,
          onTaskTap: _onTaskTap,
        ),
      ),
    );
  }
}
