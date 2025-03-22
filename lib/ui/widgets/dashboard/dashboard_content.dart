import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taqvimi/models/dashboard_task.dart';
import 'package:taqvimi/ui/widgets/dashboard/dashboard_header.dart';
import 'package:taqvimi/ui/widgets/dashboard/prayer_time_tile.dart';
import 'package:taqvimi/ui/widgets/dashboard/task_list.dart';
import 'package:taqvimi/ui/widgets/dashboard/weather_tile.dart';

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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Plattformspezifische Anpassungen
    final double horizontalPadding = Platform.isIOS ? 14.0 : 16.0;
    final double topPadding = Platform.isIOS ? 14.0 : 16.0;
    final double betweenSectionsPadding = Platform.isIOS ? 18.0 : 16.0;
    final double borderRadius = Platform.isIOS ? 14.0 : 16.0;
    final double tilePadding = Platform.isIOS ? 14.0 : 16.0;
    final double tileMargin = Platform.isIOS ? 6.0 : 8.0;

    final Color accentCardColor = mainColor.withOpacity(isDark ? 0.3 : 0.1);
    final Color accentTextColor = mainColor.withOpacity(isDark ? 0.9 : 0.7);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding),

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
                    margin: EdgeInsets.only(right: tileMargin),
                    padding: EdgeInsets.all(tilePadding),
                    decoration: BoxDecoration(
                      color: accentCardColor,
                      borderRadius: BorderRadius.circular(borderRadius),
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
                    margin: EdgeInsets.only(left: tileMargin),
                    padding: EdgeInsets.all(tilePadding),
                    decoration: BoxDecoration(
                      color: accentCardColor,
                      borderRadius: BorderRadius.circular(borderRadius),
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

          SizedBox(height: betweenSectionsPadding),

          // Aufgabenliste
          TaskList(
            tasks: todayTasks,
            isLoading: isTasksLoading,
            hoveredTaskId: hoveredTaskId,
            onHoverEnter: onHoverEnter,
            onHoverExit: onHoverExit,
            onTaskTap: onTaskTap,
          ),

          // Extra Abstand am Ende für den FAB
          SizedBox(height: Platform.isIOS ? 80 : 40),
        ],
      ),
    );
  }
}
