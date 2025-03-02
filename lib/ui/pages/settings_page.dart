// lib/ui/pages/settings_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:muslim_calendar/data/services/google_calendar_api.dart';
import 'package:muslim_calendar/data/services/outlook_sync_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/providers/theme_notifier.dart';

import '../../data/services/google_sync_service.dart';

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

  bool _googleCalendarEnabled = false;
  bool _appleCalendarEnabled = false;
  bool _outlookCalendarEnabled = false;
  SyncFrequency _googleCalendarSyncFrequency = SyncFrequency.daily;
  SyncFrequency _appleCalendarSyncFrequency = SyncFrequency.daily;
  SyncFrequency _outlookCalendarSyncFrequency = SyncFrequency.daily;
  bool _googleCalendarConnected = false;
  bool _appleCalendarConnected = false;
  bool _outlookCalendarConnected = false;

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

    _googleCalendarEnabled = prefs.getBool('googleCalendarEnabled') ?? false;
    _appleCalendarEnabled = prefs.getBool('appleCalendarEnabled') ?? false;
    _outlookCalendarEnabled = prefs.getBool('outlookCalendarEnabled') ?? false;
    _googleCalendarSyncFrequency = SyncFrequency.values[prefs.getInt('googleSyncFrequency') ?? 0];
    _appleCalendarSyncFrequency = SyncFrequency.values[prefs.getInt('appleSyncFrequency') ?? 0];
    _outlookCalendarSyncFrequency = SyncFrequency.values[prefs.getInt('outlookSyncFrequency') ?? 0];

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

  Future<bool> _connectToGoogleCalendar(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    
    final success = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.connectGoogle),
        content: Text(loc.connectGoogleDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.connect),
          ),
        ],
      ),
    );
    
    if (success == true) {
      
      //await Provider.of<OutlookSyncService>(context, listen: false).calendarProvider.signIn();
      setState(() => _googleCalendarConnected = true);
      return true;
    }
    return false;
  }

  Future<void> _manageGoogleCalendarConnection(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.manageConnection),
        content: Text(loc.manageConnectionPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'disconnect'),
            child: Text(loc.disconnect),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );

    if (action == 'disconnect') {
      await Provider.of<GoogleSyncService>(context, listen: false).calendarProvider.signOut();
      setState(() => _googleCalendarConnected = false);
      await _saveSettings();
    }
  }

  Future<bool> _connectToAppleCalendar(BuildContext context) async {
    // Implement Apple Calendar integration
    return true;
  }

  Future<void> _manageAppleCalendarConnection(BuildContext context) async {

  }

  Future<bool> _connectToOutlookCalendar(BuildContext context) async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    
    final success = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.connectOutlook),
        content: Text(loc.connectOutlookDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.connect),
          ),
        ],
      ),
    );
    
    if (success == true) {
      
      await Provider.of<OutlookSyncService>(context, listen: false).calendarProvider.signIn();
      setState(() => _outlookCalendarConnected = true);
      return true;
    }
    return false;
  }

  Future<void> _manageOutlookCalendarConnection(BuildContext context) async {

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

    // Daily/Week
    await prefs.setBool('showPrayerTimesInDayView', _showPrayerTimesInDayView);
    await prefs.setBool(
        'showPrayerTimesInWeekView', _showPrayerTimesInWeekView);

    // Gebets-Berechnungsmethode
    await prefs.setInt('calculationMethod', _selectedCalcMethod);

    await prefs.setBool('googleCalendarEnabled', _googleCalendarEnabled);
    await prefs.setBool('appleCalendarEnabled', _appleCalendarEnabled);
    await prefs.setBool('outlookCalendarEnabled', _outlookCalendarEnabled);
    await prefs.setInt('googleSyncFrequency', _googleCalendarSyncFrequency.index);
    await prefs.setInt('appleSyncFrequency', _appleCalendarSyncFrequency.index);
    await prefs.setInt('outlookSyncFrequency', _outlookCalendarSyncFrequency.index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    // WICHTIG: Bei iOS packen wir den Inhalt in eine Material-Hülle,
    // damit Widgets wie DropdownButtonFormField, ListTile usw.
    // nicht den "TextField widgets require a Material ancestor"-Fehler werfen.
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
            child: SafeArea(
              child: Material(
                child: _buildSettingsList(loc),
              ),
            ),
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
          // Beachte: wir haben hier invertierte Logik => s. Original:
          // "value: _locationMode == LocationMode.manual" => an = manual
          value: _locationMode == LocationMode.manual,
          onChanged: (bool value) async {
            setState(() {
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
          Icons.email_outlined,
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


        // Falls Android => Save-Button extra
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
                    child: const Text('Close'),
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
  Widget _buildCalendarIntegration(
    String title,
    IconData icon,
    bool enabled,
    bool connected,
    SyncFrequency frequency,
    Function(bool) onEnabledChanged,
    Future<bool> Function() onConnectPressed,
    Function(SyncFrequency) onFrequencyChanged,
  ) {
    final loc = Provider.of<AppLocalizations>(context);
    
    return Column(
      children: [
        SwitchListTile.adaptive(
          title: Text(title),
          value: enabled,
          onChanged: onEnabledChanged,
          secondary: Icon(icon),
        ),
        if (enabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final success = await onConnectPressed();
                    if (success) {
                      setState(() {});
                      await _saveSettings();
                    }
                  },
                  child: Text(connected ? loc.manageConnection : loc.connect),
                ),
                const SizedBox(width: 8),
                if (connected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),
          if (connected) ...[
            _buildFrequencySelector(loc, frequency, onFrequencyChanged),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _handleManualSync(true, title),
                  child: Text(loc.importFromCalendar),
                ),
                ElevatedButton(
                  onPressed: () => _handleManualSync(false, title),
                  child: Text(loc.exportToCalendar),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }
  Future<void> _handleManualSync(bool isImport, String serviceName) async {
  final loc = Provider.of<AppLocalizations>(context, listen: false);
  final String google = loc.googleCalendar;
  final String apple = loc.appleCalendar;
  final String outlook = loc.outlookCalendar;

  try {
    // İf-else ile servis karşılaştırması yapıyoruz
    if (serviceName == google) {
      final googleSyncService = Provider.of<GoogleSyncService>(context, listen: false);
      if (isImport) {
        await googleSyncService.importAppointments();
      } else {
        await googleSyncService.exportAppointments();
      }
    } else if (serviceName == outlook) {
      if (isImport) {
        //await outlookCalendarSyncService.importAppointments();
      } else {
        //await outlookCalendarSyncService.exportAppointments();
      }
    } else if (serviceName == apple) {
      if (isImport) {
        //await appleCalendarSyncService.importAppointments();
      } else {
        //await appleCalendarSyncService.exportAppointments();
      }
    } else {
      // Bilinmeyen servis durumunda exception fırlatılıyor
      throw Exception("Bilinmeyen servis: $serviceName");
    }

    // Başarı mesajı gösterme
    if (isImport) {
      await _showSuccessDialog(loc.importSuccess(serviceName));
    } else {
      await _showSuccessDialog(loc.exportSuccess(serviceName));
    }
  } catch (e) {
    // Hata mesajı gösterme
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
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(Provider.of<AppLocalizations>(ctx).ok),
          ),
        ],
      ),
    );
  }
  Widget _buildFrequencySelector(
    AppLocalizations loc,
    SyncFrequency currentFrequency,
    Function(SyncFrequency) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: DropdownButtonFormField<SyncFrequency>(
        value: currentFrequency,
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
            _saveSettings();
          }
        },
        items: [
          DropdownMenuItem(
            value: SyncFrequency.none,
            child: Text(loc.noSync),
          ),
          DropdownMenuItem(
            value: SyncFrequency.daily,
            child: Text(loc.dailySync),
          ),
          DropdownMenuItem(
            value: SyncFrequency.weekly,
            child: Text(loc.weeklySync),
          ),
          DropdownMenuItem(
            value: SyncFrequency.monthly,
            child: Text(loc.monthlySync),
          ),
        ],
      ),
    );
  }

}
