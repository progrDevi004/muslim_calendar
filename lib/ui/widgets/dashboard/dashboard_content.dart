import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/dashboard_task.dart';
import 'package:muslim_calendar/ui/widgets/dashboard/dashboard_header.dart';
import 'package:muslim_calendar/ui/widgets/dashboard/prayer_time_tile.dart';
import 'package:muslim_calendar/ui/widgets/dashboard/task_list.dart';
import 'package:muslim_calendar/ui/widgets/dashboard/weather_tile.dart';

class DashboardContent extends StatelessWidget {
  // Datum
  final String dateString;
  final String weekdayString;

  // Wetter
  final String? weatherTemp;
  final String? weatherLocation;
  final String? weatherSymbol;
  final String? weatherErrorMessage;
  final bool isWeatherLoading;

  // Gebetszeiten
  final Map<String, String> prayerTimesDisplay;
  final String? prayerTimeErrorMessage;
  final bool isPrayerTimesLoading;

  // Aufgaben/Termine
  final List<DashboardTask> todayTasks;
  final bool isTasksLoading;
  final int? hoveredTaskId;

  // Callbacks
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const DashboardContent({
    Key? key,
    required this.dateString,
    required this.weekdayString,
    this.weatherTemp,
    this.weatherLocation,
    this.weatherSymbol,
    this.weatherErrorMessage,
    required this.isWeatherLoading,
    required this.prayerTimesDisplay,
    this.prayerTimeErrorMessage,
    required this.isPrayerTimesLoading,
    required this.todayTasks,
    required this.isTasksLoading,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentCardColor = mainColor.withOpacity(isDark ? 0.3 : 0.1);
    final Color accentTextColor = mainColor.withOpacity(isDark ? 0.9 : 0.7);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Datum
          DashboardHeader(
            dateString: dateString,
            weekdayString: weekdayString,
          ),

          // Kacheln für Wetter und Gebetszeiten
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wetter-Kachel
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentCardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: WeatherTile(
                      temperature: weatherTemp,
                      location: weatherLocation,
                      symbol: weatherSymbol,
                      errorMessage: weatherErrorMessage,
                      isLoading: isWeatherLoading,
                      accentTextColor: accentTextColor,
                    ),
                  ),
                ),

                // Gebetszeiten-Kachel
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentCardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: PrayerTimeTile(
                      prayerTimesDisplay: prayerTimesDisplay,
                      errorMessage: prayerTimeErrorMessage,
                      isLoading: isPrayerTimesLoading,
                      accentTextColor: accentTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Aufgabenliste
          TaskList(
            tasks: todayTasks,
            isLoading: isTasksLoading,
            hoveredTaskId: hoveredTaskId,
            onHoverEnter: onHoverEnter,
            onHoverExit: onHoverExit,
            onTaskTap: onTaskTap,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
