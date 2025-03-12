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
import 'package:muslim_calendar/ui/dialogs/calendar_selection_dialog.dart';
import 'package:muslim_calendar/models/selected_calendar.dart';

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

  // Speichere eine Referenz auf den CalendarSyncService
  late CalendarSyncService _calendarSyncService;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCountryCityData();
    _initCalcMethodMap();
    _checkCalendarConnections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sichere Methode, um auf Provider zuzugreifen - wird aufgerufen, wenn das Widget gebaut wird
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: false);

    // Listener für Kategorieänderungen hinzufügen
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen - jetzt mit der gespeicherten Referenz
    _calendarSyncService.removeListener(_onCategoriesChanged);
    super.dispose();
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    setState(() {
      // UI aktualisieren
    });
  }

  void _initCalcMethodMap() {
    _calcMethodMap = {
      0: 'MWL (Muslim World League)',
      1: 'Egypt (GAS)',
      2: 'Karachi (UIS)',
      3: 'Makkah (Umm al-Qura)',
      4: 'ISNA (North America)',
      5: 'UOIF (France)',
      6: 'MUIS (Singapore)',
      7: 'Tehran (Geophysics)',
      8: 'Shia Ithna-Ashari',
      9: 'Gulf Region',
      10: 'Kuwait',
      11: 'Qatar',
      12: 'Singapore',
      13: 'Turkey',
      14: 'Dubai',
      15: 'Moonsighting Committee',
    };
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    // Lade die Standorteinstellungen aus SharedPreferences
    String? country = prefs.getString('defaultCountry');
    String? city = prefs.getString('defaultCity');

    // Wenn automaticLocation aktiviert ist oder Standortdaten fehlen,
    // müssen wir eventuell zur InitialLocationPage zurückkehren
    final bool locationSet = (country != null &&
        city != null &&
        country.isNotEmpty &&
        city.isNotEmpty);
    final bool wasLocationAsked = prefs.getBool('wasLocationAsked') ?? false;

    // Wenn die Standorteinstellungen fehlen und der Benutzer bereits nach seiner Lage gefragt wurde,
    // liegt ein Fehler vor - navigiere zurück zur InitialLocationPage
    if (!locationSet && wasLocationAsked) {
      // Setze wasLocationAsked zurück, damit der Benutzer erneut nach seinem Standort gefragt wird
      await prefs.setBool('wasLocationAsked', false);

      if (mounted) {
        // Zeige eine Fehlermeldung an
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Standorteinstellungen fehlen. Sie werden zur Standortkonfiguration weitergeleitet.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );

        // Wir müssen aus der SettingsPage zurückkehren, damit die App zur InitialLocationPage navigieren kann
        Navigator.of(context).pop();
        return;
      }
    }

    // Wenn wir eine manuelle Standortauswahl haben und nie automaticLocation aktiviert haben,
    // sollten wir automaticLocation standardmäßig deaktivieren
    bool autoLocation;
    if (locationSet && !(prefs.containsKey('automaticLocation'))) {
      // Wenn Standort bereits gesetzt ist und nie explizit automaticLocation aktiviert wurde,
      // setzen wir automaticLocation auf false
      autoLocation = false;
      await prefs.setBool('automaticLocation', false);
    } else {
      // Ansonsten nutzen wir den gespeicherten Wert oder true als Standard
      autoLocation = prefs.getBool('automaticLocation') ?? true;
    }

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
      _automaticLocation = autoLocation;
      _defaultCountry = country;
      _defaultCity = city;
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

    // Wenn automaticLocation deaktiviert ist, aber keine Stadt/Land ausgewählt wurde,
    // zeige eine Fehlermeldung an und breche ab
    if (!_automaticLocation &&
        (_defaultCountry == null ||
            _defaultCity == null ||
            _defaultCountry!.isEmpty ||
            _defaultCity!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Bitte wählen Sie sowohl ein Land als auch eine Stadt aus'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Aktualisieren des Themes über den ThemeNotifier
    themeNotifier.toggleTheme(_isDarkMode);
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('use24hFormat', _use24hFormat);
    await prefs.setBool('automaticLocation', _automaticLocation);

    // Standardwerte für Land und Stadt immer setzen
    if (_defaultCountry != null &&
        _defaultCity != null &&
        _defaultCountry!.isNotEmpty &&
        _defaultCity!.isNotEmpty) {
      await prefs.setString('defaultCountry', _defaultCountry!);
      await prefs.setString('defaultCity', _defaultCity!);
    } else {
      // Wenn keine Werte gesetzt sind, zeige eine Fehlermeldung an
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Bitte wählen Sie sowohl ein Land als auch eine Stadt aus'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Abbrechen, bis die Einstellungen gesetzt sind
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

      // Prayer Times Display Section
      Text(
        loc.prayerTimeDisplay,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: Text(loc.showPrayerTimesInDayView),
        subtitle: Text(loc.showPrayerTimesInDayViewSubtitle),
        value: _showPrayerTimesInDayView,
        onChanged: (value) async {
          setState(() => _showPrayerTimesInDayView = value);
          await _saveSettings();
        },
      ),
      SwitchListTile(
        title: Text(loc.showPrayerTimesInWeekView),
        subtitle: Text(loc.showPrayerTimesInWeekViewSubtitle),
        value: _showPrayerTimesInWeekView,
        onChanged: (value) async {
          setState(() => _showPrayerTimesInWeekView = value);
          await _saveSettings();
        },
      ),
      SwitchListTile(
        title: Text(loc.showPrayerSlotsInDashboard),
        subtitle: Text(loc.showPrayerSlotsInDashboardSubtitle),
        value: _showPrayerSlotsInDashboard,
        onChanged: (value) async {
          setState(() => _showPrayerSlotsInDashboard = value);
          await _saveSettings();
        },
      ),
      const Divider(height: 32),

      // Language Settings Section
      Text(
        loc.language,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<AppLanguage>(
        value: _selectedLanguage,
        decoration: InputDecoration(
          labelText: loc.language,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) async {
          if (value != null) {
            setState(() => _selectedLanguage = value);

            // Aktualisiere die Sprache im AppLocalizations Provider
            Provider.of<AppLocalizations>(context, listen: false)
                .setLanguage(value);

            // Speichere die Einstellung
            await _saveSettings();
          }
        },
        items: AppLanguage.values.map((lang) {
          return DropdownMenuItem<AppLanguage>(
            value: lang,
            child: Text(loc.getLanguageName(lang)),
          );
        }).toList(),
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
        subtitle: _automaticLocation
            ? (_defaultCity != null && _defaultCountry != null)
                ? Text('$_defaultCity, $_defaultCountry')
                : Text(loc.automaticLocationSubtitle)
            : null,
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
      Container(
        // Definiert eine maximale Breite, um zu verhindern, dass der Text zu breit wird
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
        child: DropdownButtonFormField<int>(
          value: _selectedCalcMethod,
          isExpanded:
              true, // Stellt sicher, dass das Dropdown die volle Breite nutzt
          menuMaxHeight: 350, // Begrenzt die maximale Höhe des Dropdown-Menüs
          decoration: const InputDecoration(
            labelText: 'Calculation Method',
            border: OutlineInputBorder(),
            // Fügt zusätzlichen Platz für die Label-Text hinzu
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              // Verwendet FittedBox um sicherzustellen, dass der Text passt
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ),
      ),

      // New Calendar Sync Section
      const Divider(height: 40),
      _buildGoogleCalendarSection(context),

      // Outlook Calendar Section
      _buildOutlookCalendarSection(context),

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

  Widget _buildGoogleCalendarSection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final googleService = Provider.of<GoogleCalendarService>(context);
    final calendarSyncService = _calendarSyncService;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Google Calendar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            // State anzeigen
            FutureBuilder<bool>(
              future: _checkGoogleCalendarState(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final isConnected = snapshot.data ?? false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.cancel,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isConnected
                                ? loc.googleCalendarConnected
                                : loc.googleCalendarDisconnected,
                            style: TextStyle(
                              color: isConnected ? Colors.green : Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isConnected) ...[
                      // Kalenderliste verwalten
                      OutlinedButton.icon(
                        onPressed: _showCalendarSelectionDialog,
                        icon: const Icon(Icons.calendar_month),
                        label: Flexible(
                          child: Text(
                            loc.selectWhichCalendarsToSync,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sofort synchronisieren
                      OutlinedButton.icon(
                        onPressed: () async {
                          // Importoptionen anzeigen
                          final categoryOption =
                              await _showImportOptionsDialog(context);

                          if (categoryOption != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Synchronisierung läuft...")),
                            );

                            await calendarSyncService.syncGoogleCalendarNow(
                                categoryOption: categoryOption);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Synchronisierung abgeschlossen")),
                            );

                            setState(() {}); // UI aktualisieren
                          }
                        },
                        icon: const Icon(Icons.sync),
                        label: Flexible(
                          child: Text(
                            loc.syncGoogleCalendarNow,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Import und Export in einer Reihe
                      Row(
                        children: [
                          // Import
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Dialog anzeigen
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(loc.importCalendarTitle),
                                    content:
                                        Text(loc.importCalendarConfirmation),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(loc.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(loc.importButtonLabel),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  // Importoptionen anzeigen
                                  final categoryOption =
                                      await _showImportOptionsDialog(context);

                                  if (categoryOption != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(loc.importInProgress)),
                                    );

                                    // Nur importieren mit gewählter Kategorie-Option
                                    await calendarSyncService
                                        .importAppointments(
                                            categoryOption: categoryOption);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(loc.importCompleted)),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Nur importieren'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Export
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Dialog anzeigen
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(loc.exportCalendarTitle),
                                    content:
                                        Text(loc.exportCalendarConfirmation),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(loc.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(loc.exportButtonLabel),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(loc.exportInProgress)),
                                  );

                                  // Fehlerhafte Regeln zuerst korrigieren
                                  await calendarSyncService
                                      .fixInvalidRecurrenceRules();
                                  // Nur exportieren
                                  await calendarSyncService
                                      .exportAppointments();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(loc.exportCompleted)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.upload),
                              label: const Text('Nur exportieren'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Verbindung trennen
                      OutlinedButton.icon(
                        onPressed: () async {
                          await googleService.signOut();
                          setState(() {}); // UI aktualisieren
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(loc.disconnect),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Fehlerhafte Termine bereinigen
                      OutlinedButton.icon(
                        onPressed: () async {
                          // Dialog anzeigen
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(loc.fixInvalidRecurrencesTitle),
                              content:
                                  Text(loc.fixInvalidRecurrencesConfirmation),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(loc.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(loc.fixButtonLabel),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.fixInProgress)),
                            );

                            // Fehlerhafte Termine korrigieren
                            await calendarSyncService
                                .fixInvalidRecurrenceRules();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.fixCompleted)),
                            );
                          }
                        },
                        icon: const Icon(Icons.healing),
                        label: const Text('Fehlerhafte Termine bereinigen'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Alle Termine zurücksetzen
                      OutlinedButton.icon(
                        onPressed: () async {
                          final loc = Provider.of<AppLocalizations>(context,
                              listen: false);
                          // Dialog anzeigen
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Alle Termine zurücksetzen'),
                              content: Text(
                                  'ACHTUNG: Diese Funktion löscht ALLE lokalen Termine und importiert sie neu von Google. Dies ist ein letzter Ausweg, wenn andere Lösungen nicht funktionieren. Möchten Sie wirklich fortfahren?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('Abbrechen'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text('Zurücksetzen'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Zurücksetzen läuft...")),
                            );

                            // Verwende die gespeicherte _calendarSyncService Referenz
                            await calendarSyncService
                                .clearAppointmentsAndReimport();
                          }
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Alle Termine zurücksetzen'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ] else ...[
                      // Verbinden
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await googleService.signIn();
                            setState(() {}); // UI aktualisieren
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${loc.googleSignInError}: ${e.toString()}'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: Text(loc.connectWithGoogleCalendar),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlookCalendarSection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Outlook Calendar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _outlookCalendarConnected ? Icons.check_circle : Icons.cancel,
                  color: _outlookCalendarConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _outlookCalendarConnected
                        ? 'Connected to Outlook Calendar'
                        : 'Not connected to Outlook Calendar',
                    style: TextStyle(
                      color: _outlookCalendarConnected
                          ? Colors.green
                          : Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  // Placeholder für Outlook-Verbindungsimplementierung
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Outlook Integration coming soon!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Connection error: ${e.toString()}')),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: Flexible(
                child: Text(
                  loc.connectWithOutlookCalendar,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageGoogleCalendars(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final calendarSyncService = _calendarSyncService;

    try {
      // Zeige Ladeindikator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.loading),
            ],
          ),
        ),
      );

      // Lade verfügbare Kalender
      final availableCalendars =
          await _calendarSyncService.getAvailableCalendars();

      // Schließe Ladeindikator
      if (mounted) Navigator.of(context).pop();

      if (availableCalendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.noCalendarsFound)),
          );
        }
        return;
      }

      // Zeige Dialog zur Kalenderauswahl
      final result =
          await showCalendarSelectionDialog(context, availableCalendars);

      if (result != null) {
        // Speichere ausgewählte Kalender
        await calendarSyncService.saveSelectedCalendars(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.settingsSaved)),
          );
        }
      }
    } catch (e) {
      // Schließe Ladeindikator, falls angezeigt
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorLoadingCalendars(e.toString()))),
        );
      }
    }
  }

  String _syncFrequencyToString(SyncFrequency frequency, BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    switch (frequency) {
      case SyncFrequency.none:
        return loc.noSync;
      case SyncFrequency.daily:
        return loc.dailySync;
      case SyncFrequency.weekly:
        return loc.weeklySync;
      case SyncFrequency.monthly:
        return loc.monthlySync;
    }
  }

  Future<void> _showSyncFrequencyDialog(BuildContext context,
      bool isSyncFrequency, SyncFrequency currentFrequency) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.syncFrequency),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.syncFrequencyDescription),
              const SizedBox(height: 16),
              ...SyncFrequency.values.map((frequency) {
                return ListTile(
                  title: Text(
                    _syncFrequencyToString(frequency, context),
                  ),
                  leading: Radio<SyncFrequency>(
                    value: frequency,
                    groupValue: currentFrequency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _googleCalendarSyncFrequency = value;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _syncGoogleCalendarNow(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final calendarSyncService = _calendarSyncService;

    try {
      await calendarSyncService.syncGoogleCalendarNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.syncGoogleCalendarNow)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.syncError(e.toString()))),
        );
      }
    }
  }

  /// Prüft den aktuellen Zustand der Google Calendar-Verbindung
  Future<bool> _checkGoogleCalendarState() async {
    final googleService =
        Provider.of<GoogleCalendarService>(context, listen: false);
    return googleService.isSignedIn;
  }

  /// Zeigt einen Dialog zur Auswahl der zu synchronisierenden Kalender an
  Future<void> _showCalendarSelectionDialog() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final calendarSyncService = _calendarSyncService;

    try {
      // Zeige Ladeindikator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.loading),
            ],
          ),
        ),
      );

      // Lade verfügbare Kalender
      final availableCalendars =
          await _calendarSyncService.getAvailableCalendars();

      // Schließe Ladeindikator
      if (mounted) Navigator.of(context).pop();

      if (availableCalendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.noCalendarsFound)),
          );
        }
        return;
      }

      // Zeige Dialog zur Kalenderauswahl
      final result =
          await showCalendarSelectionDialog(context, availableCalendars);

      if (result != null) {
        // Speichere ausgewählte Kalender
        await _calendarSyncService.saveSelectedCalendars(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.settingsSaved)),
          );
        }
      }
    } catch (e) {
      // Schließe Ladeindikator, falls angezeigt
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorLoadingCalendars(e.toString()))),
        );
      }
    }
  }

  /// Zeigt einen Dialog zur Auswahl der Import-Kategorie-Option an
  Future<int?> _showImportOptionsDialog(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    int selectedOption = 0;

    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.importCalendarTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.importCalendarDescription),
              const SizedBox(height: 16),
              RadioListTile<int>(
                title: Text(loc.importOptionDefault),
                subtitle: Text(loc.importOptionDefaultSubtitle),
                value: 0,
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() => selectedOption = value!);
                },
              ),
              RadioListTile<int>(
                title: Text(loc.importOptionColorCategories),
                subtitle: Text(loc.importOptionColorCategoriesSubtitle),
                value: 1,
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() => selectedOption = value!);
                },
              ),
              RadioListTile<int>(
                title: Text(loc.importOptionNamedCategories),
                subtitle: Text(loc.importOptionNamedCategoriesSubtitle),
                value: 2,
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() => selectedOption = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(selectedOption),
              child: Text(loc.importButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  /// Löscht alle lokalen Termine und führt einen vollständigen Neuimport durch
  Future<void> clearAppointmentsAndReimport() async {
    final calendarSyncService = _calendarSyncService;
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.resetInProgress)),
      );

      // Alle Termine löschen und neu importieren
      await calendarSyncService.clearAppointmentsAndReimport();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.resetCompleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.syncError(e.toString()))),
      );
    }
  }
}
