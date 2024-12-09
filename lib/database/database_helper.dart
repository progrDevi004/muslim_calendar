import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../widgets/prayer_time_appointment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'appointments.db');
    return await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime TEXT,
            endTime TEXT,
            startTimeZone TEXT,
            endTimeZone TEXT,
            recurrenceRule TEXT,
            recurrenceExceptionDates TEXT,
            isAllDay INTEGER,
            isRelatedToPrayerTimes INTEGER,
            notes TEXT,
            location TEXT,
            subject TEXT,
            color INTEGER,
            prayerTime INTEGER,
            timeRelation INTEGER,
            minutesBeforeAfter INTEGER,
            duration INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE prayer_times (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            location TEXT,
            fajr TEXT,
            dhuhr TEXT,
            asr TEXT,
            maghrib TEXT,
            isha TEXT,
            UNIQUE(date, location)
          )
        ''');
      },
      version: 1,
      onUpgrade: (db, oldVersion, newVersion) async {
      },
    );
  }

  Future<int> insertAppointment(PrayerTimeAppointment appointment) async {
    final db = await database;
    // id'yi Map'ten çıkarıyoruz, böylece veritabanı otomatik olarak atayacak
    final appointmentMap = appointment.toMap()..remove('id');
    return await db.insert(
      'appointments',
      appointmentMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PrayerTimeAppointment>> getAllAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('appointments');
    return List.generate(maps.length, (i) => _createAppointment(maps[i]));
  }

  Future<PrayerTimeAppointment?> getAppointment(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _createAppointment(maps.first);
    }
    return null;
  }

  Future<int> updateAppointment(PrayerTimeAppointment appointment) async {
    final db = await database;
    if (appointment.id == null) {
      throw ArgumentError('Appointment ID cannot be null');
    }
    
    try {
      int updatedRows = await db.update(
        'appointments',
        appointment.toMap(),
        where: 'id = ?',
        whereArgs: [appointment.id is int ? appointment.id : int.parse(appointment.id.toString())],
      );
      
      if (updatedRows == 0) {
        print('No appointment found with ID: ${appointment.id}');
      }
      
      return updatedRows;
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(int id) async {
    final db = await database;
    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PrayerTimeAppointment>> getAppointmentsForDateRange(DateTime start, DateTime end) async {
  final db = await database;
  List<PrayerTimeAppointment> allAppointments = [];
  // 1. Tekrarlamayan ve namaz vakitlerine bağlı olmayan randevular
  final List<Map<String, dynamic>> nonRepeatingNonPrayerMaps = await db.query(
    'appointments',
    where: 'startTime >= ? AND startTime <= ? AND recurrenceRule IS NULL AND isRelatedToPrayerTimes = 0',
    whereArgs: [start.toIso8601String(), end.toIso8601String()],
  );

  allAppointments.addAll(_mapAppointments(nonRepeatingNonPrayerMaps));

  // 2. Tekrarlayan randevular (namaz vakitlerine bağlı olmayan)
  final List<Map<String, dynamic>> repeatingMaps = await db.query(
    'appointments',
    where: 'recurrenceRule IS NOT NULL AND isRelatedToPrayerTimes = 0',
  );

  allAppointments.addAll(_mapAppointments(repeatingMaps));

  // 3. Namaz vakitlerine bağlı randevular (tekrarlamayan)
    final List<Map<String, dynamic>> prayerRelatedMaps = await db.query(
      'appointments',
      where: 'isRelatedToPrayerTimes = 1 AND recurrenceRule IS NULL AND startTime >= ? AND startTime <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    for (var appointment in prayerRelatedMaps) {
      var updatedAppointment = await _updatePrayerRelatedAppointment(appointment);
      if (updatedAppointment != null) {
        allAppointments.add(updatedAppointment);
      }
    }
    print(allAppointments);
    // 4. Namaz vakitlerine bağlı ve tekrarlayan randevular
    // TODO: Bu kısım daha sonra eklenecek

  return allAppointments;
}

Future<PrayerTimeAppointment?> _updatePrayerRelatedAppointment(Map<String, dynamic> appointment) async {
  final db = await database;
  var prayerTimeHour = await _getPrayerTimeFromDatabase(appointment['startTime'], appointment['location'], PrayerTime.values[appointment['prayerTime']]);
  print(prayerTimeHour);
  if (prayerTimeHour == null) {
    return null;
  }
  var prayerTimeHourbyMinutes = int.parse(prayerTimeHour);
  DateTime startTime = DateTime.parse(appointment['startTime']).toLocal();
  startTime = DateTime(startTime.year, startTime.month, startTime.day).add(Duration(minutes: prayerTimeHourbyMinutes));
  startTime = _calculateStartTime(startTime, TimeRelation.values[appointment['timeRelation']], appointment['minutesBeforeAfter']);
  DateTime endTime = startTime.add(Duration(minutes: appointment['duration']));
  return PrayerTimeAppointment(
    id: appointment['id'],
    startTime: startTime,
    endTime: endTime,
    subject: appointment['subject'],
    color: Color(appointment['color']),
    isAllDay: appointment['isAllDay'] == 1,
    isRelatedToPrayerTimes: true,
    notes: appointment['notes'],
    location: appointment['location'],
    prayerTime: PrayerTime.values[appointment['prayerTime']],
    timeRelation: TimeRelation.values[appointment['timeRelation']],
    minutesBeforeAfter: appointment['minutesBeforeAfter'],
    duration: Duration(minutes: appointment['duration']),
  );
}

DateTime _calculateStartTime(DateTime prayerTime, TimeRelation timeRelation, int minutesBeforeAfter) {
  switch (timeRelation) {
    case TimeRelation.before:
      return prayerTime.subtract(Duration(minutes: minutesBeforeAfter));
    case TimeRelation.after:
      return prayerTime.add(Duration(minutes: minutesBeforeAfter));
    default:
      return prayerTime; // Eğer bir ilişki belirtilmemişse, namaz vaktini olduğu gibi döndür
  }
}
Future<String?> _getPrayerTimeFromDatabase(String startTime, String location, PrayerTime prayerTime) async {
  final db = await database;
  final DateTime dateTime = DateTime.parse(startTime).toLocal();
  final String date = dateTime.toString().split(' ')[0];
  final int year = dateTime.year;
  final int month = dateTime.month;

  // Veritabanından ilgili namaz vaktini sorgula
  final List<Map<String, dynamic>> result = await db.query(
    'prayer_times',
    columns: [prayerTime.toString().split('.').last.toLowerCase()],
    where: 'date = ? AND location = ?',
    whereArgs: [date, location],
  );
  print(" RESULTTTTTTTTTTT" + result.toString() + date);

  if (result.isNotEmpty && result.first.values.first != null) {
    // Eğer veri bulunduysa, saat ve dakika olarak döndür
    return result.first.values.first as String;
  } else {
    // Veri bulunamadıysa, API'den çek ve veritabanına kaydet
    final prayerTimes = await _fetchPrayerTimesFromAPI(year, month, location);
    //print(prayerTimes);
    if (prayerTimes != null) {
      await _savePrayerTimesToDatabase(prayerTimes, location);
      
      // Yeni eklenen veriden ilgili namaz vaktini al
      final newResult = await db.query(
        'prayer_times',
        columns: [prayerTime.toString().split('.').last.toLowerCase()],
        where: 'date = ? AND location = ?',
        whereArgs: [date, location],
      );
      //print("newres" + newResult.toString());
      if (newResult.isNotEmpty && newResult.first.values.first != null) {
        return newResult.first.values.first as String;
      }
    }
  }
  
  // Eğer hala veri bulunamadıysa null döndür
  return null;
}

Future<Map<String, Map<String, String>>> _fetchPrayerTimesFromAPI(int year, int month, String location) async {
  final url = 'https://api.aladhan.com/v1/calendarByAddress/$year/$month?address=$location';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final Map<String, Map<String, String>> prayerTimes = {};

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

    return prayerTimes;
  } else {
    throw Exception('Failed to load prayer times from API');
  }
}


int _timeToMinutes(String timeString) {
  // Parantez içindeki kısmı kaldır
  String cleanTime = timeString.split(' ')[0];
  
  // Saat ve dakikayı ayır
  List<String> parts = cleanTime.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  
  // Toplam dakikayı hesapla ve döndür
  return hours * 60 + minutes;
}

String _formatDate(String inputDate) {
  // Gelen tarih formatını parse et
  final parts = inputDate.split('-');
  if (parts.length == 3) {
    // Yıl-Ay-Gün formatına dönüştür
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }
  // Eğer format beklendiği gibi değilse, orijinal tarihi döndür
  return inputDate;
}
Future<void> _savePrayerTimesToDatabase(Map<String, Map<String, String>> prayerTimes, String location) async {
  final Database db = await database;
  final Batch batch = db.batch();

  prayerTimes.forEach((date, timings) {
    batch.insert(
      'prayer_times',
      {
        'date': _formatDate(date),
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
  //await _printAllPrayerTimes(db);
}

Future<void> _printAllPrayerTimes(Database db) async {
  final List<Map<String, dynamic>> prayerTimes = await db.query('prayer_times');
  print('Tüm Namaz Vakitleri:');
  prayerTimes.forEach((row) {
    print('Tarih: ${row['date']}, Konum: ${row['location']}');
    print('  Fajr: ${(row['fajr'])}');
    print('  Dhuhr: ${(row['dhuhr'])}');
    print('  Asr: ${(row['asr'])}');
    print('  Maghrib: ${(row['maghrib'])}');
    print('  Isha: ${(row['isha'])}');
    print('-------------------');
  });
}

String _minutesToTime(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
}


List<PrayerTimeAppointment> _mapAppointments(List<Map<String, dynamic>> maps) {
  return maps.map((map) => _createAppointment(map)).toList();
}

PrayerTimeAppointment _createAppointment(Map<String, dynamic> map) {
  return PrayerTimeAppointment(
    id: map['id'],
    startTime: DateTime.parse(map['startTime']),
    endTime: DateTime.parse(map['endTime']),
    subject: map['subject'],
    color: Color(map['color']),
    isAllDay: map['isAllDay'] == 1,
    isRelatedToPrayerTimes: map['isRelatedToPrayerTimes'] == 1,
    notes: map['notes'],
    location: map['location'],
    startTimeZone: map['startTimeZone'],
    endTimeZone: map['endTimeZone'],
    recurrenceRule: map['recurrenceRule'],
    recurrenceExceptionDates: map['recurrenceExceptionDates'] != null
        ? (json.decode(map['recurrenceExceptionDates']) as List)
            .map((item) => DateTime.parse(item))
            .toList()
        : null,

    prayerTime: map['prayerTime'] != null 
        ? PrayerTime.values[map['prayerTime']] 
        : null,
    timeRelation: map['timeRelation'] != null 
        ? TimeRelation.values[map['timeRelation']] 
        : null,
    minutesBeforeAfter: map['minutesBeforeAfter'],
    duration: map['duration'] != null 
        ? Duration(minutes: map['duration']) 
        : null,
  );
}
}