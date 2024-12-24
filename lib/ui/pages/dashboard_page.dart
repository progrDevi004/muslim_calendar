// lib/ui/pages/dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ----------------------------------------
  // Wetter + Standort
  // ----------------------------------------
  String? _weatherTemp; // z.B. '21°C'
  String? _weatherLocation; // z.B. 'Sylhet'
  bool _isWeatherLoading = false;
  String? _weatherErrorMessage;

  // ----------------------------------------
  // Gebetszeiten
  // ----------------------------------------
  // z.B. {'Fajr': '05:30', 'Dhuhr': '12:15' ...}
  Map<String, String> _todayPrayerTimes = {};
  bool _isPrayerTimesLoading = false;
  String? _prayerTimeErrorMessage;

  // ----------------------------------------
  // Termine für heute
  // ----------------------------------------
  List<_DashboardTask> _todayTasks = [];
  bool _isAppointmentsLoading = false;

  // ----------------------------------------
  // Repositories
  // ----------------------------------------
  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // ----------------------------------------
  // Lifecycle / Init
  // ----------------------------------------
  @override
  void initState() {
    super.initState();
    _initData(); // Lädt Standort + Wetter + Prayer Times + Today-Tasks
  }

  Future<void> _initData() async {
    setState(() {
      _isWeatherLoading = true;
      _isPrayerTimesLoading = true;
      _isAppointmentsLoading = true;
    });

    // 1) Standort aus SharedPreferences lesen
    final prefs = await SharedPreferences.getInstance();
    final defaultCountry = prefs.getString('defaultCountry') ?? 'Turkey';
    final defaultCity = prefs.getString('defaultCity') ?? 'Istanbul';
    final locationString = '$defaultCity,$defaultCountry';

    // 2) Wetter abrufen
    await _fetchWeather(defaultCity);

    // 3) Gebetszeiten für "heute" abrufen
    await _fetchPrayerTimesForToday(locationString);

    // 4) Heutige Termine laden
    await _loadTodaysAppointments();

    // done
    setState(() {});
  }

  // ----------------------------------------
  // WETTER - via OpenWeatherMap
  // ----------------------------------------
  Future<void> _fetchWeather(String city) async {
    const apiKey = 'ea71a51c210c3fa6760039a8b592c19c'; // <<< Bitte anpassen
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final temp = jsonData['main']['temp']; // z.B. 21.5

        setState(() {
          _weatherTemp = '${temp.toStringAsFixed(1)}°C';
          _weatherLocation = city;
          _weatherErrorMessage = null;
        });
      } else {
        setState(() {
          _weatherErrorMessage = 'Weather error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _weatherErrorMessage = 'Weather error: $e';
      });
    } finally {
      _isWeatherLoading = false;
    }
  }

  // ----------------------------------------
  // GEBETSZEITEN
  // ----------------------------------------
  Future<void> _fetchPrayerTimesForToday(String location) async {
    final now = DateTime.now();
    try {
      // Wir holen uns die fünf Standardzeiten
      final fajr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.fajr);
      final dhuhr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.dhuhr);
      final asr = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.asr);
      final maghrib = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.maghrib);
      final isha = await _prayerTimeRepo.getPrayerTimeMinutes(
          now, location, PrayerTime.isha);

      setState(() {
        _todayPrayerTimes = {
          'Fajr': _formatHHmm(fajr),
          'Dhuhr': _formatHHmm(dhuhr),
          'Asr': _formatHHmm(asr),
          'Maghrib': _formatHHmm(maghrib),
          'Isha': _formatHHmm(isha),
        };
        _prayerTimeErrorMessage = null;
      });
    } catch (e) {
      setState(() {
        _prayerTimeErrorMessage = 'Error fetching prayer times: $e';
      });
    } finally {
      _isPrayerTimesLoading = false;
    }
  }

  String _formatHHmm(int? totalMinutes) {
    if (totalMinutes == null) return '--:--';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ----------------------------------------
  // HEUTIGE TERMINE
  // ----------------------------------------
  Future<void> _loadTodaysAppointments() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    // Alle Appointments laden
    final all = await _appointmentRepo.getAllAppointments();

    // Filtern auf "Heute"
    final todayAppointments = all.where((appt) {
      final s = appt.startTime ?? now;
      final e = appt.endTime ?? now;
      // Überlappend mit "heute"?
      return (e.isAfter(startOfDay) && s.isBefore(endOfDay));
    }).toList();

    // Für die Anzeige wandeln wir es in _DashboardTask um
    final tasks = <_DashboardTask>[];
    for (var ap in todayAppointments) {
      final start = ap.startTime ?? now;
      final end = ap.endTime ?? start.add(const Duration(minutes: 30));
      final diff = end.difference(start).inMinutes;
      tasks.add(_DashboardTask(
        title: ap.subject,
        startTime: DateFormat('h:mm a').format(start), // z.B. "9:30 AM"
        endTime: DateFormat('h:mm a').format(end),
        durationInMinutes: diff,
        location: ap.location ?? '',
      ));
    }

    setState(() {
      _todayTasks = tasks;
      _isAppointmentsLoading = false;
    });
  }

  // ----------------------------------------
  // DURATION-FORMAT
  // ----------------------------------------
  /// Gibt die Dauer als "HH:MM h" aus, sobald diff >= 60, sonst "XXm".
  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      final hh = h.toString().padLeft(2, '0');
      final mm = m.toString().padLeft(2, '0');
      return '$hh:$mm h';
    } else {
      return '${minutes}m';
    }
  }

  // ----------------------------------------
  // BUILD
  // ----------------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    final now = DateTime.now();
    final dateString = DateFormat('MMMM d').format(now); // z.B. "September 12"
    final weekdayString = DateFormat('EEEE').format(now); // z.B. "Thursday"

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // Scroll, falls Content mal größer ist
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Datum
                Text(
                  '$dateString, $weekdayString',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Wetter & Gebetszeiten in Kacheln
                Row(
                  children: [
                    // Wetter-Kachel
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildWeatherTile(context, loc),
                      ),
                    ),

                    // Gebetszeiten-Kachel
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildPrayerTimeTile(context, loc),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // "Upcoming Task"
                Text(
                  loc.upcomingTasksLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Task Cards
                _isAppointmentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _todayTasks.map((t) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Zeit & Dauer
                                // => FittedBox, damit der Text nicht umbricht.
                                SizedBox(
                                  width: 60,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDuration(t.durationInMinutes),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${t.startTime} - ${t.endTime}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Task Info
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.location,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------
  // WIDGETS: Wetter + Gebetszeiten
  // ----------------------------------------
  Widget _buildWeatherTile(BuildContext context, AppLocalizations loc) {
    if (_isWeatherLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherErrorMessage != null) {
      return Text(
        _weatherErrorMessage!,
        style: TextStyle(color: Colors.red.shade400),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _weatherTemp != null
              ? '${loc.weather} $_weatherTemp'
              : '${loc.weather} --',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _weatherLocation != null
              ? '${loc.location} $_weatherLocation'
              : '${loc.location} --',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPrayerTimeTile(BuildContext context, AppLocalizations loc) {
    if (_isPrayerTimesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prayerTimeErrorMessage != null) {
      return Text(
        _prayerTimeErrorMessage!,
        style: TextStyle(color: Colors.red.shade400),
      );
    }
    if (_todayPrayerTimes.isEmpty) {
      return Text('${loc.prayerTimeSettings}\n--');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.prayerTimeSettings} (Today)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ..._todayPrayerTimes.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                Text(e.value, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------
// Demo-Helferklasse für Task-Anzeige
// ----------------------------------------
class _DashboardTask {
  final String title;
  final String startTime;
  final String endTime;
  final int durationInMinutes;
  final String location;

  _DashboardTask({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationInMinutes,
    required this.location,
  });
}
