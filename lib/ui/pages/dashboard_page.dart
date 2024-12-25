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

// Detailseite
import 'package:muslim_calendar/ui/pages/appointment_details_page.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';

import 'package:muslim_calendar/data/services/prayer_time_service.dart'; // <-- Für getCalculatedStartTime / getCalculatedEndTime

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

  // Für die Anzeige im kleinen Kasten oben
  Map<String, String> _todayPrayerTimesDisplay = {};
  String? _prayerTimeErrorMessage;

  // Für die exakte Zeitberechnung (z. B. 05:12 => 312 Minuten)
  Map<PrayerTime, int?> _todayPrayerTimesMinutes = {};

  List<_DashboardTask> _todayTasks = [];

  final PrayerTimeRepository _prayerTimeRepo = PrayerTimeRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // Berechnete Start-/Endzeiten
  late final PrayerTimeService _prayerTimeService;

  // 24h- vs AM/PM-Format
  bool _use24hFormat = false;

  // Einstellung: Gebetszeiten-Slots anzeigen oder nicht
  bool _showPrayerSlotsInDashboard = true;

  // Hover-Status (für Animation/Effekt)
  int? _hoveredTaskId;

  @override
  void initState() {
    super.initState();
    _prayerTimeService = PrayerTimeService(_prayerTimeRepo);
    _initData();
  }

  /// Ermöglicht Reload von außen (z. B. HomePage)
  Future<void> reloadData() async {
    await _initData();
  }

  Future<void> _initData() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final languageCode = _mapAppLanguageToCode(loc.currentLanguage);
    await initializeDateFormatting(languageCode, null);

    final prefs = await SharedPreferences.getInstance();
    _use24hFormat = prefs.getBool('use24hFormat') ?? false;

    // Gebets-Slots-Einstellung laden
    _showPrayerSlotsInDashboard =
        prefs.getBool('showPrayerSlotsInDashboard') ?? true;

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

  /// Wetter abrufen
  Future<void> _fetchWeather(String city) async {
    const apiKey = 'ea71a51c210c3fa6760039a8b592c19c'; // example key
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

  /// Gebetszeiten für heute abrufen
  Future<void> _fetchPrayerTimesForToday(String location) async {
    final now = DateTime.now();
    final loc = Provider.of<AppLocalizations>(context, listen: false);
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

      // Für die Anzeige oben
      _todayPrayerTimesDisplay = {
        loc.getPrayerTimeLabel(PrayerTime.fajr):
            _formatTimeFromMinutes(fajr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.dhuhr):
            _formatTimeFromMinutes(dhuhr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.asr):
            _formatTimeFromMinutes(asr ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.maghrib):
            _formatTimeFromMinutes(maghrib ?? -1),
        loc.getPrayerTimeLabel(PrayerTime.isha):
            _formatTimeFromMinutes(isha ?? -1),
      };

      // Rohwerte zum Einsortieren
      _todayPrayerTimesMinutes = {
        PrayerTime.fajr: fajr,
        PrayerTime.dhuhr: dhuhr,
        PrayerTime.asr: asr,
        PrayerTime.maghrib: maghrib,
        PrayerTime.isha: isha,
      };

      setState(() {
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

  /// Heutige Termine + (optional) Gebetszeiten-Slots laden
  Future<void> _loadTodaysAppointments() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

    final all = await _appointmentRepo.getAllAppointments();
    final tasks = <_DashboardTask>[];

    // 1) Normale Termine berechnen und hinzufügen
    for (var ap in all) {
      final calculatedStart =
          await _prayerTimeService.getCalculatedStartTime(ap, now);
      final s = calculatedStart ?? (ap.startTime ?? now);

      final calculatedEnd =
          await _prayerTimeService.getCalculatedEndTime(ap, now);
      final e = calculatedEnd ?? s.add(const Duration(minutes: 30));

      if (e.isAfter(startOfDay) && s.isBefore(endOfDay)) {
        final diff = e.difference(s).inMinutes;
        final desc = ap.notes ?? '';

        tasks.add(
          _DashboardTask(
            appointmentId: ap.id,
            isPrayerSlot: false,
            title: ap.subject,
            start: s,
            end: e,
            durationInMinutes: diff,
            description: desc,
            color: ap.color,
          ),
        );
      }
    }

    // 2) Gebetszeiten-Slots einsortieren (falls Einstellung aktiv)
    if (_showPrayerSlotsInDashboard) {
      final baseDay = DateTime(now.year, now.month, now.day);
      for (final entry in _todayPrayerTimesMinutes.entries) {
        final prayerTime = entry.key;
        final minutes = entry.value;
        if (minutes == null) continue; // Keine Daten => skip
        if (minutes < 0) continue; // Fehler oder invalid => skip

        final dtStart = baseDay.add(Duration(minutes: minutes));
        if (dtStart.isAfter(endOfDay) || dtStart.isBefore(startOfDay)) {
          // Außerhalb des heutigen Tages
          continue;
        }

        // Wählen wir hier 0 oder 1 Minute => minimal
        final dtEnd = dtStart.add(const Duration(minutes: 1));

        tasks.add(
          _DashboardTask(
            appointmentId: null,
            isPrayerSlot: true,
            title: _prayerTimeLabel(prayerTime), // z.B. "Fajr"
            start: dtStart,
            end: dtEnd,
            durationInMinutes: 1,
            description: '', // Kein extra Text
            color: Colors.teal, // Einheitliche Farbe für Gebets-Slots
          ),
        );
      }
    }

    // 3) Sortierung nach Startzeit
    tasks.sort((a, b) => a.start.compareTo(b.start));

    setState(() {
      _todayTasks = tasks;
      _isAppointmentsLoading = false;
    });
  }

  /// Gibt den Label-Text für den Gebets-Slot zurück
  String _prayerTimeLabel(PrayerTime pt) {
    switch (pt) {
      case PrayerTime.fajr:
        return 'Fajr';
      case PrayerTime.dhuhr:
        return 'Dhuhr';
      case PrayerTime.asr:
        return 'Asr';
      case PrayerTime.maghrib:
        return 'Maghrib';
      case PrayerTime.isha:
        return 'Isha';
    }
  }

  /// Erzeugt ein Zeit-String aus totalMinutes
  /// Falls -1 oder null => "--:--"
  String _formatTimeFromMinutes(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes < 0) {
      return '--:--';
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  /// Konvertiert in z. B. "en", "de" ...
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

  /// Wetter-Symbol anhand einfacher Schlagwörter
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

  /// Neuer Termin
  void _createQuickAppointment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AppointmentCreationPage(),
      ),
    );
    reloadData();
  }

  /// Hover-Handling
  void _onHoverEnter(int taskId) {
    setState(() {
      _hoveredTaskId = taskId;
    });
  }

  void _onHoverExit(int taskId) {
    setState(() {
      if (_hoveredTaskId == taskId) {
        _hoveredTaskId = null;
      }
    });
  }

  /// Kontrastfarbe für Text
  Color _getContrastingTextColor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Formatierung einer DateTime zu String (z. B. "14:30")
  String _formatDateTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
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

    final Color mainColor = Theme.of(context).colorScheme.primary;
    // Dark Mode => höhere Opazität für Kacheln
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentCardColor = mainColor.withOpacity(isDark ? 0.3 : 0.1);
    final Color accentTextColor = mainColor.withOpacity(isDark ? 0.9 : 0.7);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: _createQuickAppointment,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Datum-Karte
              Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 24,
                        color: mainColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$dateString, $weekdayString',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Wetter + Gebetszeiten
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentCardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildWeatherTile(context, loc, accentTextColor),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentCardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            _buildPrayerTimeTile(context, loc, accentTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.task_alt, color: mainColor),
                  const SizedBox(width: 8),
                  Text(
                    loc.upcomingTasksLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _isAppointmentsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: _todayTasks.map((t) {
                        if (t.isPrayerSlot) {
                          // Spezielle Darstellung
                          return _buildPrayerSlotItem(t);
                        } else {
                          return _buildAppointmentItem(t);
                        }
                      }).toList(),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// UI-Element für einen normalen Termin (kein Gebetsslot)
  Widget _buildAppointmentItem(_DashboardTask t) {
    final backgroundColor = t.color;
    final textColor = _getContrastingTextColor(backgroundColor);
    final startStr = _formatDateTime(t.start);
    final endStr = _formatDateTime(t.end);

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(t.appointmentId ?? 0),
      onExit: (_) => _onHoverExit(t.appointmentId ?? 0),
      child: InkWell(
        splashColor: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (t.appointmentId != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => AppointmentDetailsPage(
                  appointmentId: t.appointmentId!,
                ),
              ),
            );
            reloadData();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hoveredTaskId == t.appointmentId
                ? [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDuration(t.durationInMinutes),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startStr - $endStr',
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UI-Element für einen Gebetsslot (nicht klickbar)
  Widget _buildPrayerSlotItem(_DashboardTask t) {
    final timeStr = _formatDateTime(t.start);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade400,
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // z.B. "Fajr"
                Text(
                  t.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                // z.B. "05:30 am"
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Baut das kleine Wetter-Kästchen
  Widget _buildWeatherTile(
      BuildContext context, AppLocalizations loc, Color accentTextColor) {
    if (_isWeatherLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherErrorMessage != null) {
      return Text(
        _weatherErrorMessage!,
        style: TextStyle(color: Colors.red.shade400),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: accentTextColor),
            const SizedBox(width: 8),
            Text(
              loc.weather,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _weatherTemp ?? '--',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: accentTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _weatherSymbol ?? '',
          style: TextStyle(
            fontSize: 28,
            color: accentTextColor,
          ),
        ),
        const Spacer(),
        Text(
          _weatherLocation ?? '--',
          style: theme.textTheme.bodySmall?.copyWith(
            color: accentTextColor,
          ),
        ),
      ],
    );
  }

  /// Baut das kleine Gebetszeiten-Kästchen
  Widget _buildPrayerTimeTile(
      BuildContext context, AppLocalizations loc, Color accentTextColor) {
    if (_isPrayerTimesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prayerTimeErrorMessage != null) {
      return Text(
        _prayerTimeErrorMessage!,
        style: TextStyle(color: Colors.red.shade400),
      );
    }
    if (_todayPrayerTimesDisplay.isEmpty) {
      return Text('${loc.prayerTimeDashboard}\n--');
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_alarm_outlined, color: accentTextColor),
            const SizedBox(width: 8),
            Text(
              loc.prayerTimeDashboard,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._todayPrayerTimesDisplay.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentTextColor,
                  ),
                ),
                Text(
                  e.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  /// Menschliche Anzeige für die Dauer (z. B. "1h 30m")
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
  final bool isPrayerSlot;
  final String title;
  final DateTime start;
  final DateTime end;
  final int durationInMinutes;
  final String description;
  final Color color;

  _DashboardTask({
    this.appointmentId,
    required this.isPrayerSlot,
    required this.title,
    required this.start,
    required this.end,
    required this.durationInMinutes,
    required this.description,
    required this.color,
  });
}
