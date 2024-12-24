// lib/ui/pages/dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Localization & Models
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

// <<< NEU: Detailseite importieren >>>
import 'package:muslim_calendar/ui/pages/appointment_details_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool _isWeatherLoading = false;
  bool _isPrayerTimesLoading = false;
  bool _isAppointmentsLoading = false;

  String? _weatherTemp;
  String? _weatherLocation;
  String? _weatherSymbol;
  String? _weatherErrorMessage;

  Map<String, String> _todayPrayerTimes = {};
  String? _prayerTimeErrorMessage;

  List<_DashboardTask> _todayTasks = [];

  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  bool _use24hFormat = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// >>> Neu: öffentlich, damit wir von außen reloadData() aufrufen können <<<
  Future<void> reloadData() async {
    await _initData();
  }

  Future<void> _initData() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    await initializeDateFormatting(languageCode, null);

    final prefs = await SharedPreferences.getInstance();
    _use24hFormat = prefs.getBool('use24hFormat') ?? false;

    setState(() {
      _isWeatherLoading = true;
      _isPrayerTimesLoading = true;
      _isAppointmentsLoading = true;
    });

    final defaultCountry = prefs.getString('defaultCountry') ?? 'Turkey';
    final defaultCity = prefs.getString('defaultCity') ?? 'Istanbul';
    final locationString = '$defaultCity,$defaultCountry';

    await _fetchWeather(defaultCity);
    await _fetchPrayerTimesForToday(locationString);
    await _loadTodaysAppointments();

    setState(() {});
  }

  Future<void> _fetchWeather(String city) async {
    const apiKey = 'ea71a51c210c3fa6760039a8b592c19c'; // z. B. openweathermap
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
          'Fajr': _formatTimeFromMinutes(fajr),
          'Dhuhr': _formatTimeFromMinutes(dhuhr),
          'Asr': _formatTimeFromMinutes(asr),
          'Maghrib': _formatTimeFromMinutes(maghrib),
          'Isha': _formatTimeFromMinutes(isha),
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

      tasks.add(
        _DashboardTask(
          appointmentId: ap.id, // NEU: Halten wir die ID fest
          title: ap.subject,
          startTime: _formatDateTime(start),
          endTime: _formatDateTime(end),
          durationInMinutes: diff,
          description: desc,
          color: ap.color,
        ),
      );
    }

    setState(() {
      _todayTasks = tasks;
      _isAppointmentsLoading = false;
    });
  }

  /// Hilfsfunktion, um totalMinutes in passendes Format umzuwandeln
  String _formatTimeFromMinutes(int? totalMinutes) {
    if (totalMinutes == null) return '--:--';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  /// Start-/Endzeit
  String _formatDateTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
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

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final now = DateTime.now();
    final dateFormatter =
        DateFormat('d MMMM yyyy', _mapAppLanguageToCode(loc.currentLanguage));
    final weekdayFormatter =
        DateFormat('EEEE', _mapAppLanguageToCode(loc.currentLanguage));
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
                Text(
                  '$dateString, $weekdayString',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Wetter + Gebetszeiten
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
                          return InkWell(
                            onTap: () async {
                              // <<< NEU: Termin-Details anzeigen >>>
                              if (t.appointmentId != null) {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => AppointmentDetailsPage(
                                      appointmentId: t.appointmentId!,
                                    ),
                                  ),
                                );
                                // Nach Rückkehr reload
                                reloadData();
                              }
                            },
                            child: Container(
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(t.description),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
          loc.weather,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _weatherTemp ?? '--',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _weatherSymbol ?? '',
          style: const TextStyle(fontSize: 28),
        ),
        const Spacer(),
        Text(
          _weatherLocation ?? '--',
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

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';
    } else {
      return '${minutes}m';
    }
  }
}

class _DashboardTask {
  final int? appointmentId;
  final String title;
  final String startTime;
  final String endTime;
  final int durationInMinutes;
  final String description;
  final Color color;

  _DashboardTask({
    this.appointmentId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationInMinutes,
    required this.description,
    required this.color,
  });
}
