// lib/ui/pages/initial_location_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Lokalisierung & HomePage
import 'package:muslim_calendar/localization/app_localizations.dart'
    show AppLanguage, AppLocalizations;
import 'package:muslim_calendar/ui/pages/home_page.dart';

class InitialLocationPage extends StatefulWidget {
  const InitialLocationPage({Key? key}) : super(key: key);

  @override
  State<InitialLocationPage> createState() => _InitialLocationPageState();
}

class _InitialLocationPageState extends State<InitialLocationPage> {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.initialLocationPageTitle),
      ),
      body: _buildMainContent(loc),
    );
  }

  // STEP/STEUERUNG
  int _currentStep = 0;

  // Data
  Map<String, List<String>> _countryCityData = {};
  bool _isLoading = true;
  String? _error;

  // Felder: Sprache, Berechnung, 24h
  AppLanguage _selectedLanguage = AppLanguage.english;
  int _selectedCalcMethod = 13;
  bool _use24hFormat = false;

  // Standort
  String? _selectedCountry;
  String? _selectedCity;

  // Map für Berechnungsmethoden
  final Map<int, String> _calcMethodMap = {
    13: 'Diyanet (Turkey)',
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

  bool get _isIos => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadCountryCityData();
  }

  /// Lädt das JSON aus assets/country_city_<lang>.json und füllt `_countryCityData`
  Future<void> _loadCountryCityData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final languageCode = _mapAppLanguageToCode(_selectedLanguage);
    final fileName = 'assets/country_city_$languageCode.json';

    try {
      final jsonString = await rootBundle.loadString(fileName);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
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
        _error = 'Error loading country/city data: $e';
        _isLoading = false;
      });
    }
  }

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

  /// Speichert Daten und wechselt zur HomePage
  Future<void> _saveAndContinue() async {
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

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _isIos
          ? CupertinoPageRoute(builder: (_) => const HomePage())
          : MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  /// Stepper: Logik, um weiterzuschalten
  void _onStepContinue() {
    if (_currentStep < _buildSteps().length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Letzter Step => Daten speichern
      _saveAndContinue();
    }
  }

  /// Stepper: Logik, um zurückzuschalten
  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Stepper: Steps definieren
  List<Step> _buildSteps() {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    return [
      // Step 1: Sprache
      Step(
        title: Text(loc.language),
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.language, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                DropdownButton<AppLanguage>(
                  underline: const SizedBox(),
                  value: _selectedLanguage,
                  items: AppLanguage.values.map((lang) {
                    return DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(loc.getLanguageName(lang)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedLanguage = value;
                      _selectedCountry = null;
                      _selectedCity = null;
                    });
                    Provider.of<AppLocalizations>(context, listen: false)
                        .setLanguage(value);
                    _loadCountryCityData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              loc.initialInstructions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),

      // Step 2: Calc Method & 24h
      Step(
        title: Text(loc.calculationMethod),
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.calculationMethod,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calculate),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  underline: const SizedBox(),
                  value: _selectedCalcMethod,
                  items: _calcMethodMap.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCalcMethod = value;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            // 24h Format
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.timeFormat24),
              subtitle: Text(_use24hFormat
                  ? loc.timeFormat24Active
                  : loc.timeFormatAmPmActive),
              value: _use24hFormat,
              onChanged: (val) {
                setState(() {
                  _use24hFormat = val;
                });
              },
            ),
          ],
        ),
      ),

      // Step 3: Standort (Land & Stadt)
      Step(
        title: Text(loc.locationSettings),
        state: StepState.indexed,
        isActive: _currentStep >= 2,
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.locationInstructions,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      // Land
                      Text(loc.country),
                      const SizedBox(height: 8),
                      DropdownSearch<String>(
                        items: _countryCityData.keys.toList()..sort(),
                        selectedItem: _selectedCountry,
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedCity = null;
                          });
                        },
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: loc.country,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stadt
                      if (_selectedCountry != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.city),
                            const SizedBox(height: 8),
                            DropdownSearch<String>(
                              items: _countryCityData[_selectedCountry!] ?? [],
                              selectedItem: _selectedCity,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCity = value;
                                });
                              },
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: loc.city,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
      ),
    ];
  }

  @override
  Widget buildStep(BuildContext context, int index) {
    // Falls du einzelne Step-Widgets individuell aufbauen willst
    // (z. B. aus Performancegründen).
    // Hier jedoch nicht zwingend benötigt, da wir _buildSteps() verwenden.
    throw UnimplementedError();
  }

  @override
  Widget _buildAdaptiveStepper(BuildContext context) {
    final steps = _buildSteps();
    final loc = Provider.of<AppLocalizations>(context);
    return Stepper(
      currentStep: _currentStep,
      onStepTapped: (index) {
        setState(() {
          _currentStep = index;
        });
      },
      onStepContinue: _onStepContinue,
      onStepCancel: _onStepCancel,
      steps: steps,
      controlsBuilder: (BuildContext context, ControlsDetails details) {
        final isLastStep = _currentStep == steps.length - 1;
        final canGoBack = _currentStep > 0;

        return Row(
          children: [
            ElevatedButton(
              onPressed: details.onStepContinue,
              child: Text(isLastStep ? loc.finish : loc.next),
            ),
            const SizedBox(width: 8),
            if (canGoBack)
              OutlinedButton(
                onPressed: details.onStepCancel,
                child: Text(loc.back),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(AppLocalizations loc) {
    return SafeArea(
      child: _isIos
          ? CupertinoScrollbar(
              child:
                  SingleChildScrollView(child: _buildAdaptiveStepper(context)))
          : SingleChildScrollView(child: _buildAdaptiveStepper(context)),
    );
  }
}
