import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import 'appointment_creation_page.dart';
import '../database/database_helper.dart';
import '../widgets/prayer_time_appointment.dart';
import '../widgets/create_events.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarView _selectedView = CalendarView.month;
  late CalendarController _calendarController;
  late EventDataSource _dataSource;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime? _selectedDate;

  int _selectedNavIndex = 0; // 0 = Month, 1 = Week, 2 = Day

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = EventDataSource([]);
    _selectedDate = null;
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
      final List<PrayerTimeAppointment> appointments =
          await _databaseHelper.getAllAppointments();
      setState(() {
        _dataSource = EventDataSource(appointments);
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
          // Monatsansicht: Nur Punkte (Indikatoren) für Termine
          // Gleichzeitig showAgenda: true, um darunter die Agenda mit Text anzuzeigen.
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: true,
          ),
          // Kein appointmentBuilder nötig. Standardmäßig:
          // - Monatsansicht: Punkte im Kalender, Text unten in der Agenda
          // - Wochen- & Tagesansicht: Balken mit Text
          onTap: (calendarTapDetails) async {
            if (calendarTapDetails.targetElement ==
                CalendarElement.appointment) {
              int appointmentId = int.parse(((calendarTapDetails
                              .appointments?.firstOrNull as Appointment?)
                          ?.id ??
                      '')
                  .toString());
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => AppointmentCreationPage(
                          appointmentId: appointmentId,
                        )),
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
            MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
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
