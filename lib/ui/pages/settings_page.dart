// lib/ui/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

// Neu importiert
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
  bool _darkModeEnabled = false;

  final List<String> _availableCountries = [
    'Germany',
    'Türkiye',
    'Egypt',
    'USA'
  ];
  final Map<String, List<String>> _cityData = {
    'Germany': ['Berlin', 'Munich', 'Hamburg'],
    'Türkiye': ['Istanbul', 'Ankara', 'Izmir'],
    'Egypt': ['Cairo', 'Alexandria'],
    'USA': ['New York', 'San Francisco', 'Miami'],
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

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

    final savedLangIndex = prefs.getInt('selectedLanguageIndex');
    if (savedLangIndex != null &&
        savedLangIndex >= 0 &&
        savedLangIndex < AppLanguage.values.length) {
      _selectedLanguage = AppLanguage.values[savedLangIndex];
      Provider.of<AppLocalizations>(context, listen: false)
          .setLanguage(_selectedLanguage);
    }

    setState(() {});
  }

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

    await prefs.setInt('selectedLanguageIndex', _selectedLanguage.index);
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
          Text(
            loc.general,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Sprache
          ListTile(
            title: const Text('Language'),
            subtitle: Text(
              Provider.of<AppLocalizations>(context, listen: false)
                  .getLanguageName(_selectedLanguage),
            ),
            onTap: () => _showLanguageSelector(context),
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 16),

          // Dark Mode
          SwitchListTile(
            activeColor: Colors.green,
            activeTrackColor: Colors.greenAccent,
            title: Text(loc.darkMode),
            subtitle: Text(loc.darkModeSubtitle),
            value: _darkModeEnabled,
            onChanged: (bool value) async {
              setState(() {
                _darkModeEnabled = value;
              });
              await _saveSettings();
              Provider.of<ThemeNotifier>(context, listen: false)
                  .toggleTheme(value);
            },
          ),
          const SizedBox(height: 16),

          // Notifications
          SwitchListTile(
            activeColor: Colors.green,
            activeTrackColor: Colors.greenAccent,
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

          // Erweiterte Einstellungen
          Text(
            loc.locationSettings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            activeColor: Colors.green,
            activeTrackColor: Colors.greenAccent,
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
          if (_locationMode == LocationMode.manual) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _defaultCountry,
              decoration: InputDecoration(labelText: loc.country),
              onChanged: (value) {
                setState(() {
                  _defaultCountry = value;
                  _defaultCity = null;
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
          const SizedBox(height: 40),
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

  void _showLanguageSelector(BuildContext context) {
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
