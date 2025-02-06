// lib/data/repositories/prayer_time_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/models/enums.dart';
import '../database_helper.dart';

class PrayerTimeRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // >>> NEU: Machen wir es einfach per Getter:
  DatabaseHelper get databaseHelper => dbHelper;

  // Prüft, ob wir schon das ganze Jahr im DB-Cache haben.
  Future<bool> _hasFullYearInDB(int year, String location) async {
    final db = await dbHelper.database;

    // Alles kleinschreiben, um Konsistenz zu bewahren
    final locLower = location.toLowerCase();
    final startOfYear = '$year-01-01';
    final endOfYear = '$year-12-31';

    final countQuery = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM prayer_times "
      "WHERE LOWER(location) = ? AND date >= ? AND date <= ?",
      [locLower, startOfYear, endOfYear],
    );

    final dbCount = countQuery.first['cnt'] as int? ?? 0;
    // Wenn wir >= 365 Einträge haben, gehen wir davon aus, dass das Jahr vollständig ist.
    return dbCount >= 365;
  }

  // Lädt Gebetszeiten für ein ganzes Jahr monatsweise
  Future<void> fetchAndSaveYearlyPrayerTimes(int year, String location) async {
    // Alles kleinschreiben, damit in DB einheitlich gespeichert wird
    location = location.trim().toLowerCase();

    final hasYear = await _hasFullYearInDB(year, location);
    if (hasYear) {
      return;
    }

    for (int month = 1; month <= 12; month++) {
      final hasFullMonth = await _hasFullMonthInDB(year, month, location);
      if (!hasFullMonth) {
        await _fetchAndSaveMonthlyPrayerTimes(year, month, location);
      }
    }
  }

  Future<int?> getPrayerTimeMinutes(
      DateTime date, String location, PrayerTime prayerTime) async {
    final db = await dbHelper.database;
    // Auch hier => klein schreiben
    location = location.trim().toLowerCase();

    final String dateString = _formatDate(date);
    final prayerName = prayerTime.toString().split('.').last.toLowerCase();

    final List<Map<String, dynamic>> result = await db.query(
      'prayer_times',
      columns: [prayerName],
      where: 'date = ? AND LOWER(location) = ?',
      whereArgs: [dateString, location],
    );

    if (result.isNotEmpty && result.first.values.first != null) {
      return int.tryParse(result.first.values.first.toString());
    } else {
      // Daten fehlen => wir laden (falls nicht schon vorhanden) die Daten neu
      await _fetchAndSaveMonthlyPrayerTimes(date.year, date.month, location);

      final newResult = await db.query(
        'prayer_times',
        columns: [prayerName],
        where: 'date = ? AND LOWER(location) = ?',
        whereArgs: [dateString, location],
      );
      if (newResult.isNotEmpty && newResult.first.values.first != null) {
        return int.tryParse(newResult.first.values.first.toString());
      }
    }

    return null;
  }

  /// Liefert alle Zeilen aus prayer_times, die im Bereich [startDate, endDate] liegen
  Future<List<Map<String, dynamic>>> getPrayerTimesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);

    // Wir holen erstmal alle Gebetszeiten, filtern später nach location
    final result = await db.query(
      'prayer_times',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
    );

    return result;
  }

  /// Lädt die Gebetszeiten für den angegebenen Monat, sofern sie noch nicht gespeichert sind
  Future<void> _fetchAndSaveMonthlyPrayerTimes(
    int year,
    int month,
    String location,
  ) async {
    final hasData = await _hasFullMonthInDB(year, month, location);
    if (hasData) {
      return;
    }

    // Berechnungsmethode aus SharedPreferences (Default: 13 = Diyanet)
    final prefs = await SharedPreferences.getInstance();
    final calcMethod = prefs.getInt('calculationMethod') ?? 13;

    // >>> KORREKTES ENCODING
    final encodedLoc = Uri.encodeQueryComponent(location);

    final url =
        'https://api.aladhan.com/v1/calendarByAddress/$year/$month?address=$encodedLoc&method=$calcMethod';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      Map<String, Map<String, String>> prayerTimes = {};
      for (var dayData in jsonData['data']) {
        final date = dayData['date']['gregorian']['date']; // z.B. "18-05-2024"
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
      throw Exception(
          'Failed to load prayer times from API (status code: ${response.statusCode}).');
    }
  }

  /// Prüft, ob wir bereits ALLE Tage eines Monats in der DB haben (monatsweiser Cache)
  Future<bool> _hasFullMonthInDB(int year, int month, String location) async {
    final db = await dbHelper.database;
    final daysInMonth = _getDaysInMonth(year, month);

    // => z. B. "2024-05-"
    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}-';

    // Wieder: wir speichern location in Kleinbuchstaben
    final locLower = location.toLowerCase();

    final countQuery = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM prayer_times "
      "WHERE LOWER(location) = ? AND date LIKE ?",
      [locLower, '$monthPrefix%'],
    );

    final dbCount = countQuery.first['cnt'] as int? ?? 0;
    return dbCount >= daysInMonth;
  }

  int _getDaysInMonth(int year, int month) {
    final firstNextMonth =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDayCurrentMonth =
        firstNextMonth.subtract(const Duration(days: 1)).day;
    return lastDayCurrentMonth;
  }

  Future<void> _savePrayerTimesToDatabase(
    Map<String, Map<String, String>> prayerTimes,
    String location,
  ) async {
    final Database db = await dbHelper.database;
    final Batch batch = db.batch();

    // location bleibt in Kleinbuchstaben
    location = location.toLowerCase();

    prayerTimes.forEach((date, timings) {
      batch.insert(
        'prayer_times',
        {
          'date': _formatDateString(date), // "18-05-2024" => "2024-05-18"
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
    // "05:10 (EET)" => vor Leerzeichen trennen
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

  /// "18-05-2024" => "2024-05-18"
  String _formatDateString(String inputDate) {
    final parts = inputDate.split('-');
    final dd = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    final yyyy = parts[2].padLeft(4, '0');
    return '$yyyy-$mm-$dd';
  }
}
