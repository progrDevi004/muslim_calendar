import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../pages/appointment_creation_page.dart';
import '../widgets/create_events.dart';
import '../database/database_helper.dart';
import '../widgets/prayer_time_appointment.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarView _selectedView = CalendarView.month;
  late CalendarController _calendarController;
  late EventDataSource _dataSource;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = EventDataSource([]);
    //_loadAppointments();
  }

  Future<void> _loadAppointments() async {
    List<PrayerTimeAppointment> appointments = await _databaseHelper.getAllAppointments();
    setState(() {
      _dataSource = EventDataSource(appointments);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildViewButton("Month", CalendarView.month),
            _buildViewButton("Week", CalendarView.week),
            _buildViewButton("Day", CalendarView.day),
          ],
        ),
      ),
      body: SfCalendar(
        view: _selectedView,
        controller: _calendarController,
        dataSource: _dataSource,
        showDatePickerButton: true,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showAgenda: true,
          ),
          onTap: (calendarTapDetails) {
            print(calendarTapDetails.targetElement);
          },
        onViewChanged: (ViewChangedDetails details) {
          //print("Before:" + _dataSource.appointments.toString());
          //print(details.visibleDates);
          _loadAppointmentsForVisibleDates(details.visibleDates);
        },
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
          );
          _loadAppointments();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildViewButton(String title, CalendarView view) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedView = view;
          _calendarController.view = view;
          //print("Günlük görünümdeki randevular: ${_dataSource}");
        });
      },
      child: Text(
        title,
        style: TextStyle(
          color: _selectedView == view
              ? Colors.black
              : Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  Future<void> _loadAppointmentsForVisibleDates(List<DateTime> visibleDates) async {
  if (visibleDates.isEmpty) return;

  final DateTime start = visibleDates.first;
  final DateTime end = _calculateEndDate(start);

  try {
    final List<PrayerTimeAppointment> appointments = 
        await _databaseHelper.getAppointmentsForDateRange(start, end);
    
    setState(() {
      _dataSource = EventDataSource(appointments);
    });

    // Hata ayıklama için
    // print('Loaded appointments: ${appointments.length}');
    // print('Date range: $start to $end');
  } catch (e) {
    print('Error loading appointments: $e');
    // Hata durumunda kullanıcıya bilgi verebilirsiniz
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Randevular yüklenirken bir hata oluştu')),
    // );
  }
}
  DateTime _calculateEndDate(DateTime start) {
    switch (_selectedView) {
      case CalendarView.day:
        return start.add(Duration(days: 1));
      case CalendarView.week:
        return start.add(Duration(days: 8));
      default:
        return start.add(Duration(days: 32));
    }
  }
}