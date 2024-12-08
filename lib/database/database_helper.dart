import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      },
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE appointments ADD COLUMN duration INTEGER');
        }
      },
    );
  }

  Future<int> insertAppointment(PrayerTimeAppointment appointment) async {
    final db = await database;
    return await db.insert(
      'appointments',
      appointment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PrayerTimeAppointment>> getAllAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('appointments');

    return List.generate(maps.length, (i) {
      return PrayerTimeAppointment(
        id: maps[i]['id'],
        startTime: DateTime.parse(maps[i]['startTime']),
        endTime: DateTime.parse(maps[i]['endTime']),
        subject: maps[i]['subject'],
        color: Color(maps[i]['color']),
        isAllDay: maps[i]['isAllDay'] == 1,
        isRelatedToPrayerTimes: maps[i]['isRelatedToPrayerTimes'] == 1,
        notes: maps[i]['notes'],
        location: maps[i]['location'],
        startTimeZone: maps[i]['startTimeZone'],
        endTimeZone: maps[i]['endTimeZone'],
        recurrenceRule: maps[i]['recurrenceRule'],
        prayerTime: maps[i]['prayerTime'] != null 
            ? PrayerTime.values[maps[i]['prayerTime']] 
            : null,
        timeRelation: maps[i]['timeRelation'] != null 
            ? TimeRelation.values[maps[i]['timeRelation']] 
            : null,
        minutesBeforeAfter: maps[i]['minutesBeforeAfter'],
        duration: maps[i]['duration'] != null 
            ? Duration(minutes: maps[i]['duration']) 
            : null,
      );
    });
  }

  Future<void> updateAppointment(PrayerTimeAppointment appointment) async {
    final db = await database;
    await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
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

  // 2. Tekrarlayan randevular (namaz vakitlerine bağlı olup olmadığına bakılmaksızın)
  final List<Map<String, dynamic>> repeatingMaps = await db.query(
    'appointments',
    where: 'recurrenceRule IS NOT NULL',
  );

  allAppointments.addAll(_mapAppointments(repeatingMaps));

  // 3. Namaz vakitlerine bağlı randevular (tekrarlamayan)
  final List<Map<String, dynamic>> prayerRelatedMaps = await db.query(
    'appointments',
    where: 'isRelatedToPrayerTimes = 1 AND recurrenceRule IS NULL',
  );

  allAppointments.addAll(_mapAppointments(prayerRelatedMaps));

  return allAppointments;
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