// lib/data/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // >>> Version von 6 auf 7 erhöht
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'appointments.db');
    return await openDatabase(
      path,
      version: 7, // <-- NEU: DB-Version auf 7 erhöht
      onCreate: (db, version) async {
        // Version 7 bedeutet, wir führen gleich alles an.

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
            recurrenceEndDate TEXT,
            color INTEGER,
            startTime TEXT,
            endTime TEXT,
            categoryId INTEGER,
            reminderMinutesBefore INTEGER,
            externalIdGoogle TEXT,
            externalIdOutlook TEXT,
            externalIdApple TEXT,
            lastSyncedAt TEXT,
            syncWithGoogleCalendar INTEGER DEFAULT 0
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

        // Google Calendar Event Mappings (NEU)
        await db.execute('''
          CREATE TABLE google_event_mappings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_appointment_id INTEGER,
            original_date TEXT,
            google_event_id TEXT,
            last_synced_at TEXT,
            UNIQUE(local_appointment_id, original_date)
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

        if (oldVersion < 5) {
          // Neue Spalte für Google Calendar Sync Flag
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN syncWithGoogleCalendar INTEGER DEFAULT 0
          ''');
        }

        if (oldVersion < 6) {
          // Neue Tabelle für Google Calendar Event Mappings
          await db.execute('''
            CREATE TABLE google_event_mappings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              local_appointment_id INTEGER,
              original_date TEXT,
              google_event_id TEXT,
              last_synced_at TEXT,
              UNIQUE(local_appointment_id, original_date)
            )
          ''');
        }

        if (oldVersion < 7) {
          // Neue Spalte für das Enddatum der Wiederholung
          await db.execute('''
            ALTER TABLE appointments ADD COLUMN recurrenceEndDate TEXT
          ''');
        }
      },
    );
  }
}
