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
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/services/calendar_sync_service.dart';
import 'data/services/google_calendar_service.dart';
import 'data/services/recurrence_service.dart';
import 'data/services/google_calendar_sync_service.dart';
import 'data/repositories/google_event_mapping_repository.dart';
import 'ui/widgets/prayer_time_appointment_adapter.dart';
import 'data/services/location_service.dart';
// NEU: Importiere plattformadaptives Theme
import 'ui/components/platform_adaptive_theme.dart';
// Für Lokalisierung
import 'package:flutter_localizations/flutter_localizations.dart';

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
    categoryRepo: categoryRepository,
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
        // CategoryRepository als Provider
        Provider<CategoryRepository>(
          create: (_) => categoryRepository,
        ),
        // LocationService bereitstellen
        ChangeNotifierProvider<LocationService>(
          create: (context) {
            final locationService = LocationService();
            // Initialisierung starten
            locationService.initialize();
            return locationService;
          },
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
        ChangeNotifierProvider(
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

    // Lade die gespeicherte Spracheinstellung beim App-Start
    _loadSavedLanguage();
  }

  /// Lädt die gespeicherte Spracheinstellung aus SharedPreferences
  /// und setzt sie im AppLocalizations-Provider
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageIndex = prefs.getInt('selectedLanguageIndex');

    if (savedLanguageIndex != null &&
        savedLanguageIndex >= 0 &&
        savedLanguageIndex < AppLanguage.values.length) {
      // Verzögerung hinzufügen, um sicherzustellen, dass der Provider verfügbar ist
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      // Setze die gespeicherte Sprache im Provider
      final appLocalizations =
          Provider.of<AppLocalizations>(context, listen: false);
      appLocalizations.setLanguage(AppLanguage.values[savedLanguageIndex]);

      debugPrint(
          '🌐 Gespeicherte Spracheinstellung geladen: ${AppLanguage.values[savedLanguageIndex]}');
    }
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

    // NEU: Plattformadaptive Themes verwenden
    final lightTheme = PlatformAdaptiveTheme.getLightTheme(context);
    final darkTheme = PlatformAdaptiveTheme.getDarkTheme(context);

    return MaterialApp(
      title: Provider.of<AppLocalizations>(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Übersetzungen bekannt machen
      localizationsDelegates: const [
        // Flutter Standard-Übersetzungen
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'), // Deutsch
        Locale('en'), // Englisch
        Locale('tr'), // Türkisch
        Locale('ar'), // Arabisch
      ],
      // Light, Dark oder System-Theme verwenden
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: FutureBuilder<bool>(
        future: _locationCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          final bool wasLocationAsked = snapshot.data ?? false;
          if (!wasLocationAsked) {
            return const InitialLocationPage();
          }
          return const HomePage();
        },
      ),
    );
  }
}
