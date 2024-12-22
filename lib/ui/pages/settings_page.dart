// lib/ui/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

enum LocationMode {
  automatic, // per Standort
  manual, // per Auswahl
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LocationMode _locationMode = LocationMode.automatic;
  String? _defaultCountry;
  String? _defaultCity;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  final List<String> _availableCountries = [
    'Germany',
    'Turkey',
    'Egypt',
    'USA'
  ];
  // Pro Land natürlich beliebig viele Einträge
  final Map<String, List<String>> _cityData = {
    'Germany': ['Berlin', 'Munich', 'Hamburg'],
    'Turkey': ['Istanbul', 'Ankara', 'Izmir'],
    'Egypt': ['Cairo', 'Alexandria'],
    'USA': ['New York', 'San Francisco', 'Miami'],
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Lädt die Einstellungen aus SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;

      final modeString = prefs.getString('locationMode') ?? 'automatic';
      if (modeString == 'manual') {
        _locationMode = LocationMode.manual;
      } else {
        _locationMode = LocationMode.automatic;
      }

      _defaultCountry = prefs.getString('defaultCountry');
      _defaultCity = prefs.getString('defaultCity');
    });
  }

  /// Speichert die Einstellungen in SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
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
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========== Location Mode ===========
          Text(
            loc.locationSettings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(loc.automaticLocation),
            subtitle: Text(loc.automaticLocationSubtitle),
            value: _locationMode == LocationMode.automatic,
            onChanged: (bool value) {
              setState(() {
                _locationMode =
                    value ? LocationMode.automatic : LocationMode.manual;
              });
            },
          ),
          if (_locationMode == LocationMode.manual)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _defaultCountry,
                  decoration: InputDecoration(labelText: loc.country),
                  onChanged: (value) {
                    setState(() {
                      _defaultCountry = value;
                      _defaultCity = null; // Reset city
                    });
                  },
                  items: _availableCountries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (_defaultCountry != null &&
                    _cityData.containsKey(_defaultCountry))
                  DropdownButtonFormField<String>(
                    value: _defaultCity,
                    decoration: InputDecoration(labelText: loc.city),
                    onChanged: (value) {
                      setState(() {
                        _defaultCity = value;
                      });
                    },
                    items: _cityData[_defaultCountry]!
                        .map((city) => DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            ))
                        .toList(),
                  ),
              ],
            ),
          const SizedBox(height: 20),

          // =========== Notifications ===========
          Text(
            loc.notificationSettings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SwitchListTile(
            title: Text(loc.enableNotifications),
            subtitle: Text(loc.enableNotificationsSubtitle),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // =========== Dark Mode ===========
          Text(
            loc.displaySettings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SwitchListTile(
            title: Text(loc.darkMode),
            subtitle: Text(loc.darkModeSubtitle),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          const SizedBox(height: 20),

          // =========== Save Button ===========
          Center(
            child: FilledButton(
              onPressed: () async {
                await _saveSettings();
                Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ),
        ],
      ),
    );
  }
}
