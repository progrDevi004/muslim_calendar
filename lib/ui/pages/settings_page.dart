// lib/ui/pages/settings_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:Taqvimi/data/services/google_calendar_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/providers/theme_notifier.dart';
// Für reDownloadAndRecalcAll()
import 'package:Taqvimi/data/services/prayer_time_service.dart';
import '../../data/services/calendar_sync_service.dart';
import 'package:Taqvimi/ui/dialogs/calendar_selection_dialog.dart';
import 'package:Taqvimi/data/services/location_service.dart';
import 'package:Taqvimi/data/services/import_settings_service.dart';

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
  const SettingsPage({super.key});

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

  // Speichere eine Referenz auf den LocationService - nullable machen
  LocationService? _locationService;

  // Neue Variable für Notification Status
  final String _notificationStatus = "";
  final bool _isLoadingStatus = false;

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

    // Sicherer Zugriff auf LocationService mit try-catch
    try {
      _locationService = Provider.of<LocationService>(context, listen: false);
    } catch (e) {
      debugPrint('LocationService konnte nicht geladen werden: $e');
      // Wir erstellen keinen neuen LocationService, da das zu weiteren Problemen führen könnte
    }

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
    final loc = Provider.of<AppLocalizations>(context, listen: false);

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
          SnackBar(
            content: Text(loc.locationSettingsMissing),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

    // Aktualisiere die Sprache im AppLocalizations Provider
    Provider.of<AppLocalizations>(context, listen: false)
        .setLanguage(_selectedLanguage);

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
    const outlookConnected = false;

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
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    // Wenn automaticLocation deaktiviert ist, aber keine Stadt/Land ausgewählt wurde,
    // zeige eine Fehlermeldung an und breche ab
    if (!_automaticLocation &&
        (_defaultCountry == null ||
            _defaultCity == null ||
            _defaultCountry!.isEmpty ||
            _defaultCity!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.selectCountryAndCity),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
        SnackBar(
          content: Text(loc.selectCountryAndCity),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
    final theme = Theme.of(context);

    Widget settingsContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildSettingsContent(context),
        ),
      ),
    );

    if (_isIos) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(loc.settings),
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Material(
          type: MaterialType.transparency,
          child: settingsContent,
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.settings),
        ),
        body: settingsContent,
      );
    }
  }

  List<Widget> _buildSettingsContent(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    return [
      // Appearance Section
      Text(
        loc.appearance,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (isIOS)
        CupertinoListTile(
          title: Text(loc.darkMode),
          subtitle: Text(loc.darkModeSubtitle),
          trailing: CupertinoSwitch(
            value: _isDarkMode,
            onChanged: (value) async {
              setState(() => _isDarkMode = value);
              await _saveSettings();
            },
          ),
        )
      else
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

      // Time Format Section
      Text(
        loc.timeFormat,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (isIOS)
        Column(
          children: [
            CupertinoListTile(
              title: Text(loc.timeFormat24Active),
              trailing: CupertinoRadio<bool>(
                value: true,
                groupValue: _use24hFormat,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _use24hFormat = value);
                    await _saveSettings();
                  }
                },
              ),
            ),
            CupertinoListTile(
              title: Text(loc.timeFormatAmPmActive),
              trailing: CupertinoRadio<bool>(
                value: false,
                groupValue: _use24hFormat,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _use24hFormat = value);
                    await _saveSettings();
                  }
                },
              ),
            ),
          ],
        )
      else
        Column(
          children: [
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
          ],
        ),
      const Divider(height: 32),

      // Prayer Times Display Section
      Text(
        loc.prayerTimeDisplay,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (isIOS)
        Column(
          children: [
            CupertinoListTile(
              title: Text(loc.showPrayerTimesInDayView),
              subtitle: Text(loc.showPrayerTimesInDayViewSubtitle),
              trailing: CupertinoSwitch(
                value: _showPrayerTimesInDayView,
                onChanged: (value) async {
                  setState(() => _showPrayerTimesInDayView = value);
                  await _saveSettings();
                },
              ),
            ),
            CupertinoListTile(
              title: Text(loc.showPrayerTimesInWeekView),
              subtitle: Text(loc.showPrayerTimesInWeekViewSubtitle),
              trailing: CupertinoSwitch(
                value: _showPrayerTimesInWeekView,
                onChanged: (value) async {
                  setState(() => _showPrayerTimesInWeekView = value);
                  await _saveSettings();
                },
              ),
            ),
            CupertinoListTile(
              title: Text(loc.showPrayerSlotsInDashboard),
              subtitle: Text(loc.showPrayerSlotsInDashboardSubtitle),
              trailing: CupertinoSwitch(
                value: _showPrayerSlotsInDashboard,
                onChanged: (value) async {
                  setState(() => _showPrayerSlotsInDashboard = value);
                  await _saveSettings();
                },
              ),
            ),
          ],
        )
      else
        Column(
          children: [
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
          ],
        ),
      const Divider(height: 32),

      // Language Settings Section
      Text(
        loc.language,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (isIOS)
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                title: Text(loc.language),
                actions: AppLanguage.values.map((lang) {
                  return CupertinoActionSheetAction(
                    onPressed: () async {
                      setState(() => _selectedLanguage = lang);
                      Provider.of<AppLocalizations>(context, listen: false)
                          .setLanguage(lang);
                      await _saveSettings();
                      Navigator.pop(context);
                    },
                    child: Text(
                      loc.getLanguageName(lang),
                      style: TextStyle(
                        color: _selectedLanguage == lang
                            ? CupertinoColors.activeBlue
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.getLanguageName(_selectedLanguage)),
              const Icon(CupertinoIcons.chevron_right),
            ],
          ),
        )
      else
        DropdownButtonFormField<AppLanguage>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            labelText: loc.language,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) async {
            if (value != null) {
              setState(() => _selectedLanguage = value);
              Provider.of<AppLocalizations>(context, listen: false)
                  .setLanguage(value);
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
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),

      // Aktueller Standort (Informationsanzeige) - je nach Modus unterschiedlich
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _automaticLocation
                    ? loc.currentLocationAuto
                    : loc.currentLocationManual,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                      _automaticLocation
                          ? Icons.my_location
                          : Icons.location_on,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: (_defaultCity != null && _defaultCountry != null)
                        ? Text('$_defaultCity, $_defaultCountry',
                            style: const TextStyle(fontSize: 16))
                        : Text(loc.noLocationSet,
                            style:
                                const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Automatischer Standort Switch
      SwitchListTile(
        title: Text(loc.automaticLocation),
        subtitle: _automaticLocation
            ? (_locationServiceAvailable() &&
                    _locationService!.currentCity != null &&
                    _locationService!.currentCountry != null)
                ? Text(loc.automaticLocationActive)
                : Text(loc.automaticLocationSubtitle)
            : Text(loc.manualLocationActive),
        value: _automaticLocation,
        onChanged: (value) async {
          setState(() => _automaticLocation = value);

          if (value && _locationServiceAvailable()) {
            // Automatische Standorterkennung aktivieren
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.locationDetecting),
                duration: const Duration(seconds: 1),
              ),
            );

            final success = await _locationService!.determineLocation();

            if (!success) {
              // Fehlermeldung anzeigen
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_locationService!.errorMessage ??
                        loc.locationDetectionFailed),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } else if (mounted) {
              // Erfolg melden und neugeladene Daten anzeigen
              setState(() {
                _defaultCity = _locationService!.currentCity;
                _defaultCountry = _locationService!.currentCountry;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.locationUpdated}: ${_locationService!.currentCity}, ${_locationService!.currentCountry}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }

          await _saveSettings();
          await _updatePrayerTimes();
        },
      ),

      // Manuelle Standortauswahl mit leeren Dropdowns statt vorausgefüllten Werten
      if (!_automaticLocation) ...[
        const SizedBox(height: 8),
        Text(
          loc.chooseLocationManually,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: null, // Immer leer starten
          hint: Text(loc.selectCountry),
          icon: Container(),
          decoration: InputDecoration(
            labelText: loc.country,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.arrow_drop_down,
                size: 24,
              ),
            ),
          ),
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                _defaultCountry = value;
                _defaultCity = null;
              });
              await _saveSettings();
              if (_defaultCountry != null && _defaultCountry!.isNotEmpty) {
                await _updatePrayerTimes();
              }
            }
          },
          items: _isLoadingCountries
              ? []
              : _countryCityData.keys.toList().map((c) {
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
            value: null, // Immer leer starten
            hint: Text(loc.selectCity),
            icon: Container(),
            decoration: InputDecoration(
              labelText: loc.city,
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                ),
              ),
            ),
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _defaultCity = value;
                });
                await _saveSettings();
                if (_defaultCity != null && _defaultCity!.isNotEmpty) {
                  await _updatePrayerTimes();
                }
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

        // Button zum Übernehmen
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _defaultCountry != null && _defaultCity != null
              ? () async {
                  await _saveSettings();
                  await _updatePrayerTimes();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.locationUpdated),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              : null, // Deaktivieren wenn keine Auswahl getroffen wurde
          icon: const Icon(Icons.save),
          label: Text(loc.applyLocation),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],

      const Divider(height: 32),

      // Prayer Time Calculation Method
      Text(
        loc.prayerTimeCalculationMethod,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      Platform.isIOS
          ? GestureDetector(
              onTap: () {
                _showCalculationMethodPicker(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _calcMethodMap[_selectedCalcMethod] ?? '',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
            )
          : Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              child: DropdownButtonFormField<int>(
                value: _selectedCalcMethod,
                isExpanded: true,
                menuMaxHeight: 350,
                decoration: InputDecoration(
                  labelText: loc.calculationMethod,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

      const SizedBox(height: 20),
    ];
  }

  Widget _buildGoogleCalendarSection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final googleService = Provider.of<GoogleCalendarService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
          child: Text(
            loc.googleCalendar,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Google account status
        FutureBuilder<bool>(
          future: _checkGoogleCalendarState(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final isConnected = snapshot.data ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status
                ListTile(
                  leading: Icon(
                    isConnected
                        ? Icons.check_circle
                        : Icons.account_circle_outlined,
                    color: isConnected
                        ? (isDarkMode
                            ? Colors.greenAccent
                            : Colors.green.shade700)
                        : null,
                  ),
                  title: Text(
                    isConnected
                        ? loc.googleCalendarConnected
                        : loc.googleCalendarDisconnected,
                    style: TextStyle(
                      color: isConnected
                          ? (isDarkMode
                              ? Colors.greenAccent
                              : Colors.green.shade700)
                          : null,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                if (isConnected)
                  const Divider(height: 1, indent: 16, endIndent: 16),

                // Manage calendars button
                if (isConnected)
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(loc.selectWhichCalendarsToSync),
                    onTap: _showCalendarSelectionDialog,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                  ),

                // Import options button
                if (isConnected)
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(loc.importOptions),
                    subtitle: Text(loc.importFromGoogleCalendar),
                    onTap: () => _showImportOptionsDialog(context),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                  ),

                // Divider before disconnect button
                if (isConnected)
                  const Divider(height: 1, indent: 16, endIndent: 16),

                // Disconnect button
                if (isConnected)
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(loc.disconnect),
                    onTap: () async {
                      await googleService.signOut();
                      setState(() {});
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                  ),

                // Connect button
                if (!isConnected)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(loc.connectWithGoogleCalendar),
                      onPressed: () async {
                        try {
                          await googleService.signIn();
                          setState(() {});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${loc.googleSignInError}: ${e.toString()}'),
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildOutlookCalendarSection(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
          child: Text(
            loc.outlookCalendar,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Outlook account status
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(loc.outlookCalendarDisconnected),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),

        // Connect button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(loc.connectWithOutlookCalendar,
                style: const TextStyle(
                  inherit: true,
                )),
            onPressed: () async {
              try {
                // Placeholder für Outlook-Verbindungsimplementierung
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.outlookCalendarComingSoon)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connection error: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        // Coming soon text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            loc.outlookCalendarComingSoon,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),

        const Divider(height: 1),
      ],
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

  /// Hilfsmethode hinzufügen, um zu prüfen, ob der LocationService verfügbar ist
  bool _locationServiceAvailable() {
    try {
      return _locationService != null;
    } catch (e) {
      return false;
    }
  }

  /// Zeigt einen Dialog für Import-Optionen an
  void _showImportOptionsDialog(BuildContext context) {
    // Die gemeinsame Implementierung von ImportSettingsService verwenden
    ImportSettingsService.showImportOptionsDialog(context);
  }

  // Neue Methode für den iOS Picker
  void _showCalculationMethodPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        Provider.of<AppLocalizations>(context).cancel,
                        style: const TextStyle(fontSize: 17),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      Provider.of<AppLocalizations>(context)
                          .prayerTimeCalculationMethod,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        Provider.of<AppLocalizations>(context).ok,
                        style: const TextStyle(fontSize: 17),
                      ),
                      onPressed: () async {
                        await _saveSettings();
                        await _updatePrayerTimes();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44.0,
                  backgroundColor:
                      CupertinoColors.systemBackground.resolveFrom(context),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedCalcMethod =
                          _calcMethodMap.keys.elementAt(index);
                    });
                  },
                  children: _calcMethodMap.entries
                      .map(
                        (entry) => Center(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 20,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
