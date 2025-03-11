// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';
// ThemeNotifier
import 'package:muslim_calendar/providers/theme_notifier.dart';
// HomePage
import 'package:muslim_calendar/ui/pages/home_page.dart';
// InitialLocationPage
import 'package:muslim_calendar/ui/pages/initial_location_page.dart';

// NotificationService
import 'package:muslim_calendar/data/services/notification_service.dart';
// PrayerTimeService und zugehöriges Repository
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';

import 'data/repositories/appointment_repository.dart';
import 'data/repositories/prayer_time_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/services/calendar_sync_service.dart';
import 'data/services/google_calendar_service.dart';
import 'data/services/recurrence_service.dart';
import 'data/services/google_calendar_sync_service.dart';
import 'data/repositories/google_event_mapping_repository.dart';
import 'ui/widgets/prayer_time_appointment_adapter.dart';

void main() async {
  // Widgets binding sicherstellen, da asynchrone Aufrufe vor runApp durchgeführt werden sollen.
  WidgetsFlutterBinding.ensureInitialized();

  // NotificationService initialisieren (und ggf. um Berechtigung fragen, wenn iOS)
  try {
    await NotificationService().init();
  } catch (e) {
    // Bei Fehlern mit dem NotificationService loggen, aber App trotzdem starten
    debugPrint("Fehler bei der Initialisierung des NotificationService: $e");
  }

  // Repositories erstellen
  final appointmentRepository = AppointmentRepository();
  final prayerTimeRepository = PrayerTimeRepository();
  final googleEventMappingRepository = GoogleEventMappingRepository();
  final categoryRepository = CategoryRepository();

  // Services erstellen
  final prayerTimeService = PrayerTimeService(prayerTimeRepository);
  final recurrenceService = RecurrenceService();

  // Google Calendar Service erstellen
  final googleCalendarService =
      GoogleCalendarService.withPrayerTimeService(prayerTimeService);

  // Adapter für die Terminumwandlung erstellen
  final prayerTimeAppointmentAdapter = PrayerTimeAppointmentAdapter(
    prayerTimeService: prayerTimeService,
    recurrenceService: recurrenceService,
  );

  // Google Calendar Sync Service erstellen
  final googleCalendarSyncService = GoogleCalendarSyncService(
    appointmentRepo: appointmentRepository,
    prayerTimeService: prayerTimeService,
    mappingRepo: googleEventMappingRepository,
    appointmentAdapter: prayerTimeAppointmentAdapter,
  );

  // Calendar Sync Service erstellen
  final calendarSyncService = CalendarSyncService(
    calendarProvider: googleCalendarService,
    appointmentRepository: appointmentRepository,
    categoryRepository: categoryRepository,
    recurrenceService: recurrenceService,
    prayerTimeService: prayerTimeService,
    googleCalendarSyncService: googleCalendarSyncService,
  );

  // Verbindung zwischen Repository und Sync Service herstellen
  appointmentRepository.setGoogleSyncService(googleCalendarSyncService);

  runApp(
    MultiProvider(
      providers: [
        // Localization-Provider
        ChangeNotifierProvider(
          create: (_) => AppLocalizations(),
        ),
        // ThemeNotifier-Provider
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(),
        ),
        // PrayerTimeService als Provider
        ChangeNotifierProvider(
          create: (_) => prayerTimeService,
        ),
        // Google Calendar Service als Provider
        Provider(
          create: (_) => googleCalendarService,
        ),
        // Calendar Sync Service als Provider
        Provider(
          create: (_) => calendarSyncService,
        ),
        // Google Calendar Sync Service als Provider
        ChangeNotifierProvider(
          create: (_) => googleCalendarSyncService,
        ),
        // Repository als Provider
        Provider(
          create: (_) => appointmentRepository,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Prüft, ob der Nutzer bereits einen Standort festgelegt hat.
  late Future<bool> _locationCheckFuture;

  @override
  void initState() {
    super.initState();
    _locationCheckFuture = _checkInitialLocation();
  }

  /// Prüft in SharedPreferences, ob 'wasLocationAsked' bereits true ist.
  Future<bool> _checkInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final wasAsked = prefs.getBool('wasLocationAsked') ?? false;
    return wasAsked;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeMode = themeNotifier.currentThemeMode;

    // Basiskonfiguration: Seed-Farbe
    const seedColor = Color(0xFF4285F4);

    // -------------------------
    // Light Theme
    // -------------------------
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Color.fromARGB(255, 245, 245, 245),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(seedColor),
        trackColor: WidgetStateProperty.all(seedColor.withOpacity(0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: seedColor.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.black54,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );

    // -------------------------
    // Dark Theme
    // -------------------------
    final ThemeData darkTheme = ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: seedColor.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'Muslim Calendar',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: FutureBuilder<bool>(
        future: _locationCheckFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final wasAsked = snapshot.data ?? false;
          if (!wasAsked) {
            return const InitialLocationPage();
          } else {
            return const HomePage();
          }
        },
      ),
    );
  }
}
