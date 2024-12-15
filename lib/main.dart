import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization/app_localizations.dart';
import 'pages/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppLocalizations(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Google-typische Primärfarbe: Blau (#4285F4)
    final seedColor = const Color(0xFF4285F4);

    return MaterialApp(
      title: 'Muslim Calendar',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
          filled: true,
          fillColor: Color.fromARGB(255, 245, 245, 245),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(seedColor),
          trackColor: MaterialStateProperty.all(seedColor.withOpacity(0.5)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: seedColor.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          iconTheme: MaterialStateProperty.resolveWith((states) =>
              IconThemeData(
                  color: states.contains(MaterialState.selected)
                      ? seedColor
                      : Colors.black54)),
          labelTextStyle:
              MaterialStateProperty.resolveWith((states) => TextStyle(
                    color: states.contains(MaterialState.selected)
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
      ),
      home: const HomePage(),
    );
  }
}
