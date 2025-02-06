import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  /// Navigation:
  /// 0 => Dashboard
  /// 1 => Day
  /// 2 => Week
  /// 3 => Month
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

  // Dezenter Farbton für Gebetszeiten
  static const Color _prayerTimeColor = Color(0xFF90A4AE); // BlueGrey 300

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

    // --------------------------
    // NEU: Standardmäßig heute auswählen,
    // damit bei der Monats-Agenda direkt der heutige Tag angezeigt wird.
    // --------------------------
    _selectedDate = DateTime.now();
    _calendarController.selectedDate = _selectedDate;
    _calendarController.displayDate = _selectedDate;
    // --------------------------

    _updateCalendarViewFromNavIndex();

    _loadUserPrefs();
    _loadAllCategories();
    _fetchYearlyPrayerTimesIfNeeded().then((_) {
      loadAllAppointments();
    });
  }

  /// Zeitformat und Gebetszeiteinstellungen aus SharedPreferences laden
  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _use24hFormat = prefs.getBool('use24hFormat') ?? false;

      // Dashboard
      _showPrayerSlotsInDashboard =
          prefs.getBool('showPrayerSlotsInDashboard') ?? true;

      // Day
      _showPrayerTimesInDayView =
          prefs.getBool('showPrayerTimesInDayView') ?? true;

      // Week
      _showPrayerTimesInWeekView =
          prefs.getBool('showPrayerTimesInWeekView') ?? true;

      // Month
      // Hier hast du laut Vorgabe "nie Gebetszeiten" – also auf false
      _showPrayerTimesInMonthView = false;
    });
  }

  /// Prüfen, ob wir schon das ganze Jahr an Gebetszeiten gespeichert haben
  Future<void> _fetchYearlyPrayerTimesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('defaultCountry');
    final city = prefs.getString('defaultCity');
    if (country == null || city == null) return;

    final location = '${city.trim()},${country.trim()}'.toLowerCase();
    final now = DateTime.now();
    await _prayerTimeRepo.fetchAndSaveYearlyPrayerTimes(now.year, location);
  }

  /// Updated den `CalendarView` und lädt neu
  void _updateCalendarViewFromNavIndex() {
    switch (_selectedNavIndex) {
      case 0:
        // Dashboard => kein CalendarView
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
    setState(() {
      // Falls du bei jedem Wechsel in die Monatsansicht
      // *erneut* den heutigen Tag erzwingen willst, könntest du hier:
      // if (_selectedView == CalendarView.month) {
      //   _selectedDate = DateTime.now();
      //   _calendarController.selectedDate = _selectedDate;
      //   _calendarController.displayDate = _selectedDate;
      // }
    });

    // Bei jedem Wechsel der Ansicht -> neu laden,
    // damit Day/Week-Flags korrekt berücksichtigt werden
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

  // Hilfsfunktion, um DB-Werte in int? zu konvertieren
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Lädt alle normalen Appointments + Gebetszeiten (falls aktiviert)
  Future<void> loadAllAppointments() async {
    try {
      final models = await _appointmentRepo.getAllAppointments();
      final now = DateTime.now();

      // Standard: 2 Monate zurück, 3 Monate nach vorn
      final startRange = DateTime(now.year, now.month - 2, 1);
      final endRange = DateTime(now.year, now.month + 3, 1);

      final List<Appointment> allAppointments = [];

      // 1) Normale Appointments
      for (var m in models) {
        // Kategorie-Filter
        if (m.categoryId == null ||
            _selectedCategoryIds.contains(m.categoryId)) {
          final apps =
              await _adapter.getAppointmentsForRange(m, startRange, endRange);
          allAppointments.addAll(apps);
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
        addPrayers = false; // niemals Gebetszeiten in Month
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

    // Falls wir auf Dashboard sind => reload
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

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final bool showFab = (_selectedNavIndex >= 1);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 200, // Wert ggf. anpassen
        leading: Row(
          children: [
            // Dein Logo (mit Schrift) als Image.asset
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Image.asset(
                'assets/images/logo.png', // Pfad zu deinem Logo anpassen
                height: 30, // Höhe des Logos, ggf. anpassen
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
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
                showDatePickerButton: true,
                monthViewSettings: const MonthViewSettings(
                  // Agenda einblenden
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  showAgenda: true,
                  agendaItemHeight: 50,
                  monthCellStyle: MonthCellStyle(
                    trailingDatesBackgroundColor:
                        Color.fromARGB(0, 165, 165, 165),
                  ),
                ),
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeIntervalHeight: 80,
                ),
                appointmentBuilder:
                    (BuildContext context, CalendarAppointmentDetails details) {
                  if (details.appointments.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final Appointment appointment = details.appointments.first;

                  // Gebetszeiten nicht antippbar
                  if (appointment.notes == 'prayerTime' &&
                      _selectedView != CalendarView.day &&
                      _selectedView != CalendarView.week) {
                    return const SizedBox.shrink();
                  }

                  // Month => Minimales Layout
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
                                  '${_formatTime(appointment.startTime)} - '
                                  '${_formatTime(appointment.endTime)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    );
                  }

                  // Week/Day => größerer Container
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

                    // Gebetszeiten nicht antippbar
                    if (app.notes == 'prayerTime') {
                      return;
                    }

                    // Sonst => Termin-Details
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
                    // KLICK auf denselben Tag => wechsle in Day-Ansicht
                    if (calendarTapDetails.date == _selectedDate) {
                      setState(() {
                        _selectedNavIndex = 1; // Day
                        _updateCalendarViewFromNavIndex();
                      });
                    }
                  }
                },
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

  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  /// SPEICHERN DER GEWÄHLTEN KATEGORIEN IN SHARED PREFERENCES
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
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(cat.name),
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

                    // **NEU**: Ausgewählte Kategorien in SharedPrefs speichern
                    await _saveSelectedCategoryIdsToPrefs();

                    // Dann neu laden
                    loadAllAppointments();

                    // Wenn Dashboard aktiv => dort auch reload
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
    showDialog(
      context: context,
      builder: (ctx) {
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
              const SizedBox(height: 12),
              BlockPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) {
                  selectedColor = color;
                },
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
                  final newCategory = CategoryModel(
                    name: name,
                    color: selectedColor,
                  );
                  await _categoryRepo.insertCategory(newCategory);
                  await _loadAllCategories();
                  Navigator.of(ctx).pop();
                  loadAllAppointments();
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }
}
