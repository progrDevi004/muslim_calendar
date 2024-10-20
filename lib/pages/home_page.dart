import 'package:flutter/material.dart';
import 'package:muslim_calendar/pages/appointment_creation_page.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../widgets/create_events.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarView _selectedView = CalendarView.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Monthly view Button
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedView = CalendarView.month; // Change to monthly view
                });
              },
              child: Text(
                "Month",
                style: TextStyle(
                  color: _selectedView == CalendarView.month
                      ? Colors.black // Highlight selected view
                      : Colors.black.withOpacity(0.7),
                ),
              ),
            ),
            // Weekly view Button
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedView = CalendarView.week; // Change to weekly view
                });
              },
              child: Text(
                "Week",
                style: TextStyle(
                  color: _selectedView == CalendarView.week
                      ? Colors.black // Highlight selected view
                      : Colors.black.withOpacity(0.7),
                ),
              ),
            ),
            // Daily view Button
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedView = CalendarView.day;
                  // Change to daily view
                });
              },
              child: Text(
                "Day",
                style: TextStyle(
                  color: _selectedView == CalendarView.day
                      ? Colors.black // Highlight selected view
                      : Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _getViewWidget(),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () => {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
          )
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getViewWidget() {
    return FutureBuilder<List<Appointment>>(
      future: loadAppointments(),
      builder: (BuildContext context, AsyncSnapshot<List<Appointment>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return SfCalendar(
            view: _selectedView,
            key: ValueKey(_selectedView),
            monthViewSettings: const MonthViewSettings(
              showTrailingAndLeadingDates: false,
            ),
            dataSource: MeetingDataSource(snapshot.data!),
          );
        } else {
          return Center(child: Text('No appointments available.'));
        }
      },
    );
  }

  void _showDaySelector(BuildContext context) {
    // Burada gün seçimi için bir widget gösterebilirsiniz.
  }

  String _getMonthName() {
    // Burada mevcut ayın ismini döndüren bir fonksiyon yazabilirsiniz.
    return "Month";
  }
}