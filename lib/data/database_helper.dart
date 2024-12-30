// lib/data/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // >>> Version von 3 auf 4 erhöht
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'appointments.db');
    return await openDatabase(
      path,
      version: 4, // <-- NEU: DB-Version raufgesetzt
      onCreate: (db, version) async {
        // Version 4 bedeutet, wir führen gleich alles an.

        // appointments
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
            reminderMinutesBefore INTEGER,

            -- NEU ab Version 4:
            externalIdGoogle TEXT,
            externalIdOutlook TEXT,
            externalIdApple TEXT,
            lastSyncedAt TEXT
          )
        ''');

        // prayer_times
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

        // categories
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            colorValue INTEGER
          )
        ''');

        // Standard-Kategorien einfügen
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
        // Hier handle Upgrades von älteren Versionen:

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

        if (oldVersion < 3) {
          // Version 3 => Spalte reminderMinutesBefore
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN reminderMinutesBefore INTEGER
          ''');
        }

        // >>> NEU: Wenn von <3 hoch auf 4, müssen wir
        // ebenfalls die reminderMinutesBefore-Spalte noch ergänzen (siehe oben).
        // Dann erst die neuen Spalten:

        if (oldVersion < 4) {
          // Die neuen Spalten für externe Sync:
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN externalIdGoogle TEXT
          ''');
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN externalIdOutlook TEXT
          ''');
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN externalIdApple TEXT
          ''');
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN lastSyncedAt TEXT
          ''');
        }
      },
    );
  }
}
