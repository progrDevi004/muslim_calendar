// lib/ui/pages/initial_location_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/ui/pages/home_page.dart';

class InitialLocationPage extends StatefulWidget {
  const InitialLocationPage({Key? key}) : super(key: key);

  @override
  State<InitialLocationPage> createState() => _InitialLocationPageState();
}

class _InitialLocationPageState extends State<InitialLocationPage> {
  // Hier halten wir das geladene Map-Objekt aus dem JSON
  Map<String, List<String>> _countryCityData = {};

  String? _selectedCountry;
  String? _selectedCity;

  bool _isLoading = true;
  String? _error;

  bool get _isIos => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadCountryCityData();
  }

  /// Lädt das JSON aus assets/country_city_data.json und
  /// füllt `_countryCityData`
  Future<void> _loadCountryCityData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jsonString =
          await rootBundle.loadString('assets/country_city_data.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      // Wir konvertieren Map<String, dynamic> zu Map<String, List<String>>
      final Map<String, List<String>> parsed = jsonMap.map((k, v) {
        final list = (v as List).map((e) => e.toString()).toList();
        return MapEntry(k, list);
      });

      setState(() {
        _countryCityData = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der Länderliste: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Damit der Dropdown auch auf iOS funktioniert, müssen wir eine Material-Hülle verwenden.
    // Wir packen das _buildBody() einfach in ein Material-Widget.
    return _isIos
        ? CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Willkommen!'),
            ),
            child: SafeArea(
              child: Material(
                child: _buildBody(),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Willkommen!'),
            ),
            body: _buildBody(),
          );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // Wir haben nun _countryCityData
    final countries = _countryCityData.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Bitte wähle deinen Standort aus, damit die Gebetszeiten korrekt berechnet werden können.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Auswahl Land
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Land',
              border: OutlineInputBorder(),
            ),
            value: _selectedCountry,
            items: countries.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedCity = null; // Reset der Stadt
              });
            },
          ),
          const SizedBox(height: 24),

          // Stadt
          if (_selectedCountry != null) ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Stadt',
                border: OutlineInputBorder(),
              ),
              value: _selectedCity,
              items: _countryCityData[_selectedCountry]!
                  .map((city) => DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
            ),
          ],
          const Spacer(),
          _buildAdaptiveButton(
            label: 'Fertig',
            onPressed: _selectedCity == null ? null : _saveAndContinue,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    // Speichere den Standort in SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    if (_selectedCountry != null) {
      await prefs.setString('defaultCountry', _selectedCountry!);
    }
    if (_selectedCity != null) {
      await prefs.setString('defaultCity', _selectedCity!);
    }

    // Markiere, dass wir schon gefragt haben
    await prefs.setBool('wasLocationAsked', true);

    // Wechsle zur HomePage
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _isIos
          ? CupertinoPageRoute(builder: (_) => const HomePage())
          : MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Widget _buildAdaptiveButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    if (_isIos) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: Text(label),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
  }
}
