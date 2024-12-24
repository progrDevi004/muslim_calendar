// lib/ui/pages/dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// >>> WICHTIG: Diesen Import brauchst du für initializeDateFormatting <<<
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
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
  String? _weatherTemp;
  String? _weatherLocation;
  String? _weatherSymbol;
  bool _isWeatherLoading = false;
  String? _weatherErrorMessage;

  // ----------------------------------------
  // Gebetszeiten
  // ----------------------------------------
  Map<String, String> _todayPrayerTimes = {};
  bool _isPrayerTimesLoading = false;
  String? _prayerTimeErrorMessage;

  // ----------------------------------------
  // Termine für heute (Dashboard-Tasks)
  // ----------------------------------------
  List<_DashboardTask> _todayTasks = [];
  bool _isAppointmentsLoading = false;

  // ----------------------------------------
  // Repositories
  // ----------------------------------------
  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// Initialisiert die Lokalisierung (Datumsformate) und lädt Wetter/Gebetszeiten/Termine.
  Future<void> _initData() async {
    // 1) Vor dem Erzeugen eines DateFormat einmalig initializeDateFormatting aufrufen.
    //    Damit verhinderst du den "Locale data has not been initialized"-Fehler.
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    await initializeDateFormatting(languageCode, null);

    // 2) Dann normal weiter:
    setState(() {
      _isWeatherLoading = true;
      _isPrayerTimesLoading = true;
      _isAppointmentsLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final defaultCountry = prefs.getString('defaultCountry') ?? 'Turkey';
    final defaultCity = prefs.getString('defaultCity') ?? 'Istanbul';
    final locationString = '$defaultCity,$defaultCountry';

    // Wetter
    await _fetchWeather(defaultCity);

    // Gebetszeiten
    await _fetchPrayerTimesForToday(locationString);

    // Heutige Termine
    await _loadTodaysAppointments();

    setState(() {});
  }

  // ----------------------------------------
  // WETTER
  // ----------------------------------------
  Future<void> _fetchWeather(String city) async {
    const apiKey = 'ea71a51c210c3fa6760039a8b592c19c'; // Dein API-Key
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final temp = jsonData['main']['temp'];
        final tempStr = '${temp.toStringAsFixed(1)}°C';

        final mainCondition =
            (jsonData['weather'] != null && jsonData['weather'].isNotEmpty)
                ? (jsonData['weather'][0]['main'] as String?) ?? ''
                : '';

        final symbol = _mapWeatherSymbol(mainCondition);

        setState(() {
          _weatherTemp = tempStr;
          _weatherSymbol = symbol;
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

  String _mapWeatherSymbol(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain')) {
      return '🌧';
    } else if (lower.contains('cloud')) {
      return '☁';
    } else if (lower.contains('clear')) {
      return '☀';
    } else if (lower.contains('snow')) {
      return '❄';
    } else {
      return '🌤';
    }
  }

  // ----------------------------------------
  // GEBETSZEITEN
  // ----------------------------------------
  Future<void> _fetchPrayerTimesForToday(String location) async {
    final now = DateTime.now();
    try {
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
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ----------------------------------------
  // HEUTIGE TERMINE
  // ----------------------------------------
  Future<void> _loadTodaysAppointments() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    final all = await _appointmentRepo.getAllAppointments();

    final todayAppointments = all.where((appt) {
      final s = appt.startTime ?? now;
      final e = appt.endTime ?? now;
      return (e.isAfter(startOfDay) && s.isBefore(endOfDay));
    }).toList();

    final tasks = <_DashboardTask>[];
    for (var ap in todayAppointments) {
      final start = ap.startTime ?? now;
      final end = ap.endTime ?? start.add(const Duration(minutes: 30));
      final diff = end.difference(start).inMinutes;

      final desc = ap.notes ?? '';

      tasks.add(_DashboardTask(
        title: ap.subject,
        startTime: DateFormat('h:mm a').format(start),
        endTime: DateFormat('h:mm a').format(end),
        durationInMinutes: diff,
        description: desc,
        color: ap.color,
      ));
    }

    setState(() {
      _todayTasks = tasks;
      _isAppointmentsLoading = false;
    });
  }

  // ----------------------------------------
  // Dauer-Format
  // ----------------------------------------
  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';
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

    // >>> Wir erstellen einen lokalisierten Formatter
    final dateFormatter = _createLocalizedDateFormatter(loc);
    final weekdayFormatter = _createLocalizedWeekdayFormatter(loc);

    final now = DateTime.now();
    final dateString = dateFormatter.format(now);
    final weekdayString = weekdayFormatter.format(now);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Z.B. "24 December 2024, Tuesday" in lokalisierter Schreibweise
                Text(
                  '$dateString, $weekdayString',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildWeatherTile(context, loc),
                        ),
                      ),

                      // Gebetszeiten-Kachel
                      Expanded(
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
                ),

                const SizedBox(height: 16),
                Text(
                  loc.upcomingTasksLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                _isAppointmentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _todayTasks.map((t) {
                          final tintedColor = t.color.withOpacity(0.15);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: tintedColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
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
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
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
                                      ),
                                      const SizedBox(height: 4),
                                      Text(t.description),
                                    ],
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
  // Wetter-Widget
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

    // Überschrift: "Wetter" o.Ä. via loc.weather
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.weather,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        // Temperatur
        Text(
          _weatherTemp ?? '--',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 4),
        // Symbol
        Text(
          _weatherSymbol ?? '',
          style: const TextStyle(fontSize: 28),
        ),
        const Spacer(),
        // Ort
        Text(
          _weatherLocation ?? '--',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ----------------------------------------
  // Gebetszeiten
  // ----------------------------------------
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
      return Text('${loc.prayerTimeDashboard}\n--');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.prayerTimeDashboard,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
        const Spacer(),
      ],
    );
  }

  // ----------------------------------------
  // Lokalisierte Formatter
  // ----------------------------------------
  DateFormat _createLocalizedDateFormatter(AppLocalizations loc) {
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    return DateFormat('d MMMM yyyy', languageCode);
  }

  DateFormat _createLocalizedWeekdayFormatter(AppLocalizations loc) {
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    return DateFormat('EEEE', languageCode);
  }

  String _mapAppLanguageToCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.german:
        return 'de';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
      default:
        return 'en';
    }
  }
}

// ----------------------------------------
// Hilfsklasse für Task-Anzeige
// ----------------------------------------
class _DashboardTask {
  final String title;
  final String startTime;
  final String endTime;
  final int durationInMinutes;
  final String description;
  final Color color;

  _DashboardTask({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationInMinutes,
    required this.description,
    required this.color,
  });
}
