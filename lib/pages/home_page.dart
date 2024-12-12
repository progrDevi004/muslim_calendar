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
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = EventDataSource([]);
    _selectedDate = null;
    _dataSource.loadAppointmentsFromDatabase();
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
        headerStyle: CalendarHeaderStyle(backgroundColor: Colors.white),
        view: _selectedView,
        controller: _calendarController,
        dataSource: _dataSource,
        showDatePickerButton: true,
        onSelectionChanged: (calendarSelectionDetails) {
          _selectedDate = calendarSelectionDetails.date;
        },
        timeSlotViewSettings: const TimeSlotViewSettings(timeIntervalHeight: 100,),
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showAgenda: true,
          ),
          onTap: (calendarTapDetails) async {
            if(calendarTapDetails.targetElement == CalendarElement.appointment){
              int appointmentId = int.parse(((calendarTapDetails.appointments?.firstOrNull as Appointment?)?.id ?? '').toString());
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AppointmentCreationPage(appointmentId: appointmentId,)),
                );
              //_loadAppointmentsForVisibleDates(_calendarController.displayDate!, _calendarController.view!);
            }
            else if(calendarTapDetails.targetElement == CalendarElement.calendarCell){
              if(calendarTapDetails.date == _selectedDate){
                setState(() {
                  _selectedView = CalendarView.day;
                  _calendarController.view = CalendarView.day;
                });
              }
            }
          },
        onViewChanged: (ViewChangedDetails details) {
          _loadAppointmentsForVisibleDates(details.visibleDates.first, details.visibleDates.last);
        },
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
          );
          //_loadAppointmentsForVisibleDates(_calendarController.displayDate!, _calendarController.view!);
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
        });
        // Görünüm değiştiğinde görünür tarihleri yeniden yükle
        //_loadAppointmentsForVisibleDates(_calendarController.displayDate!, _calendarController.view!);
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


  Future<void> _loadAppointmentsForVisibleDates(DateTime displayDate, DateTime endDate) async {
    DateTime start = displayDate;
    DateTime end = endDate.add(const Duration(days: 1));
    print(endDate);


    try {
      final List<PrayerTimeAppointment> appointments = 
          await _databaseHelper.getAppointmentsForDateRange(start, end);
      
      setState(() {
        _dataSource = EventDataSource(appointments);
      });
      //print(appointments);
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
  DateTime _calculateEndDate(DateTime start, CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return start.add(Duration(days: 1));
      case CalendarView.week:
        return start.add(Duration(days: 7));
      case CalendarView.workWeek:
        return start.add(Duration(days: 5));
      case CalendarView.month:
        return DateTime(start.year, start.month + 1, 0);
      default:
        return start.add(Duration(days: 30));
    }
  }
}