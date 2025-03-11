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

  // Dezenter Farbton für Gebetszeiten (BlueGrey 300)
  static const Color _prayerTimeColor = Color(0xFF90A4AE);

  // Flags aus den Settings (für Daily/Weekly und ggf. Dashboard-Gebetszeiten)
  bool _showPrayerSlotsInDashboard = true;
  bool _showPrayerTimesInDayView = true;
  bool _showPrayerTimesInWeekView = true;
  bool _showPrayerTimesInMonthView = true;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController();
    _selectedNavIndex = 0; // Standard: Dashboard

    // Standardmäßig heute auswählen
    _selectedDate = DateTime.now();
    _calendarController.selectedDate = _selectedDate;
    _calendarController.displayDate = _selectedDate;

    _updateCalendarViewFromNavIndex();
    _loadUserPrefs();
    _loadAllCategories();
    _fetchYearlyPrayerTimesIfNeeded().then((_) {
      loadAllAppointments();
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
    setState(() {
      _use24hFormat = prefs.getBool('use24hFormat') ?? false;
      _showPrayerSlotsInDashboard =
          prefs.getBool('showPrayerSlotsInDashboard') ?? true;
      _showPrayerTimesInDayView =
          prefs.getBool('showPrayerTimesInDayView') ?? true;
      _showPrayerTimesInWeekView =
          prefs.getBool('showPrayerTimesInWeekView') ?? true;
      // In der Monatsansicht sollen keine Gebetszeiten angezeigt werden.
      _showPrayerTimesInMonthView = false;
    });
  }

  /// Prüft, ob bereits das ganze Jahr an Gebetszeiten gespeichert wurde.
  Future<void> _fetchYearlyPrayerTimesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('defaultCountry');
    final city = prefs.getString('defaultCity');
    if (country == null || city == null) return;
    final location = '${city.trim()},${country.trim()}'.toLowerCase();
    final now = DateTime.now();
    await _prayerTimeRepo.fetchAndSaveYearlyPrayerTimes(now.year, location);
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
    _calendarController.view = _selectedView;
    setState(() {});
    if (_selectedNavIndex != 0) {
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
      final models = await _appointmentRepo.getAllAppointments();
      final now = DateTime.now();

      // Korrigierte Datumsberechnung mit addMonths
      final startRange = addMonths(DateTime(now.year, now.month, 1), -2);
      final endRange = addMonths(DateTime(now.year, now.month, 1), 3);

      // Debug-Ausgabe für den Datumsbereich
      debugPrint("📅 Lade Termine im Bereich: $startRange bis $endRange");

      final List<Appointment> allAppointments = [];

      // Debug-Ausgabe für verfügbare Kategorien und Termine
      debugPrint("🏷️ Verfügbare Kategorien: $_selectedCategoryIds");
      for (var m in models) {
        debugPrint(
            "📄 Termin ${m.id}: ${m.subject}, Kategorie: ${m.categoryId}, Datum: ${m.startTime}");
      }

      // 1) Normale Appointments
      try {
        for (var m in models) {
          if (m.categoryId == null ||
              _selectedCategoryIds.contains(m.categoryId)) {
            debugPrint("✅ Termin wird angezeigt: ${m.id} - ${m.subject}");
            try {
              final apps = await _adapter.getAppointmentsForRange(
                  m, startRange, endRange);
              allAppointments.addAll(apps);
            } catch (e) {
              debugPrint(
                  "⚠️ Fehler beim Laden des Termins ${m.subject} (ID: ${m.id}): $e");

              // Wenn der Fehler den String "Invalid weekly recurrence rule" enthält
              if (e.toString().contains("Invalid weekly recurrence rule") &&
                  m.recurrenceRule != null) {
                debugPrint(
                    "🔍 Gefunden: Ungültige wöchentliche Wiederholungsregel in Termin ${m.id}: ${m.recurrenceRule}");

                // Überprüfen, ob die Regel BYDAY enthält
                if (!m.recurrenceRule!.contains("BYDAY=")) {
                  // Automatisch BYDAY-Parameter hinzufügen basierend auf dem Startdatum
                  String weekday = 'MO'; // Standardwert
                  if (m.startTime != null) {
                    switch (m.startTime!.weekday) {
                      case DateTime.monday:
                        weekday = 'MO';
                        break;
                      case DateTime.tuesday:
                        weekday = 'TU';
                        break;
                      case DateTime.wednesday:
                        weekday = 'WE';
                        break;
                      case DateTime.thursday:
                        weekday = 'TH';
                        break;
                      case DateTime.friday:
                        weekday = 'FR';
                        break;
                      case DateTime.saturday:
                        weekday = 'SA';
                        break;
                      case DateTime.sunday:
                        weekday = 'SU';
                        break;
                    }
                  }

                  String correctedRule = m.recurrenceRule!;
                  if (correctedRule.contains('UNTIL=')) {
                    correctedRule = correctedRule.replaceFirst(
                        'UNTIL=', 'BYDAY=$weekday;UNTIL=');
                  } else {
                    correctedRule = '$correctedRule;BYDAY=$weekday';
                  }

                  debugPrint(
                      "🛠️ Korrigiere Termin ${m.id} mit neuer Regel: $correctedRule");

                  // Korrigierte Regel speichern
                  AppointmentModel updatedAppointment =
                      m.copyWith(recurrenceRule: correctedRule);

                  await _appointmentRepo.updateAppointment(updatedAppointment);
                }
              }
            }
          } else {
            debugPrint(
                "⛔ Termin wird GEFILTERT: ${m.id} - ${m.subject} - (Kat: ${m.categoryId})");
          }
        }
      } catch (error) {
        debugPrint("⚠️ Fehler beim Laden der Termine: $error");

        // Zeige Dialog mit Optionen zur Fehlerbehebung an
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Fehler beim Laden der Termine"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Es gab ein Problem beim Laden Ihrer Termine. Dies kann durch ungültige Wiederholungsregeln verursacht werden.",
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Fehlermeldung:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    error.toString(),
                    style:
                        const TextStyle(fontFamily: "monospace", fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Schließen"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  child: const Text("Zu den Einstellungen"),
                ),
              ],
            ),
          );
        }
      }

      // 2) Gebetszeiten
      bool addPrayers = true;
      if (_selectedView == CalendarView.day && !_showPrayerTimesInDayView) {
        addPrayers = false;
      } else if (_selectedView == CalendarView.week &&
          !_showPrayerTimesInWeekView) {
        addPrayers = false;
      } else if (_selectedView == CalendarView.month) {
        addPrayers = false;
      }

      if (addPrayers && _selectedNavIndex != 0) {
        final prayerTimeEntries = await _prayerTimeRepo.getPrayerTimesInRange(
          startRange,
          endRange,
        );
        final prefs = await SharedPreferences.getInstance();
        final country = prefs.getString('defaultCountry');
        final city = prefs.getString('defaultCity');
        if (country != null && city != null) {
          final userLocation = '${city.trim()},${country.trim()}'.toLowerCase();
          final filteredEntries = prayerTimeEntries.where((row) {
            final dbLoc = (row['location'] as String).toLowerCase();
            return dbLoc == userLocation;
          }).toList();
          for (var row in filteredEntries) {
            final dateStr = row['date'].toString();
            final parts = dateStr.split('-');
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            final baseDay = DateTime(year, month, day);
            Appointment? createPrayerAppointment(String name, int? minutes) {
              if (minutes == null) return null;
              final start = baseDay.add(Duration(minutes: minutes));
              final end = start.add(const Duration(minutes: 15));
              return Appointment(
                id: 'prayer_${name}_${baseDay.toIso8601String()}',
                subject: name,
                notes: 'prayerTime',
                startTime: start,
                endTime: end,
                isAllDay: false,
                color: _prayerTimeColor,
              );
            }

            final fajrApp =
                createPrayerAppointment('Fajr', _toInt(row['fajr']));
            if (fajrApp != null) allAppointments.add(fajrApp);
            final dhuhrApp =
                createPrayerAppointment('Dhuhr', _toInt(row['dhuhr']));
            if (dhuhrApp != null) allAppointments.add(dhuhrApp);
            final asrApp = createPrayerAppointment('Asr', _toInt(row['asr']));
            if (asrApp != null) allAppointments.add(asrApp);
            final maghribApp =
                createPrayerAppointment('Maghrib', _toInt(row['maghrib']));
            if (maghribApp != null) allAppointments.add(maghribApp);
            final ishaApp =
                createPrayerAppointment('Isha', _toInt(row['isha']));
            if (ishaApp != null) allAppointments.add(ishaApp);
          }
        }
      }
      setState(() {
        _dataSource = EventDataSource(allAppointments);
      });
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    if (_selectedNavIndex == 0) {
      _dashboardKey.currentState?.reloadData();
    }
    await _loadUserPrefs();
    await loadAllAppointments();
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
                    if (appointment.notes == 'prayerTime' &&
                        _selectedView != CalendarView.day &&
                        _selectedView != CalendarView.week) {
                      return const SizedBox.shrink();
                    }
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
          _selectedNavIndex = index;
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

                                      // UI aktualisieren
                                      await _loadAllCategories();
                                      setStateDialog(
                                          () {}); // Dialog aktualisieren

                                      // Snackbar anzeigen
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Kategorie "${cat.name}" gelöscht'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Fehler: ${e.toString()}'),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
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
