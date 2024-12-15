import 'package:flutter/material.dart';
import 'package:muslim_calendar/widgets/create_events.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'appointment_creation_page.dart';
import '../database/database_helper.dart';
import '../widgets/prayer_time_appointment.dart';
import 'dart:async';

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
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = EventDataSource([]);
    _selectedDate = null;
    _dataSource.loadAppointmentsFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final viewOptions = {
      CalendarView.month: 'Month',
      CalendarView.week: 'Week',
      CalendarView.day: 'Day',
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            Text('My Calendar', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<CalendarView>(
              showSelectedIcon: false,
              segments: viewOptions.entries.map((entry) {
                return ButtonSegment<CalendarView>(
                  value: entry.key,
                  label: Text(entry.value),
                );
              }).toList(),
              selected: {_selectedView},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedView = newSelection.first;
                  _calendarController.view = _selectedView;
                });
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SfCalendar(
          headerStyle:
              const CalendarHeaderStyle(backgroundColor: Colors.transparent),
          view: _selectedView,
          controller: _calendarController,
          dataSource: _dataSource,
          showDatePickerButton: true,
          onSelectionChanged: (calendarSelectionDetails) {
            _selectedDate = calendarSelectionDetails.date;
          },
          timeSlotViewSettings: const TimeSlotViewSettings(
            timeIntervalHeight: 60,
          ),
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showAgenda: true,
          ),
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
            } else if (calendarTapDetails.targetElement ==
                CalendarElement.calendarCell) {
              if (calendarTapDetails.date == _selectedDate) {
                setState(() {
                  _selectedView = CalendarView.day;
                  _calendarController.view = CalendarView.day;
                });
              }
            }
          },
          onViewChanged: (ViewChangedDetails details) {
            _loadAppointmentsForVisibleDates(
                details.visibleDates.first, details.visibleDates.last);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Future<void> _loadAppointmentsForVisibleDates(
      DateTime start, DateTime end) async {
    DateTime endDate = end.add(const Duration(days: 1));
    try {
      final List<PrayerTimeAppointment> appointments =
          await _databaseHelper.getAppointmentsForDateRange(start, endDate);

      setState(() {
        _dataSource.appointments!.clear();
        _dataSource.appointments!.addAll(appointments);
        _dataSource.notifyListeners(
            CalendarDataSourceAction.reset, appointments);
      });
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }
}
