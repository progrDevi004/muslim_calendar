// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization/app_localizations.dart';
import 'ui/pages/home_page.dart';

// >>> NEU HINZUGEFÜGT <<<
import 'package:muslim_calendar/providers/theme_notifier.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Dein vorhandenes Localization-Provider-Setup
        ChangeNotifierProvider(
          create: (_) => AppLocalizations(),
        ),
        // >>> NEU: ThemeNotifier <<<
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // >>> Info: Wir lesen isDarkMode aus dem ThemeNotifier <<<
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final bool isDark = themeNotifier.isDarkMode;

    // Du hast schon ein Seed-Farbschema (z. B. Blau)
    const seedColor = Color(0xFF4285F4);

    // >>> Hier bauen wir dein Light-Theme (z. B. dein bisheriges) <<<
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
            borderRadius: BorderRadius.all(Radius.circular(8))),
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
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.black54)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? seedColor
                  : Colors.black54,
              fontWeight: FontWeight.w500,
            )),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );

    // >>> Beispiel für Dark-Theme <<<
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
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.white70)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? seedColor
                  : Colors.white70,
              fontWeight: FontWeight.w500,
            )),
      ),
    );

    return MaterialApp(
      title: 'Muslim Calendar',
      debugShowCheckedModeBanner: false,
      // >>> Du lässt es bei HomePage
      // >>> Dort ist nun Index=0 => Dashboard, Index=1 => Month, etc.
      theme: isDark ? darkTheme : lightTheme,
      home: const HomePage(),
    );
  }
}
