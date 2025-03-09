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
import '../../data/repositories/appointment_repository.dart';

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
  bool _use24hFormat = true;
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
  bool _outlookCalendarEnabled = false;
  bool _googleCalendarConnected = false;
  bool _outlookCalendarConnected = false;
  SyncFrequency _googleCalendarSyncFrequency = SyncFrequency.none;
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
      _use24hFormat = prefs.getBool('use24hFormat') ?? true;
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
      _outlookCalendarEnabled =
          prefs.getBool('outlookCalendarEnabled') ?? false;
      _googleCalendarSyncFrequency = SyncFrequency.values[
          prefs.getInt('googleSyncFrequency') ?? SyncFrequency.none.index];
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
          await rootBundle.loadString('assets/country_city_en.json');
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
    final googleService = context.read<GoogleCalendarService>();

    // Tatsächliche Implementierung für Google
    bool googleConnected = googleService.isSignedIn;

    // Temporäre Mock-Implementierung für Outlook
    final outlookConnected = false;

    setState(() {
      _googleCalendarConnected = googleConnected;
      _outlookCalendarConnected = outlookConnected;
    });
  }

  Future<bool> _connectToGoogleCalendar(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final googleService = context.read<GoogleCalendarService>();

    try {
      await googleService.signIn();

      setState(() {
        _googleCalendarConnected = googleService.isSignedIn;
      });

      return googleService.isSignedIn;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.syncError(e.toString()))),
        );
      }
      return false;
    }
  }

  Future<void> _manageGoogleCalendarConnection(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final googleService = context.read<GoogleCalendarService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.manageConnection),
        content: Text(loc.manageConnectionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              await googleService.signOut();
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

    // Aktualisieren des Themes über den ThemeNotifier
    themeNotifier.toggleTheme(_isDarkMode);
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('use24hFormat', _use24hFormat);
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
    await prefs.setBool('outlookCalendarEnabled', _outlookCalendarEnabled);
    await prefs.setInt(
        'googleSyncFrequency', _googleCalendarSyncFrequency.index);
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
        groupValue: _use24hFormat,
        onChanged: (value) async {
          if (value != null) {
            setState(() => _use24hFormat = value);
            await _saveSettings();
          }
        },
      ),
      RadioListTile<bool>(
        title: Text(loc.timeFormatAmPmActive),
        value: false,
        groupValue: _use24hFormat,
        onChanged: (value) async {
          if (value != null) {
            setState(() => _use24hFormat = value);
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

      // New Calendar Sync Section
      const Divider(height: 40),
      _buildCalendarSection(context),

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
                  SnackBar(content: Text(loc.settingsSaved)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              loc.saveSettings,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  // Neues Widget für Kalender-Integration
  Widget _buildCalendarSection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            children: [
              Icon(Icons.sync, size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                loc.calendarSync,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Google Kalender Card
        _buildCalendarCard(
          context: context,
          title: loc.googleCalendar,
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF4285F4), // Google Blue
          isEnabled: _googleCalendarEnabled,
          isConnected: _googleCalendarConnected,
          syncFrequency: _googleCalendarSyncFrequency,
          onEnabledChanged: (value) async {
            setState(() => _googleCalendarEnabled = value);
            await _saveSettings();
          },
          onConnectPressed: () async {
            if (!_googleCalendarConnected) {
              return _connectToGoogleCalendar(context);
            } else {
              await _manageGoogleCalendarConnection(context);
              return _googleCalendarConnected;
            }
          },
          onSyncFrequencyChanged: (value) {
            setState(() => _googleCalendarSyncFrequency = value);
            _saveSettings();
          },
          onImportPressed: () => _handleManualSync(true, "Google Calendar"),
          onExportPressed: () => _handleManualSync(false, "Google Calendar"),
        ),

        const SizedBox(height: 16),

        // Outlook Kalender Card
        _buildCalendarCard(
          context: context,
          title: loc.outlookCalendar,
          icon: Icons.mail_outline,
          iconColor: const Color(0xFF0078D4), // Outlook Blue
          isEnabled: _outlookCalendarEnabled,
          isConnected: _outlookCalendarConnected,
          syncFrequency: _outlookCalendarSyncFrequency,
          onEnabledChanged: (value) async {
            setState(() => _outlookCalendarEnabled = value);
            await _saveSettings();
          },
          onConnectPressed: () async {
            if (!_outlookCalendarConnected) {
              return _connectToOutlookCalendar(context);
            } else {
              await _manageOutlookCalendarConnection(context);
              return _outlookCalendarConnected;
            }
          },
          onSyncFrequencyChanged: (value) {
            setState(() => _outlookCalendarSyncFrequency = value);
            _saveSettings();
          },
          onImportPressed: () => _handleManualSync(true, "Outlook Calendar"),
          onExportPressed: () => _handleManualSync(false, "Outlook Calendar"),
        ),
      ],
    );
  }

  Widget _buildCalendarCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
    required bool isConnected,
    required SyncFrequency syncFrequency,
    required Future<void> Function(bool) onEnabledChanged,
    required Future<bool> Function() onConnectPressed,
    required void Function(SyncFrequency) onSyncFrequencyChanged,
    required Future<void> Function() onImportPressed,
    required Future<void> Function() onExportPressed,
  }) {
    final loc = Provider.of<AppLocalizations>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context).cardColor
        : Theme.of(context).cardColor.withOpacity(0.95);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEnabled
              ? iconColor.withOpacity(0.5)
              : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      elevation: isEnabled ? 2 : 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel und Switch
            Row(
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Switch(
                  value: isEnabled,
                  activeColor: iconColor,
                  onChanged: (value) async {
                    await onEnabledChanged(value);
                  },
                ),
              ],
            ),

            // Aktive Inhalte, wenn enabled
            if (isEnabled) ...[
              const Divider(height: 24),

              // Verbindungsstatus
              Row(
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: isConnected
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? loc.connected : loc.notConnected,
                    style: TextStyle(
                      color: isConnected ? Colors.green : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Connect/Manage Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final success = await onConnectPressed();
                    setState(() {});
                  },
                  icon: Icon(
                    isConnected ? Icons.settings : Icons.login,
                    size: 18,
                  ),
                  label: Text(
                    isConnected ? loc.manageConnection : loc.connect,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Sync Optionen, wenn verbunden
              if (isConnected) ...[
                const SizedBox(height: 20),

                // Import/Export Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onImportPressed,
                        icon: const Icon(Icons.download, size: 16),
                        label: Text(loc.import),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: iconColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onExportPressed,
                        icon: const Icon(Icons.upload, size: 16),
                        label: Text(loc.export),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: iconColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sync Frequency
                Text(
                  loc.syncFrequency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                _buildSyncFrequencyOptions(
                  syncFrequency,
                  onSyncFrequencyChanged,
                  iconColor,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncFrequencyOptions(
    SyncFrequency currentFrequency,
    void Function(SyncFrequency) onChanged,
    Color activeColor,
  ) {
    final loc = Provider.of<AppLocalizations>(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFrequencyChip(
          label: loc.noSync,
          selected: currentFrequency == SyncFrequency.none,
          onSelected: (selected) {
            if (selected) onChanged(SyncFrequency.none);
          },
          activeColor: activeColor,
        ),
        _buildFrequencyChip(
          label: loc.dailySync,
          selected: currentFrequency == SyncFrequency.daily,
          onSelected: (selected) {
            if (selected) onChanged(SyncFrequency.daily);
          },
          activeColor: activeColor,
        ),
        _buildFrequencyChip(
          label: loc.weeklySync,
          selected: currentFrequency == SyncFrequency.weekly,
          onSelected: (selected) {
            if (selected) onChanged(SyncFrequency.weekly);
          },
          activeColor: activeColor,
        ),
        _buildFrequencyChip(
          label: loc.monthlySync,
          selected: currentFrequency == SyncFrequency.monthly,
          onSelected: (selected) {
            if (selected) onChanged(SyncFrequency.monthly);
          },
          activeColor: activeColor,
        ),
      ],
    );
  }

  Widget _buildFrequencyChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required Color activeColor,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : null,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: activeColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _handleManualSync(bool isImport, String serviceName) async {
    final calendarService = context.read<CalendarSyncService>();
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    // Zeige Ladeindikator an
    final loadingDialog = _showLoadingDialog(isImport);

    try {
      if (isImport) {
        // Echte Implementierung für den Import
        await calendarService.importAppointments();
        // Dialog schließen
        if (mounted) Navigator.of(context).pop();

        // Termine für Debugging lesen und anzeigen
        _showDebugTermineDialog();

        // Erfolgsmeldung anzeigen
        await _showSuccessDialog(loc.importSuccess(serviceName));
        // UI aktualisieren, um die importierten Termine anzuzeigen
        if (mounted) _refreshAppointmentsUI();
      } else {
        // Echte Implementierung für den Export
        await calendarService.exportAppointments();
        // Dialog schließen
        if (mounted) Navigator.of(context).pop();
        // Erfolgsmeldung anzeigen
        await _showSuccessDialog(loc.exportSuccess(serviceName));
      }
    } catch (e) {
      // Dialog schließen im Fehlerfall
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog(loc.syncError(e.toString()));
    }
  }

  // Zeigt einen Debug-Dialog mit allen Terminen aus der Datenbank
  Future<void> _showDebugTermineDialog() async {
    final appointmentRepo = context.read<AppointmentRepository>();
    final termine = await appointmentRepo.getAllAppointments();

    // Nur für Debug-Zwecke in Konsole ausgeben
    debugPrint("🔍 TERMIN DEBUG LISTE (${termine.length} Termine):");
    for (var t in termine) {
      debugPrint(
          "  - ${t.subject} | ID: ${t.id} | Kategorie: ${t.categoryId} | Start: ${t.startTime}");
    }

    // Im Debug-Modus (oder mit speziellem Flag) Dialog anzeigen
    if (mounted) {
      final loc = Provider.of<AppLocalizations>(context, listen: false);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.debugAppointments),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${loc.totalAppointments}: ${termine.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...termine
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text("${t.subject}\n"
                              "ID: ${t.id} | Kategorie: ${t.categoryId}\n"
                              "Start: ${t.startTime?.toString().substring(0, 16)}"),
                        ))
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.ok),
            ),
          ],
        ),
      );
    }
  }

  // Aktualisiere die UI, um die importierten Termine anzuzeigen
  void _refreshAppointmentsUI() {
    // Intelligentere Aktualisierungsstrategie
    try {
      // Variante 1: EventBus/Provider-Benachrichtigung senden
      final appointmentRepo = context.read<AppointmentRepository>();
      if (appointmentRepo is ChangeNotifier) {
        (appointmentRepo as ChangeNotifier).notifyListeners();
        debugPrint("🔄 UI aktualisiert über ChangeNotifier");
      }

      // Variante 2: Snackbar anzeigen mit detaillierten Infos
      final loc = Provider.of<AppLocalizations>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.appointmentsUpdated),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: loc.viewAppointments,
            onPressed: () {
              // Falls wir auf dem Stack sind
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
              // Hier könnte man auch direkt zur Terminansicht navigieren
            },
          ),
        ),
      );

      // Variante 3: Manuell Apps mit Dependency Injection aktualisieren
      // Hier könnten spezifische Manager/Controller direkt aktualisiert werden

      debugPrint("📱 UI-Aktualisierung für Termine durchgeführt");
    } catch (e) {
      debugPrint("⚠️ Fehler bei der UI-Aktualisierung: $e");
    }
  }

  Future<void> _showLoadingDialog(bool isImport) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              isImport ? loc.importingAppointments : loc.exportingAppointments,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
