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
      version: 2, // Version bleibt 2 wie zuvor
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
            endTime TEXT,
            categoryId INTEGER
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

        // Neue Tabelle "categories"
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            colorValue INTEGER
          )
        ''');

        // >>> Standard-Kategorien einfügen <<<
        // Du kannst natürlich andere Farben wählen
        await db.insert('categories', {
          'name': 'Privat',
          'colorValue': 0xFF2196F3, // Blau
        });
        await db.insert('categories', {
          'name': 'Geschäftlich',
          'colorValue': 0xFF4CAF50, // Grün
        });
        await db.insert('categories', {
          'name': 'Islam',
          'colorValue': 0xFFF44336, // Rot
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

          // >>> Standard-Kategorien ggf. auch hier einfügen <<<
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
      },
    );
  }
}
