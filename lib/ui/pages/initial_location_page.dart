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
import 'package:Taqvimi/localization/app_localizations.dart'
    show AppLanguage, AppLocalizations;
import 'package:Taqvimi/ui/pages/home_page.dart';
import 'package:Taqvimi/data/services/location_service.dart';
import 'package:Taqvimi/data/services/import_settings_service.dart';
import 'package:Taqvimi/data/services/calendar_sync_service.dart';
import 'package:Taqvimi/data/services/google_calendar_service.dart';
import 'package:Taqvimi/models/selected_calendar.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

class InitialLocationPage extends StatefulWidget {
  const InitialLocationPage({super.key});

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

  // Import-Option (0 = Standardkategorie, 2 = Kalendername als Kategorie)
  int _selectedImportOption = 2;

  // Standort
  String? _selectedCountry;
  String? _selectedCity;
  bool _useAutomaticLocation = false;
  bool _isDetectingLocation = false;
  LocationService? _locationService;

  late CalendarSyncService _calendarSyncService;
  late GoogleCalendarService _googleCalendarService;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialisiere LocationService, falls noch nicht geschehen
    if (_locationService == null) {
      try {
        _locationService = Provider.of<LocationService>(context, listen: false);
      } catch (e) {
        debugPrint('LocationService konnte nicht initialisiert werden: $e');
      }
    }

    // Initialisiere die Services für die Kalendersynchronisation
    try {
      _calendarSyncService =
          Provider.of<CalendarSyncService>(context, listen: false);
      _googleCalendarService =
          Provider.of<GoogleCalendarService>(context, listen: false);
    } catch (e) {
      debugPrint('CalendarServices konnten nicht initialisiert werden: $e');
    }
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

