// lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:muslim_calendar/data/services/outlook_calendar_api.dart';
import 'package:muslim_calendar/data/services/outlook_sync_service.dart';
import 'package:provider/provider.dart';

// Deine Localization
import 'package:muslim_calendar/localization/app_localizations.dart';
// Deine HomePage
import 'package:muslim_calendar/ui/pages/home_page.dart';
// Dein ThemeNotifier
import 'package:muslim_calendar/providers/theme_notifier.dart';

// NEU: Für Standort-Erstabfrage
import 'package:muslim_calendar/ui/pages/initial_location_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NEU: NotificationService-Import
import 'package:muslim_calendar/data/services/notification_service.dart';

import 'data/repositories/appointment_repository.dart';
import 'data/repositories/prayer_time_repository.dart';
import 'data/services/google_sync_service.dart';
import 'data/services/google_calendar_api.dart';
import 'data/services/prayer_time_service.dart';
import 'data/services/recurrence_service.dart';

void main() async {
  // Damit wir vor dem runApp asynchrone Aufrufe durchführen können:
  WidgetsFlutterBinding.ensureInitialized();

  // NotificationService initialisieren + (falls iOS) um Erlaubnis fragen
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        // Localization-Provider
        ChangeNotifierProvider(
          create: (_) => AppLocalizations(),
        ),
        // ThemeNotifier => für Dark/Light/System
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(),
        ),
        Provider<AppointmentRepository>(
          create: (_) => AppointmentRepository(),
        ),
        Provider<RecurrenceService>(
          create: (_) => RecurrenceService(),
        ),
        Provider<PrayerTimeService>(
          create: (_) => PrayerTimeService(PrayerTimeRepository()),
        ),

        Provider<GoogleCalendarApi>(create: (_) => GoogleCalendarApi()),
        Provider<OutlookCalendarApi>(create: (_) => OutlookCalendarApi()),
        
        // Ardından, CalendarSyncService nesnelerini oluşturuyoruz:
        Provider<GoogleSyncService>(
          create: (context) => GoogleSyncService(
            calendarProvider: context.read<GoogleCalendarApi>(),
            appointmentRepository: context.read<AppointmentRepository>(),
            recurrenceService: context.read<RecurrenceService>(),
            prayerTimeService: context.read<PrayerTimeService>(),
          ),
        ),
        Provider<OutlookSyncService>(
          create: (context) => OutlookSyncService(
            calendarProvider: context.read<OutlookCalendarApi>(),
            appointmentRepository: context.read<AppointmentRepository>(),
            recurrenceService: context.read<RecurrenceService>(),
            prayerTimeService: context.read<PrayerTimeService>(),
          ),
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
  // Wir prüfen hier, ob der Nutzer bereits einen Standort festgelegt hat.
  late Future<bool> _locationCheckFuture;

  @override
  void initState() {
    super.initState();
    _locationCheckFuture = _checkInitialLocation();
  }

  /// Prüft in SharedPreferences, ob 'wasLocationAsked' bereits true ist.
  /// Falls nicht, führen wir den Nutzer zuerst durch die Standort-Abfrage.
  Future<bool> _checkInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final wasAsked = prefs.getBool('wasLocationAsked') ?? false;
    return wasAsked;
  }

  @override
  Widget build(BuildContext context) {
    // Unser ThemeNotifier, damit wir themeMode auslesen können
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

      // Wichtig: Wir nutzen nun themeMode
      themeMode: themeMode,

      theme: lightTheme,
      darkTheme: darkTheme,

      // FutureBuilder, um herauszufinden, ob wir InitialLocationPage oder HomePage anzeigen
      home: FutureBuilder<bool>(
        future: _locationCheckFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Noch laden wir
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final wasAsked = snapshot.data ?? false;
          if (!wasAsked) {
            // Standort noch nicht festgelegt => zum Auswahldialog
            return const InitialLocationPage();
          } else {
            // Standort schon da => direkt zur HomePage
            return const HomePage();
          }
        },
      ),
    );
  }
}
