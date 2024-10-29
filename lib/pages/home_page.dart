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
  late LazyLoadingCalendarDataSource _dataSource;
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _dataSource = LazyLoadingCalendarDataSource(loadAppointments);
    _calendarController = CalendarController();
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
        dataSource: _dataSource,
        loadMoreWidgetBuilder: _buildLoadMoreWidget,
        monthViewSettings: const MonthViewSettings(
          showTrailingAndLeadingDates: false,
        ),
        onViewChanged: (ViewChangedDetails details) {
          _dataSource.handleLoadMore(details.visibleDates.first, details.visibleDates.last);
        },
        controller: _calendarController,
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AppointmentCreationPage()),
        ),
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

  Widget _buildLoadMoreWidget(BuildContext context, LoadMoreCallback loadMoreAppointments) {
    return FutureBuilder(
      future: loadMoreAppointments(),
      builder: (context, snapshot) {
        return Container(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
