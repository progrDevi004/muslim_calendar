//data/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT,
            notes TEXT,
            isAllDay INTEGER,
            isRelatedToPrayerTimes INTEGER,
            prayerTime INTEGER,
            timeRelation INTEGER,
            minutesBeforeAfter INTEGER,
            duration INTEGER,
            location TEXT,
            recurrenceRule TEXT,
            recurrenceExceptionDates TEXT,
            color INTEGER,
            startTime TEXT,
            endTime TEXT
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
    );
  }
}
