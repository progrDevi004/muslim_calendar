// lib/ui/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repositories & Services
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
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
import 'package:muslim_calendar/ui/pages/appointment_details_page.dart'; // <<< NEU: Import der Detail-Seite

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Navigation:
  /// 0 => Dashboard
  /// 1 => Month
  /// 2 => Week
  /// 3 => Day
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

  bool _use24hFormat = false; // Zeitformat

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _selectedNavIndex = 0;
    _updateCalendarViewFromNavIndex();

    _loadUserPrefs();
    _loadAllCategories();
    _loadAllAppointments();
  }

  /// Zeitformat aus SharedPreferences laden
  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24hFormat = prefs.getBool('use24hFormat') ?? false;
    });
  }

  void _updateCalendarViewFromNavIndex() {
    switch (_selectedNavIndex) {
      case 0:
        break; // Dashboard
      case 1:
        _selectedView = CalendarView.month;
        break;
      case 2:
        _selectedView = CalendarView.week;
        break;
      case 3:
        _selectedView = CalendarView.day;
        break;
    }
    _calendarController.view = _selectedView;
    setState(() {});
  }

  Future<void> _loadAllCategories() async {
    final cats = await _categoryRepo.getAllCategories();
    setState(() {
      _allCategories = cats;
      _selectedCategoryIds = cats.map((e) => e.id!).toSet();
    });
  }

  Future<void> _loadAllAppointments() async {
    try {
      final models = await _appointmentRepo.getAllAppointments();
      final now = DateTime.now();
      final startRange = DateTime(now.year, now.month - 1, 1);
      final endRange = DateTime(now.year, now.month + 2, 1);

      final List<Appointment> allAppointments = [];
      for (var m in models) {
        if (m.categoryId == null ||
            _selectedCategoryIds.contains(m.categoryId)) {
          final apps =
              await _adapter.getAppointmentsForRange(m, startRange, endRange);
          allAppointments.addAll(apps);
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

    // Zeitformat ggf. neu laden
    _loadUserPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final bool showFab = (_selectedNavIndex >= 1);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategoryFilterDialog,
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
                  textStyle:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                view: _selectedView,
                controller: _calendarController,
                dataSource: _dataSource,
                showDatePickerButton: true,

                // MonthView: Agenda
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  showAgenda: true,
                  agendaItemHeight: 50,
                  monthCellStyle: MonthCellStyle(
                    trailingDatesBackgroundColor:
                        Color.fromARGB(0, 165, 165, 165),
                  ),
                ),

                // Tages-/Wochen-Ansicht: mehr Höhe für Zeitintervalle
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeIntervalHeight: 80,
                ),

                appointmentBuilder:
                    (BuildContext context, CalendarAppointmentDetails details) {
                  if (details.appointments.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final Appointment appointment = details.appointments.first;

                  // MonthView => kleines Layout
                  if (_selectedView == CalendarView.month) {
                    return Container(
                      decoration: BoxDecoration(
                        color: appointment.color,
                        shape: BoxShape.rectangle,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                // Zeitformat
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

                  // Week/Day => Container mit Text
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
                  // Auf Termin getippt => Detailseite öffnen
                  if (calendarTapDetails.targetElement ==
                      CalendarElement.appointment) {
                    final appId = calendarTapDetails.appointments?.first.id;
                    if (appId != null) {
                      final appointmentId = int.tryParse(appId.toString());
                      if (appointmentId != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AppointmentDetailsPage(
                              appointmentId: appointmentId,
                            ),
                          ),
                        );
                        _loadAllAppointments();
                      }
                    }
                  }
                  // Auf freies Kalenderfeld getippt => evtl. Day-View bei Doppelklick
                  else if (calendarTapDetails.targetElement ==
                      CalendarElement.calendarCell) {
                    if (calendarTapDetails.date == _selectedDate) {
                      setState(() {
                        _selectedNavIndex = 3; // Day
                        _updateCalendarViewFromNavIndex();
                      });
                    }
                  }
                },
              ),
            ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              tooltip: 'Neuen Termin hinzufügen',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AppointmentCreationPage(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
                _loadAllAppointments();
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
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: loc.month,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week),
            label: loc.week,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_day),
            label: loc.day,
          ),
        ],
      ),
    );
  }

  /// Zeitformat für Termin-Anzeige
  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Kategorien filtern'),
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
                      setState(() {
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
                  child: const Text('+ Neue Kategorie'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _loadAllAppointments();
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Neue Kategorie erstellen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
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
              child: const Text('Abbrechen'),
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
                  _loadAllAppointments();
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}
