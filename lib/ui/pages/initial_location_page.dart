// lib/ui/pages/initial_location_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_search/dropdown_search.dart'; // Für suchfähige Dropdowns
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/ui/pages/home_page.dart';

class InitialLocationPage extends StatefulWidget {
  const InitialLocationPage({Key? key}) : super(key: key);

  @override
  State<InitialLocationPage> createState() => _InitialLocationPageState();
}

class _InitialLocationPageState extends State<InitialLocationPage> {
  // Standortbezogene Felder
  Map<String, List<String>> _countryCityData = {};
  String? _selectedCountry;
  String? _selectedCity;

  // Neue Felder für Sprache, Gebetszeiten-Berechnung und Zeitformat
  AppLanguage _selectedLanguage = AppLanguage.english;
  int _selectedCalcMethod = 13;
  bool _use24hFormat = false;

  // Map für die Berechnungsmethoden (analog zur SettingsPage)
  final Map<int, String> _calcMethodMap = {
    13: 'Diyanet (Turkey)', // Standard
    3: 'MWL (Muslim World League)',
    4: 'Umm Al-Qura, Makkah',
    5: 'Egypt (GAS)',
    2: 'ISNA (N. America)',
    1: 'Karachi',
    7: 'Tehran (Univ. of Geophysics)',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
  };

  /// Wandelt den internen AppLanguage-Wert in einen Locale-Code (String) um.
  String _mapAppLanguageToCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.german:
        return 'de';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
      default:
        return 'en';
    }
  }

  bool _isLoading = true;
  String? _error;

  bool get _isIos => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadCountryCityData();
  }

  /// Lädt das JSON aus assets/country_city_data.json und füllt `_countryCityData`
  Future<void> _loadCountryCityData() async {
    final languageCode = _mapAppLanguageToCode(_selectedLanguage);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jsonString =
          await rootBundle.loadString('assets/country_city_$languageCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      // Konvertiere Map<String, dynamic> zu Map<String, List<String>>
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
    // Lokale Übersetzungen abrufen
    final loc = Provider.of<AppLocalizations>(context);
    return _isIos
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(loc.welcome),
            ),
            child: SafeArea(
              child: Material(
                child: _buildBody(loc),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(loc.welcome),
            ),
            body: _buildBody(loc),
          );
  }

  Widget _buildBody(AppLocalizations loc) {
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

    // Sortierte Liste der Länder
    final countries = _countryCityData.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Abschnitt: Allgemeine Einstellungen
          Text(
            loc.initialInstructions,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Sprache auswählen
          DropdownButtonFormField<AppLanguage>(
            decoration: InputDecoration(
              labelText: loc.language,
              border: const OutlineInputBorder(),
            ),
            value: _selectedLanguage,
            items: AppLanguage.values.map((lang) {
              return DropdownMenuItem<AppLanguage>(
                value: lang,
                child: Text(loc.getLanguageName(lang)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                _loadCountryCityData();
              });
              Provider.of<AppLocalizations>(context, listen: false)
                  .setLanguage(value!);
            },
          ),
          const SizedBox(height: 24),

          // Berechnungsmethode auswählen
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: loc.calculationMethod,
              border: const OutlineInputBorder(),
            ),
            value: _selectedCalcMethod,
            items: _calcMethodMap.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCalcMethod = value!;
              });
            },
          ),
          const SizedBox(height: 24),

          // Zeitformat auswählen
          SwitchListTile.adaptive(
            title: Text(loc.timeFormat24),
            subtitle: Text(_use24hFormat
                ? loc.timeFormat24Active
                : loc.timeFormatAmPmActive),
            value: _use24hFormat,
            onChanged: (value) {
              setState(() {
                _use24hFormat = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Trennung: Standortauswahl
          Text(
            loc.locationInstructions,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Suchfähiges Dropdown für die Länder-Auswahl
          DropdownSearch<String>(
            items: countries,
            selectedItem: _selectedCountry,
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedCity = null; // Reset der Stadtauswahl
              });
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: loc.country,
                border: const OutlineInputBorder(),
              ),
            ),
            validator: (value) =>
                value == null ? loc.country + ' ' + 'ist erforderlich' : null,
          ),
          const SizedBox(height: 24),

          // Suchfähiges Dropdown für die Städte-Auswahl (nur wenn ein Land ausgewählt wurde)
          if (_selectedCountry != null) ...[
            DropdownSearch<String>(
              items: _countryCityData[_selectedCountry] ?? [],
              selectedItem: _selectedCity,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: loc.city,
                  border: const OutlineInputBorder(),
                ),
              ),
              validator: (value) =>
                  value == null ? loc.city + ' ' + 'ist erforderlich' : null,
            ),
            const SizedBox(height: 24),
          ],

          const Spacer(),

          _buildAdaptiveButton(
            label: loc.finish,
            onPressed: (_selectedCity == null) ? null : _saveAndContinue,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    // Speichere alle Einstellungen in SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Sprache
    await prefs.setInt('selectedLanguageIndex', _selectedLanguage.index);
    // Berechnungsmethode
    await prefs.setInt('calculationMethod', _selectedCalcMethod);
    // Zeitformat
    await prefs.setBool('use24hFormat', _use24hFormat);

    // Standort
    if (_selectedCountry != null) {
      await prefs.setString('defaultCountry', _selectedCountry!);
    }
    if (_selectedCity != null) {
      await prefs.setString('defaultCity', _selectedCity!);
    }

    // Markiere, dass die Einstellungen bereits erfasst wurden
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
