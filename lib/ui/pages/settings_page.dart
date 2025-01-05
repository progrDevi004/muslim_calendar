// lib/ui/pages/settings_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/providers/theme_notifier.dart';

enum LocationMode {
  automatic,
  manual,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppLanguage _selectedLanguage = AppLanguage.english;
  LocationMode _locationMode = LocationMode.automatic;
  String? _defaultCountry;
  String? _defaultCity;
  bool _notificationsEnabled = true;

  // War bisher unser Dark Mode
  bool _darkModeEnabled = false;

  // System-Theme
  bool _useSystemTheme = false;

  // 24h/AM-PM
  bool _use24hFormat = false;

  // Gebetszeiten-Slots auf dem Dashboard
  bool _showPrayerSlotsInDashboard = true;

  // Gebetszeiten in Daily / Weekly View
  bool _showPrayerTimesInDayView = true;
  bool _showPrayerTimesInWeekView = true;

  // Gebets-Berechnungsmethode (Default = 13, Diyanet)
  int _selectedCalcMethod = 13;

  /// Mapping zwischen Methode und Anzeigenamen (Quelle: https://aladhan.com/calculation-methods)
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

  bool _isLoadingCountries = true;
  String? _loadError;
  Map<String, List<String>> _countryCityData = {};

  bool get _isIos => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCountryCityData();
  }

  /// Lädt das Zeitformat, DarkMode etc.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    // Aus unserem ThemeNotifier => hier gespiegelt
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    _darkModeEnabled = themeNotifier.isDarkMode;
    _useSystemTheme = themeNotifier.useSystemTheme;

    _use24hFormat = prefs.getBool('use24hFormat') ?? false;

    final modeString = prefs.getString('locationMode') ?? 'automatic';
    if (modeString == 'manual') {
      _locationMode = LocationMode.manual;
    } else {
      _locationMode = LocationMode.automatic;
    }

    _defaultCountry = prefs.getString('defaultCountry');
    _defaultCity = prefs.getString('defaultCity');

    final savedLangIndex = prefs.getInt('selectedLanguageIndex');
    if (savedLangIndex != null &&
        savedLangIndex >= 0 &&
        savedLangIndex < AppLanguage.values.length) {
      _selectedLanguage = AppLanguage.values[savedLangIndex];
      Provider.of<AppLocalizations>(context, listen: false)
          .setLanguage(_selectedLanguage);
    }

    // Dashboard-Slots
    _showPrayerSlotsInDashboard =
        prefs.getBool('showPrayerSlotsInDashboard') ?? true;

    // Gebetszeiten in Daily/Weekly
    _showPrayerTimesInDayView =
        prefs.getBool('showPrayerTimesInDayView') ?? true;
    _showPrayerTimesInWeekView =
        prefs.getBool('showPrayerTimesInWeekView') ?? true;

    // Gebets-Berechnungsmethode
    _selectedCalcMethod = prefs.getInt('calculationMethod') ?? 13; // Diyanet

    setState(() {});
  }

  /// Lädt die Country-City-Daten aus dem JSON
  Future<void> _loadCountryCityData() async {
    setState(() {
      _isLoadingCountries = true;
      _loadError = null;
    });

    try {
      final jsonString =
          await rootBundle.loadString('assets/country_city_data.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<String, List<String>> parsed = jsonMap.map((k, v) {
        final list = (v as List).map((e) => e.toString()).toList();
        return MapEntry(k, list);
      });

      setState(() {
        _countryCityData = parsed;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Error loading country list: $e';
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('use24hFormat', _use24hFormat);

    await prefs.setString(
      'locationMode',
      _locationMode == LocationMode.manual ? 'manual' : 'automatic',
    );

    if (_defaultCountry != null) {
      await prefs.setString('defaultCountry', _defaultCountry!);
    }
    if (_defaultCity != null) {
      await prefs.setString('defaultCity', _defaultCity!);
    }

    await prefs.setInt('selectedLanguageIndex', _selectedLanguage.index);

    await prefs.setBool(
        'showPrayerSlotsInDashboard', _showPrayerSlotsInDashboard);

    // NEU: Daily/Week
    await prefs.setBool('showPrayerTimesInDayView', _showPrayerTimesInDayView);
    await prefs.setBool(
        'showPrayerTimesInWeekView', _showPrayerTimesInWeekView);

    // Gebets-Berechnungsmethode
    await prefs.setInt('calculationMethod', _selectedCalcMethod);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    return _isIos
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(loc.settings),
              trailing: GestureDetector(
                onTap: () async {
                  await _saveSettings();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(
                  loc.save,
                  style: const TextStyle(color: CupertinoColors.activeBlue),
                ),
              ),
            ),
            child: SafeArea(child: _buildSettingsList(loc)),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(loc.settings),
            ),
            body: _buildSettingsList(loc),
          );
  }

  Widget _buildSettingsList(AppLocalizations loc) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          loc.general,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Sprache
        ListTile(
          title: Text(loc.language),
          subtitle: Text(
            Provider.of<AppLocalizations>(context, listen: false)
                .getLanguageName(_selectedLanguage),
          ),
          onTap: () => _showLanguageSelector(context),
          trailing: const Icon(Icons.chevron_right),
        ),
        const SizedBox(height: 16),

        // System-Theme
        SwitchListTile.adaptive(
          title: Text(loc.useSystemTheme),
          subtitle: Text(loc.autoSwitchDarkLightMode),
          value: _useSystemTheme,
          onChanged: (bool value) async {
            setState(() {
              _useSystemTheme = value;
              if (value) {
                _darkModeEnabled = false;
              }
            });
            Provider.of<ThemeNotifier>(context, listen: false)
                .toggleSystemTheme(value);
            await _saveSettings();
          },
        ),

        // Dark Mode
        SwitchListTile.adaptive(
          title: Text(loc.darkMode),
          subtitle: Text(loc.darkModeSubtitle),
          value: _darkModeEnabled,
          onChanged: _useSystemTheme
              ? null
              : (bool value) async {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                  Provider.of<ThemeNotifier>(context, listen: false)
                      .toggleTheme(value);
                  await _saveSettings();
                },
        ),
        const SizedBox(height: 16),

        // Notifications
        SwitchListTile.adaptive(
          title: Text(loc.enableNotifications),
          subtitle: Text(loc.enableNotificationsSubtitle),
          value: _notificationsEnabled,
          onChanged: (bool value) async {
            setState(() {
              _notificationsEnabled = value;
            });
            if (value) {
              await NotificationService().enableNotifications();
            } else {
              await NotificationService().disableNotifications();
            }
            await _saveSettings();
          },
        ),
        const Divider(height: 40),

        // Zeitformat
        Text(
          loc.timeFormat,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: Text(loc.timeFormat24),
          subtitle: Text(_use24hFormat
              ? loc.timeFormat24Active
              : loc.timeFormatAmPmActive),
          value: _use24hFormat,
          onChanged: (bool val) async {
            setState(() {
              _use24hFormat = val;
            });
            await _saveSettings();
          },
        ),
        const Divider(height: 40),

        // Standort
        Text(
          loc.locationSettings,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: Text(loc.automaticLocation),
          subtitle: Text(loc.automaticLocationSubtitle),
          // Invertierte Logik war im Original-Code?
          value: _locationMode == LocationMode.manual,
          onChanged: (bool value) async {
            setState(() {
              // Achtung: Hier anpassen, dass "true" => automatic
              _locationMode =
                  value ? LocationMode.manual : LocationMode.automatic;
            });
            await _saveSettings();
          },
        ),
        if (_locationMode == LocationMode.manual)
          ..._buildManualLocationFields(loc.country, loc.city),

        const Divider(height: 40),

        // Gebetszeiten-Slots (Dashboard)
        Text(
          loc.prayerTimeSlots,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: Text(loc.prayerTimeSlotsInDashboard),
          subtitle: Text(loc.showTodayPrayerTimesAsSlots),
          value: _showPrayerSlotsInDashboard,
          onChanged: (bool val) async {
            setState(() {
              _showPrayerSlotsInDashboard = val;
            });
            await _saveSettings();
          },
        ),

        // Gebetszeiten in Daily / Weekly
        SwitchListTile.adaptive(
          title: Text(loc.showPrayerTimesInDailyView),
          subtitle: Text(loc.showPrayerTimesInDailyView),
          value: _showPrayerTimesInDayView,
          onChanged: (bool val) async {
            setState(() {
              _showPrayerTimesInDayView = val;
            });
            await _saveSettings();
          },
        ),
        SwitchListTile.adaptive(
          title: Text(loc.showPrayerTimesInWeeklyView),
          subtitle: Text(loc.showPrayerTimesInWeeklyView),
          value: _showPrayerTimesInWeekView,
          onChanged: (bool val) async {
            setState(() {
              _showPrayerTimesInWeekView = val;
            });
            await _saveSettings();
          },
        ),

        const Divider(height: 40),

        // Berechnungsmethode
        Text(
          loc.prayerTimesCalculation,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: loc.calculationMethod,
            border: const OutlineInputBorder(),
          ),
          value: _selectedCalcMethod,
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              _selectedCalcMethod = value;
            });
            await _saveSettings();
          },
          items: _calcMethodMap.entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),

        if (!_isIos) ...[
          const SizedBox(height: 40),
          Center(
            child: FilledButton(
              onPressed: () async {
                await _saveSettings();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ),
        ],
      ],
    );
  }

  /// Baut das UI für die manuelle Standort-Auswahl
  List<Widget> _buildManualLocationFields(String? country, String? city) {
    if (_isLoadingCountries) {
      return [
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    if (_loadError != null) {
      return [
        const SizedBox(height: 16),
        Text(
          _loadError!,
          style: const TextStyle(color: Colors.red),
        ),
      ];
    }

    final countries = _countryCityData.keys.toList()..sort();
    return [
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _defaultCountry,
        decoration: InputDecoration(labelText: country),
        onChanged: (value) {
          setState(() {
            _defaultCountry = value;
            _defaultCity = null;
          });
        },
        items: countries.map((c) {
          return DropdownMenuItem<String>(
            value: c,
            child: Text(c),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      if (_defaultCountry != null &&
          _countryCityData.containsKey(_defaultCountry))
        DropdownButtonFormField<String>(
          value: _defaultCity,
          decoration: InputDecoration(labelText: city),
          onChanged: (value) {
            setState(() {
              _defaultCity = value;
            });
          },
          items: _countryCityData[_defaultCountry]!
              .map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  ))
              .toList(),
        ),
    ];
  }

  void _showLanguageSelector(BuildContext context) {
    if (_isIos) {
      // iOS-BottomSheet
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          final loc = Provider.of<AppLocalizations>(ctx, listen: false);
          return Container(
            color: CupertinoColors.systemBackground.resolveFrom(ctx),
            height: 300,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: AppLanguage.values.map((lang) {
                        return CupertinoButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _selectedLanguage = lang;
                            });
                            loc.setLanguage(lang);
                            await _saveSettings();
                          },
                          child: Text(loc.getLanguageName(lang)),
                        );
                      }).toList(),
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Close'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Material-BottomSheet
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          final loc = Provider.of<AppLocalizations>(ctx, listen: false);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: AppLanguage.values.map((lang) {
                return ListTile(
                  title: Text(loc.getLanguageName(lang)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _selectedLanguage = lang;
                    });
                    loc.setLanguage(lang);
                    await _saveSettings();
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    }
  }
}
