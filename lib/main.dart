import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light, // Helles Theme
          primary: Color(0xFF007A33), // Hauptfarbe (Grün)
          onPrimary: Colors.white, // Textfarbe auf Grün
          secondary: Color(0xFF4CAF50), // Sekundärfarbe (helleres Grün)
          onSecondary: Colors.white, // Textfarbe auf Sekundärfarbe
          surface: Color.fromARGB(
              255, 255, 255, 255), // Oberflächenfarbe (z. B. Karten)
          onSurface: Colors.black, // Textfarbe auf Oberflächen
          error: Colors.red, // Fehlerfarbe
          onError: Colors.white, // Textfarbe auf Fehlerfarbe
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return HomePage();
  }
}
