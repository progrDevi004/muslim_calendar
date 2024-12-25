import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/enums.dart';
import '../database_helper.dart';

class PrayerTimeRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int?> getPrayerTimeMinutes(
      DateTime date, String location, PrayerTime prayerTime) async {
    final db = await dbHelper.database;
    final String dateString = _formatDate(date);

    final prayerName = prayerTime.toString().split('.').last.toLowerCase();
    final List<Map<String, dynamic>> result = await db.query(
      'prayer_times',
      columns: [prayerName],
      where: 'date = ? AND location = ?',
      whereArgs: [dateString, location],
    );

    if (result.isNotEmpty && result.first.values.first != null) {
      return int.tryParse(result.first.values.first.toString());
    } else {
      // Falls nicht vorhanden => wir laden die Daten neu
      await _fetchAndSaveMonthlyPrayerTimes(date.year, date.month, location);
      final newResult = await db.query(
        'prayer_times',
        columns: [prayerName],
        where: 'date = ? AND location = ?',
        whereArgs: [dateString, location],
      );
      if (newResult.isNotEmpty && newResult.first.values.first != null) {
        return int.tryParse(newResult.first.values.first.toString());
      }
    }

    return null;
  }

  /// Lädt über die Aladhan-API die Gebetszeiten für den gesamten Monat [year]/[month]
  /// und speichert sie in die lokale DB. Berücksichtigt die hinterlegte Berechnungsmethode.
  Future<void> _fetchAndSaveMonthlyPrayerTimes(
      int year, int month, String location) async {
    // >>> NEU: Berechnungsmethode aus SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final calcMethod =
        prefs.getInt('calculationMethod') ?? 13; // Standard: Diyanet

    final url =
        'https://api.aladhan.com/v1/calendarByAddress/$year/$month?address=$location&method=$calcMethod';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      Map<String, Map<String, String>> prayerTimes = {};
      for (var dayData in jsonData['data']) {
        final date = dayData['date']['gregorian']['date'];
        final timings = dayData['timings'];
        prayerTimes[date] = {
          'fajr': timings['Fajr'],
          'dhuhr': timings['Dhuhr'],
          'asr': timings['Asr'],
          'maghrib': timings['Maghrib'],
          'isha': timings['Isha'],
        };
      }
      await _savePrayerTimesToDatabase(prayerTimes, location);
    } else {
      throw Exception('Failed to load prayer times from API');
    }
  }

  Future<void> _savePrayerTimesToDatabase(
      Map<String, Map<String, String>> prayerTimes, String location) async {
    final Database db = await dbHelper.database;
    final Batch batch = db.batch();

    prayerTimes.forEach((date, timings) {
      batch.insert(
        'prayer_times',
        {
          'date': _formatDateString(date),
          'location': location,
          'fajr': _timeToMinutes(timings['fajr']!),
          'dhuhr': _timeToMinutes(timings['dhuhr']!),
          'asr': _timeToMinutes(timings['asr']!),
          'maghrib': _timeToMinutes(timings['maghrib']!),
          'isha': _timeToMinutes(timings['isha']!),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }

  int _timeToMinutes(String timeString) {
    // Beispiel: "05:10 (EET)"
    // => Wir nehmen den Part vor dem Leerzeichen
    String cleanTime = timeString.split(' ')[0];
    List<String> parts = cleanTime.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateString(String inputDate) {
    // "18-05-2024" => "2024-05-18"
    final parts = inputDate.split('-');
    final dd = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    final yyyy = parts[2].padLeft(4, '0');
    return '$yyyy-$mm-$dd';
  }
}