  /// Versucht, den Standort automatisch zu ermitteln
  Future<void> _detectLocation() async {
    if (_locationService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standortdienst nicht verfügbar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final success = await _locationService!.determineLocation();

      if (success) {
        setState(() {
          _selectedCountry = _locationService!.currentCountry;
          _selectedCity = _locationService!.currentCity;
          _useAutomaticLocation = true;
          _isDetectingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Standort erkannt: $_selectedCity, $_selectedCountry'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isDetectingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_locationService!.errorMessage ??
                'Standorterkennung fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDetectingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler bei der Standorterkennung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Versucht, den Nutzer bei Google anzumelden
  Future<bool> _connectToGoogleAccount() async {
    try {
      // Anmeldeversuch starten
      await _googleCalendarService.signIn();

      // Prüfen, ob Anmeldung erfolgreich war
      if (_googleCalendarService.isSignedIn) {
        debugPrint("✅ Bei Google angemeldet");
        return true;
      } else {
        debugPrint("⚠️ Google-Anmeldung fehlgeschlagen");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Fehler bei Google-Anmeldung: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Google-Anmeldung fehlgeschlagen: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
      return false;
    }
  }

  /// Speichert Einstellungen und fährt fort
  Future<void> _saveAndContinue() async {
    // Sicherheitsprüfung: Stelle sicher, dass Land und Stadt ausgewählt wurden
    if (_selectedCountry == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<AppLocalizations>(context, listen: false)
              .selectCountryAndCity),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Nicht fortfahren
    }

    final prefs = await SharedPreferences.getInstance();

    // Sprache
    await prefs.setInt('selectedLanguageIndex', _selectedLanguage.index);
    // Berechnungsmethode
    await prefs.setInt('calculationMethod', _selectedCalcMethod);
    // Zeitformat
    await prefs.setBool('use24hFormat', _use24hFormat);

    // Import-Option mit ImportSettingsService speichern
    await ImportSettingsService.saveImportOption(_selectedImportOption);
    await prefs.setBool('import_option_initialized', true);
    debugPrint("📋 Import-Option gespeichert: $_selectedImportOption");

    // Standort - Wir haben bereits geprüft, dass die Werte nicht null sind
    await prefs.setString('defaultCountry', _selectedCountry!);
    await prefs.setString('defaultCity', _selectedCity!);

    // Automatische Standorterkennung speichern
    await prefs.setBool('automaticLocation', _useAutomaticLocation);

    // Markiere, dass die Einstellungen bereits erfasst wurden
    await prefs.setBool('wasLocationAsked', true);

<<<<<<< HEAD
    // // Stelle sicher, dass Google-Kalender verbunden ist und alle Kalender automatisch ausgewählt werden
    // try {
    //   // Auto-SignIn versuchen
    //   await _googleCalendarService.autoSignIn();
=======
    // Stelle sicher, dass Google-Kalender verbunden ist und alle Kalender automatisch ausgewählt werden
    /*try {
      // Auto-SignIn versuchen
      await _googleCalendarService.autoSignIn();
>>>>>>> d050b1c094df3c0842b41e12dad81179ef02ad0d

    //   if (!_googleCalendarService.isSignedIn) {
    //     debugPrint(
    //         "⚠️ Nicht bei Google angemeldet, versuche manuelle Anmeldung");

    //     // Anmelde-Dialog anzeigen
    //     final result = await showDialog<bool>(
    //       context: context,
    //       barrierDismissible: false,
    //       builder: (context) => AlertDialog(
    //         title: const Text("Google-Kalender verbinden"),
    //         content: const Text(
    //           "Möchten Sie sich jetzt bei Google anmelden, um Ihre Kalender zu synchronisieren?",
    //         ),
    //         actions: [
    //           TextButton(
    //             onPressed: () => Navigator.of(context).pop(false),
    //             child: const Text("Überspringen"),
    //           ),
    //           ElevatedButton(
    //             onPressed: () => Navigator.of(context).pop(true),
    //             child: const Text("Anmelden"),
    //           ),
    //         ],
    //       ),
    //     );

    //     // // Wenn der Nutzer zustimmt, Anmeldung durchführen
    //     // if (result == true) {
    //     //   final signedIn = await _connectToGoogleAccount();
    //     //   if (!signedIn) {
    //     //     debugPrint("⚠️ Manuelle Google-Anmeldung fehlgeschlagen");
    //     //   }
    //     // } else {
    //     //   debugPrint("ℹ️ Google-Anmeldung übersprungen");
    //     // }
    //   }

    //   if (_googleCalendarService.isSignedIn) {
    //     debugPrint("🔄 Automatisch bei Google angemeldet");

    //     // Hole alle verfügbaren Kalender
    //     final calendarList = await _googleCalendarService.fetchCalendarList();

    //     if (calendarList.isNotEmpty) {
    //       // Alle Kalender als ausgewählt markieren
    //       final allCalendars = calendarList
    //           .map((calendar) => SelectedCalendar(
    //                 id: calendar.id ?? 'primary',
    //                 title: calendar.summary ?? 'Kalender',
    //                 isSelected: true, // Alle als ausgewählt markieren
    //               ))
    //           .toList();

    //       // Speichere alle Kalender als ausgewählt
    //       await _calendarSyncService.saveSelectedCalendars(allCalendars);

    //       debugPrint(
    //           "✅ Alle ${allCalendars.length} Google-Kalender wurden automatisch ausgewählt");

    //       // Information, dass die Kalender nun bereit sind, aber kein automatischer Import
    //       if (mounted) {
    //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //           content: Text("Alle Google-Kalender wurden ausgewählt"),
    //           backgroundColor: Colors.green,
    //           duration: Duration(seconds: 3),
    //         ));
    //       }

<<<<<<< HEAD
    //       // Der automatische Import wurde entfernt, damit der Nutzer selbst entscheiden kann,
    //       // wann er den Import starten möchte
    //     } else {
    //       debugPrint("⚠️ Keine Google-Kalender gefunden");
    //     }
    //   } else {
    //     debugPrint(
    //         "⚠️ Nicht bei Google angemeldet, Kalender können nicht ausgewählt werden");
    //   }
    // } catch (e) {
    //   debugPrint("❌ Fehler beim Auswählen der Google-Kalender: $e");
    //   // Fehler bei der Kalenderauswahl sollten nicht den gesamten Initialisierungsprozess blockieren
    // }
=======
          // Der automatische Import wurde entfernt, damit der Nutzer selbst entscheiden kann,
          // wann er den Import starten möchte
        } else {
          debugPrint("⚠️ Keine Google-Kalender gefunden");
        }
      } else {
        debugPrint(
            "⚠️ Nicht bei Google angemeldet, Kalender können nicht ausgewählt werden");
      }
    } catch (e) {
      debugPrint("❌ Fehler beim Auswählen der Google-Kalender: $e");
      // Fehler bei der Kalenderauswahl sollten nicht den gesamten Initialisierungsprozess blockieren
    }*/ 
>>>>>>> d050b1c094df3c0842b41e12dad81179ef02ad0d

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _isIos
          ? CupertinoPageRoute(builder: (_) => const HomePage())
          : MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  /// Stepper: Logik, um weiterzuschalten
  void _onStepContinue() {
    // Wenn wir im letzten Schritt sind und auf "Fertig" klicken
    if (_currentStep == _buildSteps().length - 1) {
      // Überprüfen, ob ein Standort ausgewählt wurde (automatisch oder manuell)
      if (_useAutomaticLocation) {
        // Bei automatischer Standortwahl: Prüfen, ob ein Standort erkannt wurde
        if (_selectedCountry == null || _selectedCity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<AppLocalizations>(context, listen: false)
                      .runLocationDetectionFirst),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      } else {
        // Bei manueller Standortwahl: Beide Felder prüfen
        if (_selectedCountry == null || _selectedCity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  Provider.of<AppLocalizations>(context, listen: false)
                      .selectCountryAndCity),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      // Alles in Ordnung, Daten speichern und fortfahren
      _saveAndContinue();
    } else if (_currentStep < _buildSteps().length - 1) {
      // Normales Weitergehen zum nächsten Schritt
      setState(() {
        _currentStep++;
      });
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

      // Step 3: Import-Optionen
      Step(
        title: Text(loc.importOptionsTitle),
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.importOptionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.import_export),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  underline: const SizedBox(),
                  value: _selectedImportOption,
                  items: [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text(loc.useDefaultCategoryOption),
                    ),
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text(loc.useCalendarNameOption),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedImportOption = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.importOptionsDescription,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),

      // Step 4: Standort (überarbeitete Version)
      Step(
        title: Text(loc.locationSettings),
        state: StepState.indexed,
        isActive: _currentStep >= 3,
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
                      // Info-Text (minimalistischer)
                      Text(
                        loc.locationInstructions,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Switch für Standort-Modus
                      SwitchListTile.adaptive(
                        title: Text(loc.automaticLocationDetection),
                        subtitle: Text(_useAutomaticLocation
                            ? loc.automaticLocationDetectionActive
                            : loc.automaticLocationDetectionInactive),
                        value: _useAutomaticLocation,
                        activeColor: logoColor,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _useAutomaticLocation = value;
                          });

                          // Wenn automatische Erkennung aktiviert wird, direkt Standort ermitteln
                          if (value) {
                            _detectLocation();
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Automatischer Standortmodus
                      if (_useAutomaticLocation)
                        Column(
                          children: [
                            // Anzeige während der Standorterkennung
                            if (_isDetectingLocation)
                              Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    loc.locationDetectionInProgress,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),

                            // Anzeige des erkannten Standorts
                            if (_selectedCity != null &&
                                _selectedCountry != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                loc.detectedLocation,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              Text(
                                                "$_selectedCity, $_selectedCountry",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // Manueller Standortmodus
                      if (!_useAutomaticLocation)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Land auswählen
                            Text(
                              loc.country,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
                                  hintText: loc.selectCountry,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Stadt auswählen
                            if (_selectedCountry != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.city,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownSearch<String>(
                                    items:
                                        _countryCityData[_selectedCountry!] ??
                                            [],
                                    selectedItem: _selectedCity,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCity = value;
                                      });
                                    },
                                    popupProps: const PopupProps.menu(
                                      showSearchBox: true,
                                    ),
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        hintText: loc.selectCity,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            if (_selectedCountry == null)
                              Text(
                                loc.selectCountry,
                                style: const TextStyle(color: Colors.orange),
                              ),
                          ],
                        ),
                    ],
                  ),
      ),
    ];
  }

  Widget buildStep(BuildContext context, int index) {
    // Falls du einzelne Step-Widgets individuell aufbauen willst
    // (z. B. aus Performancegründen).
    // Hier jedoch nicht zwingend benötigt, da wir _buildSteps() verwenden.
    throw UnimplementedError();
  }

  Widget _buildAdaptiveStepper(BuildContext context) {
    final steps = _buildSteps();
    final loc = Provider.of<AppLocalizations>(context);

    // Hier wird das Layout angepasst, um Scrollbarkeit zu verbessern
    return ConstrainedBox(
      constraints: BoxConstraints(
        // Minimale Höhe, aber wächst mit Inhalt
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.height - 150,
      ),
      child: Stepper(
        currentStep: _currentStep,
        onStepTapped: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: steps,
        physics: const ClampingScrollPhysics(), // Wichtig für die Scrollbarkeit
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == steps.length - 1;
          final canGoBack = _currentStep > 0;

          // Füge zusätzlichen Padding am Ende hinzu, damit die Buttons besser erreichbar sind
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Row(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations loc) {
    return SafeArea(
      child: CustomScrollView(
        // AlwaysScrollableScrollPhysics erzwingt Scrollbarkeit auch bei kleinem Inhalt
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody:
                true, // Dies ist wichtig, um das Scrollen zu ermöglichen
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildAdaptiveStepper(context),
            ),
          ),
        ],
      ),
    );
  }
}
