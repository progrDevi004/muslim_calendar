// lib/data/database_helper.dart

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
    // >>> Version auf 3 erhöht
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Version 3 bedeutet, wir führen gleich alles an.
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
            endTime TEXT,
            categoryId INTEGER,

            -- >>> NEU: Spalte für Reminder (in Minuten)
            reminderMinutesBefore INTEGER
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

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            colorValue INTEGER
          )
        ''');

        // >>> Standard-Kategorien einfügen <<<
        await db.insert('categories', {
          'name': 'Privat',
          'colorValue': 0xFF2196F3,
        });
        await db.insert('categories', {
          'name': 'Geschäftlich',
          'colorValue': 0xFF4CAF50,
        });
        await db.insert('categories', {
          'name': 'Islam',
          'colorValue': 0xFFF44336,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN categoryId INTEGER
          ''');
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              colorValue INTEGER
            )
          ''');
          await db.insert('categories', {
            'name': 'Privat',
            'colorValue': 0xFF2196F3,
          });
          await db.insert('categories', {
            'name': 'Geschäftlich',
            'colorValue': 0xFF4CAF50,
          });
          await db.insert('categories', {
            'name': 'Islam',
            'colorValue': 0xFFF44336,
          });
        }

        // >>> Neu: Falls alter DB-Stand < 3 => Spalte reminderMinutesBefore hinzufügen
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN reminderMinutesBefore INTEGER
          ''');
        }
      },
    );
  }
}
