// lib/ui/pages/settings_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:muslim_calendar/data/services/google_calendar_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/providers/theme_notifier.dart';
// Für reDownloadAndRecalcAll()
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import '../../data/services/calendar_sync_service.dart';

// Beispiel-Enum, kann auch global in app_language.dart liegen:

enum LocationMode {
  automatic,
  manual,
}

enum SyncFrequency {
  none,
  daily,
  weekly,
  monthly,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final bool _isIos = Platform.isIOS;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _use24HourFormat = true;
  bool _showPrayerTimesInDayView = true;
  bool _showPrayerTimesInWeekView = true;
  bool _showPrayerSlotsInDashboard = true;
  bool _automaticLocation = true;
  String? _defaultCountry;
  String? _defaultCity;
  int _selectedCalcMethod = 0;
  Map<int, String> _calcMethodMap = {};
  Map<String, List<String>> _countryCityData = {};
  bool _isLoadingCountries = true;
  String? _loadError;
  int _selectedLanguageIndex = 0;
  AppLanguage _selectedLanguage = AppLanguage.english;

  // Calendar Sync
  bool _googleCalendarEnabled = false;
  bool _appleCalendarEnabled = false;
  bool _outlookCalendarEnabled = false;
  bool _googleCalendarConnected = false;
  bool _appleCalendarConnected = false;
  bool _outlookCalendarConnected = false;
  SyncFrequency _googleCalendarSyncFrequency = SyncFrequency.none;
  SyncFrequency _appleCalendarSyncFrequency = SyncFrequency.none;
  SyncFrequency _outlookCalendarSyncFrequency = SyncFrequency.none;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCountryCityData();
    _initCalcMethodMap();
    _checkCalendarConnections();
  }

  void _initCalcMethodMap() {
    _calcMethodMap = {
      0: 'Muslim World League',
      1: 'Egyptian General Authority',
      2: 'University of Islamic Sciences, Karachi',
      3: 'Umm al-Qura University, Makkah',
      4: 'Islamic Society of North America',
      5: 'Union des Organisations Islamiques de France',
      6: 'Majlis Ugama Islam Singapura',
      7: 'Institute of Geophysics, University of Tehran',
      8: 'Shia Ithna-Ashari',
      9: 'Gulf Region',
      10: 'Kuwait',
      11: 'Qatar',
      12: 'Singapore',
      13: 'Turkey',
      14: 'Dubai',
      15: 'Moonsighting Committee Worldwide',
    };
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _use24HourFormat = prefs.getBool('use24HourFormat') ?? true;
      _showPrayerTimesInDayView =
          prefs.getBool('showPrayerTimesInDayView') ?? true;
      _showPrayerTimesInWeekView =
          prefs.getBool('showPrayerTimesInWeekView') ?? true;
      _showPrayerSlotsInDashboard =
          prefs.getBool('showPrayerSlotsInDashboard') ?? true;
      _automaticLocation = prefs.getBool('automaticLocation') ?? true;
      _defaultCountry = prefs.getString('defaultCountry');
      _defaultCity = prefs.getString('defaultCity');
      _selectedCalcMethod = prefs.getInt('calculationMethod') ?? 0;
      _selectedLanguageIndex = prefs.getInt('selectedLanguageIndex') ?? 0;
      _selectedLanguage = AppLanguage.values[_selectedLanguageIndex];

      // Calendar Sync
      _googleCalendarEnabled = prefs.getBool('googleCalendarEnabled') ?? false;
      _appleCalendarEnabled = prefs.getBool('appleCalendarEnabled') ?? false;
      _outlookCalendarEnabled =
          prefs.getBool('outlookCalendarEnabled') ?? false;
      _googleCalendarSyncFrequency = SyncFrequency.values[
          prefs.getInt('googleSyncFrequency') ?? SyncFrequency.none.index];
      _appleCalendarSyncFrequency = SyncFrequency.values[
          prefs.getInt('appleSyncFrequency') ?? SyncFrequency.none.index];
      _outlookCalendarSyncFrequency = SyncFrequency.values[
          prefs.getInt('outlookSyncFrequency') ?? SyncFrequency.none.index];
    });

    // Aktualisieren des Themes über den ThemeNotifier
    themeNotifier.toggleTheme(_isDarkMode);
  }

  Future<void> _loadCountryCityData() async {
    setState(() {
      _isLoadingCountries = true;
      _loadError = null;
    });

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/country_city_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final Map<String, List<String>> data = {};
      jsonData.forEach((key, value) {
        if (value is List) {
          data[key] = List<String>.from(value);
        }
      });

      setState(() {
        _countryCityData = data;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load country data: $e';
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _checkCalendarConnections() async {
    final calendarService = context.read<CalendarSyncService>();

    // Temporäre Mock-Implementierung, bis die eigentlichen Methoden implementiert sind
    final googleConnected =
        false; // await calendarService.isGoogleCalendarConnected();
    final appleConnected =
        false; // await calendarService.isAppleCalendarConnected();
    final outlookConnected =
        false; // await calendarService.isOutlookCalendarConnected();

    setState(() {
      _googleCalendarConnected = googleConnected;
      _appleCalendarConnected = appleConnected;
      _outlookCalendarConnected = outlookConnected;
    });
  }

  Future<bool> _connectToGoogleCalendar(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final calendarService = context.read<CalendarSyncService>();

    try {
      // Temporäre Mock-Implementierung
      // final success = await calendarService.connectGoogleCalendar();
      final success = false; // Mock-Antwort
      if (success) {
        setState(() {
          _googleCalendarConnected = true;
        });
      }
      return success;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to Google Calendar: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _manageGoogleCalendarConnection(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final calendarService = context.read<CalendarSyncService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.manageConnection),
        content: Text(loc.manageConnectionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // await calendarService.disconnectGoogleCalendar();
              // Temporäre Mock-Implementierung
              setState(() {
                _googleCalendarConnected = false;
              });
              Navigator.of(ctx).pop();
            },
            child: Text(loc.disconnect),
          ),
        ],
      ),
    );
  }

  Future<bool> _connectToAppleCalendar(BuildContext context) async {
    // Implementation for Apple Calendar connection
    return false;
  }

  Future<void> _manageAppleCalendarConnection(BuildContext context) async {
    // Implementation for managing Apple Calendar connection
  }

  Future<bool> _connectToOutlookCalendar(BuildContext context) async {
    // Implementation for Outlook Calendar connection
    return false;
  }

  Future<void> _manageOutlookCalendarConnection(BuildContext context) async {
    // Implementation for managing Outlook Calendar connection
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    // Aktualisieren des Themes über den ThemeNotifier
    themeNotifier.toggleTheme(_isDarkMode);
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('use24HourFormat', _use24HourFormat);
    await prefs.setBool('automaticLocation', _automaticLocation);

    if (!_automaticLocation) {
      await prefs.setString('defaultCountry', _defaultCountry ?? '');
      await prefs.setString('defaultCity', _defaultCity ?? '');
    } else {
      await prefs.remove('defaultCountry');
      await prefs.remove('defaultCity');
    }
    await prefs.setInt('selectedLanguageIndex', _selectedLanguage.index);
    await prefs.setBool(
        'showPrayerSlotsInDashboard', _showPrayerSlotsInDashboard);
    await prefs.setBool('showPrayerTimesInDayView', _showPrayerTimesInDayView);
    await prefs.setBool(
        'showPrayerTimesInWeekView', _showPrayerTimesInWeekView);
    await prefs.setInt('calculationMethod', _selectedCalcMethod);

    await prefs.setBool('googleCalendarEnabled', _googleCalendarEnabled);
    await prefs.setBool('appleCalendarEnabled', _appleCalendarEnabled);
    await prefs.setBool('outlookCalendarEnabled', _outlookCalendarEnabled);
    await prefs.setInt(
        'googleSyncFrequency', _googleCalendarSyncFrequency.index);
    await prefs.setInt('appleSyncFrequency', _appleCalendarSyncFrequency.index);
    await prefs.setInt(
        'outlookSyncFrequency', _outlookCalendarSyncFrequency.index);
  }

  /// Ruft die Logik zum Neuladen der Gebetszeiten auf.
  Future<void> _updatePrayerTimes() async {
    final prayerTimeService = context.read<PrayerTimeService>();
    await prayerTimeService.reDownloadAndRecalcAll();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    return _isIos
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Settings'),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildSettingsContent(context),
                ),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('Settings'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildSettingsContent(context),
                ),
              ),
            ),
          );
  }

  List<Widget> _buildSettingsContent(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    return [
      // Appearance Section
      Text(
        'Appearance',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: Text(loc.darkMode),
        subtitle: Text(loc.darkModeSubtitle),
        value: _isDarkMode,
        onChanged: (value) async {
          setState(() => _isDarkMode = value);
          await _saveSettings();
        },
      ),
      const Divider(height: 32),

      // Notifications Section
      Text(
        'Notifications',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: Text(loc.enableNotifications),
        subtitle: Text(loc.enableNotificationsSubtitle),
        value: _notificationsEnabled,
        onChanged: (value) async {
          setState(() => _notificationsEnabled = value);
          await _saveSettings();
        },
      ),
      const Divider(height: 32),

      // Time Format Section
      Text(
        loc.timeFormat,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      RadioListTile<bool>(
        title: Text(loc.timeFormat24Active),
        value: true,
        groupValue: _use24HourFormat,
        onChanged: (value) async {
          if (value != null) {
            setState(() => _use24HourFormat = value);
            await _saveSettings();
          }
        },
      ),
      RadioListTile<bool>(
        title: Text(loc.timeFormatAmPmActive),
        value: false,
        groupValue: _use24HourFormat,
        onChanged: (value) async {
          if (value != null) {
            setState(() => _use24HourFormat = value);
            await _saveSettings();
          }
        },
      ),
      const Divider(height: 32),

      // Location Settings
      Text(
        loc.locationSettings,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: Text(loc.automaticLocation),
        subtitle: Text(loc.automaticLocationSubtitle),
        value: _automaticLocation,
        onChanged: (value) async {
          setState(() => _automaticLocation = value);
          await _saveSettings();
          await _updatePrayerTimes();
        },
      ),
      if (!_automaticLocation) ..._buildManualLocationFields('Country', 'City'),
      const Divider(height: 32),

      // Prayer Time Calculation Method
      Text(
        'Prayer Time Calculation Method',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        value: _selectedCalcMethod,
        decoration: const InputDecoration(
          labelText: 'Calculation Method',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) async {
          setState(() {
            _selectedCalcMethod = value ?? 0;
          });
          await _saveSettings();
          await _updatePrayerTimes();
        },
        items: _calcMethodMap.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
      ),

      // New Sync Section
      const Divider(height: 40),
      Text(
        loc.calendarSync,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),

      // Google Calendar Integration
      _buildCalendarIntegration(
        loc.googleCalendar,
        Icons.calendar_today,
        _googleCalendarEnabled,
        _googleCalendarConnected,
        _googleCalendarSyncFrequency,
        (value) async {
          setState(() => _googleCalendarEnabled = value);
          await _saveSettings();
        },
        () async {
          if (!_googleCalendarConnected) {
            return _connectToGoogleCalendar(context);
          } else {
            await _manageGoogleCalendarConnection(context);
            return _googleCalendarConnected;
          }
        },
        (value) => _googleCalendarSyncFrequency = value,
      ),

      // Apple Calendar Integration
      _buildCalendarIntegration(
        loc.appleCalendar,
        _isIos ? Icons.apple : Icons.calendar_month,
        _appleCalendarEnabled,
        _appleCalendarConnected,
        _appleCalendarSyncFrequency,
        (value) async {
          setState(() => _appleCalendarEnabled = value);
          await _saveSettings();
        },
        () async {
          if (!_appleCalendarConnected) {
            return _connectToAppleCalendar(context);
          } else {
            await _manageAppleCalendarConnection(context);
            return _appleCalendarConnected;
          }
        },
        (value) => _appleCalendarSyncFrequency = value,
      ),

      // Outlook Calendar Integration
      _buildCalendarIntegration(
        loc.outlookCalendar,
        Icons.mail_outline,
        _outlookCalendarEnabled,
        _outlookCalendarConnected,
        _outlookCalendarSyncFrequency,
        (value) async {
          setState(() => _outlookCalendarEnabled = value);
          await _saveSettings();
        },
        () async {
          if (!_outlookCalendarConnected) {
            return _connectToOutlookCalendar(context);
          } else {
            await _manageOutlookCalendarConnection(context);
            return _outlookCalendarConnected;
          }
        },
        (value) => _outlookCalendarSyncFrequency = value,
      ),

      // Falls Android => Speichern-Knopf
      if (!_isIos) ...[
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _saveSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            },
            child: const Text('Save Settings'),
          ),
        ),
      ],
    ];
  }

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
        icon: Container(),
        decoration: InputDecoration(
          labelText: country,
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.arrow_drop_down,
              size: 24,
            ),
          ),
        ),
        onChanged: (value) async {
          setState(() {
            _defaultCountry = value;
            _defaultCity = null;
          });
          await _saveSettings();
          if (_defaultCountry != null && _defaultCountry!.isNotEmpty) {
            await _updatePrayerTimes();
          }
        },
        items: countries.map((c) {
          return DropdownMenuItem<String>(
            value: c,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(c),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      if (_defaultCountry != null &&
          _countryCityData.containsKey(_defaultCountry))
        DropdownButtonFormField<String>(
          value: _defaultCity,
          icon: Container(),
          decoration: InputDecoration(
            labelText: city,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.arrow_drop_down,
                size: 24,
              ),
            ),
          ),
          onChanged: (value) async {
            setState(() {
              _defaultCity = value;
            });
            await _saveSettings();
            if (_defaultCity != null && _defaultCity!.isNotEmpty) {
              await _updatePrayerTimes();
            }
          },
          items: _countryCityData[_defaultCountry]!.map((c) {
            return DropdownMenuItem<String>(
              value: c,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(c),
              ),
            );
          }).toList(),
        ),
    ];
  }

  Widget _buildCalendarIntegration(
    String title,
    IconData icon,
    bool isEnabled,
    bool isConnected,
    SyncFrequency syncFrequency,
    Future<void> Function(bool) onEnabledChanged,
    Future<bool> Function() onConnectPressed,
    void Function(SyncFrequency) onSyncFrequencyChanged,
  ) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isEnabled,
                  onChanged: (value) async {
                    await onEnabledChanged(value);
                  },
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final success = await onConnectPressed();
                  setState(() {});
                },
                child: Text(isConnected ? loc.manageConnection : loc.connect),
              ),
              if (isConnected) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _handleManualSync(true, title);
                        },
                        child: Text(loc.importFromCalendar),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _handleManualSync(false, title);
                        },
                        child: Text(loc.exportToCalendar),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Sync Frequency:'),
                const SizedBox(height: 8),
                _buildSyncFrequencyOptions(
                    syncFrequency, onSyncFrequencyChanged),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualSync(bool isImport, String serviceName) async {
    final calendarService = context.read<CalendarSyncService>();
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    try {
      if (isImport) {
        // await calendarService.importFromCalendar(serviceName);
        // Temporäre Mock-Implementierung
        await _showSuccessDialog(loc.importSuccess(serviceName));
      } else {
        // await calendarService.exportToCalendar(serviceName);
        // Temporäre Mock-Implementierung
        await _showSuccessDialog(loc.exportSuccess(serviceName));
      }
    } catch (e) {
      await _showErrorDialog(loc.syncError(e.toString()));
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Provider.of<AppLocalizations>(ctx).success),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Provider.of<AppLocalizations>(ctx).ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Provider.of<AppLocalizations>(ctx).error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Provider.of<AppLocalizations>(ctx).ok),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFrequencyOptions(
    SyncFrequency currentFrequency,
    void Function(SyncFrequency) onChanged,
  ) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(loc.noSync),
          selected: currentFrequency == SyncFrequency.none,
          onSelected: (selected) {
            if (selected) {
              setState(() => onChanged(SyncFrequency.none));
              _saveSettings();
            }
          },
        ),
        ChoiceChip(
          label: Text(loc.dailySync),
          selected: currentFrequency == SyncFrequency.daily,
          onSelected: (selected) {
            if (selected) {
              setState(() => onChanged(SyncFrequency.daily));
              _saveSettings();
            }
          },
        ),
        ChoiceChip(
          label: Text(loc.weeklySync),
          selected: currentFrequency == SyncFrequency.weekly,
          onSelected: (selected) {
            if (selected) {
              setState(() => onChanged(SyncFrequency.weekly));
              _saveSettings();
            }
          },
        ),
        ChoiceChip(
          label: Text(loc.monthlySync),
          selected: currentFrequency == SyncFrequency.monthly,
          onSelected: (selected) {
            if (selected) {
              setState(() => onChanged(SyncFrequency.monthly));
              _saveSettings();
            }
          },
        ),
      ],
    );
  }
}
