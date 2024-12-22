//ui/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/services/recurrence_service.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/ui/widgets/create_events.dart';
import 'package:muslim_calendar/ui/widgets/prayer_time_appointment_adapter.dart';
import 'appointment_creation_page.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarView _selectedView = CalendarView.month;
  late CalendarController _calendarController;
  EventDataSource? _dataSource;
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final PrayerTimeAppointmentAdapter _adapter = PrayerTimeAppointmentAdapter(
    prayerTimeService: PrayerTimeService(PrayerTimeRepository()),
    recurrenceService: RecurrenceService(),
  );
  DateTime? _selectedDate;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _updateCalendarViewFromNavIndex();
    _loadAllAppointments();
  }

  void _updateCalendarViewFromNavIndex() {
    switch (_selectedNavIndex) {
      case 0:
        _selectedView = CalendarView.month;
        break;
      case 1:
        _selectedView = CalendarView.week;
        break;
      case 2:
        _selectedView = CalendarView.day;
        break;
    }
    _calendarController.view = _selectedView;
    setState(() {});
  }

  Future<void> _loadAllAppointments() async {
    try {
      final List<AppointmentModel> models =
          await _appointmentRepo.getAllAppointments();
      final now = DateTime.now();
      final startRange = DateTime(now.year, now.month - 1, 1);
      final endRange = DateTime(now.year, now.month + 2, 1);

      List<Appointment> allAppointments = [];
      for (var m in models) {
        final apps =
            await _adapter.getAppointmentsForRange(m, startRange, endRange);
        allAppointments.addAll(apps);
      }

      setState(() {
        _dataSource = EventDataSource(allAppointments);
      });
    } catch (e) {
      print('Error loading all appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(loc.myCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              _showLanguageSelection(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        child: SfCalendar(
          headerStyle: const CalendarHeaderStyle(
            backgroundColor: Colors.transparent,
            textAlign: TextAlign.center,
            textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          view: _selectedView,
          controller: _calendarController,
          dataSource: _dataSource,
          showDatePickerButton: true,
          onSelectionChanged: (calendarSelectionDetails) {
            _selectedDate = calendarSelectionDetails.date;
          },
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: true,
          ),
          onTap: (calendarTapDetails) async {
            if (calendarTapDetails.targetElement ==
                CalendarElement.appointment) {
              int appointmentId = int.parse(
                  (calendarTapDetails.appointments?.first.id ?? '').toString());
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppointmentCreationPage(
                    appointmentId: appointmentId,
                  ),
                ),
              );
              _loadAllAppointments();
            } else if (calendarTapDetails.targetElement ==
                CalendarElement.calendarCell) {
              if (calendarTapDetails.date == _selectedDate) {
                setState(() {
                  _selectedNavIndex = 2; // Day View
                  _updateCalendarViewFromNavIndex();
                });
              }
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const AppointmentCreationPage()),
          );
          _loadAllAppointments();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (int index) {
          _selectedNavIndex = index;
          _updateCalendarViewFromNavIndex();
        },
        destinations: [
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

  void _showLanguageSelection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: AppLanguage.values.map((language) {
              return ListTile(
                title: Text(loc.getLanguageName(language)),
                onTap: () {
                  loc.setLanguage(language);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
