import 'package:flutter/material.dart';
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
        onPressed: () => {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getViewWidget() {
    switch (_selectedView) {
      case CalendarView.week:
        return SfCalendar(
          view: _selectedView,
          key: ValueKey(_selectedView),
          firstDayOfWeek: 1,
          dataSource: MeetingDataSource(getAppointments()),
        );
      case CalendarView.day:
        return SfCalendar(
          view: _selectedView,
          key: ValueKey(_selectedView),
          dataSource: MeetingDataSource(getAppointments()),
        );
      case CalendarView.month:
      default:
        return SfCalendar(
          view: _selectedView,
          key: ValueKey(_selectedView),
          monthViewSettings: const MonthViewSettings(
            showTrailingAndLeadingDates: false,
          ),
          dataSource: MeetingDataSource(getAppointments()),
        );
    }
  }

  void _showDaySelector(BuildContext context) {
    // Burada gün seçimi için bir widget gösterebilirsiniz.
  }

  String _getMonthName() {
    // Burada mevcut ayın ismini döndüren bir fonksiyon yazabilirsiniz.
    return "Month";
  }
}
