import 'dart:convert';
import 'dart:io' show Platform; // Für isIOS
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
// Korrekter Import für die RecurrenceType Enum mit Präfix
import 'package:syncfusion_flutter_calendar/src/calendar/common/enums.dart'
    as sf;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models & Enums - Benutze Präfix für eigene Enums
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/enums.dart';

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';

// Repositories
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';

// Models
import 'package:muslim_calendar/models/category_model.dart';

// Services
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/data/services/automatic_category_service.dart';
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';

// Für das Zeitformat
import 'package:intl/intl.dart';

// CalendarSyncService
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';

class AppointmentCreationPage extends StatefulWidget {
  final int? appointmentId;
  final DateTime? selectedDate;

  const AppointmentCreationPage({
    this.appointmentId,
    this.selectedDate,
    super.key,
  });

  @override
  _AppointmentCreationPageState createState() =>
      _AppointmentCreationPageState();
}

class _AppointmentCreationPageState extends State<AppointmentCreationPage> {
  final _formKey = GlobalKey<FormState>();

  // Titel & Beschreibung
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // Gebetszeit-Flags
  bool _isAllDay = false;
  bool _isRelatedToPrayerTimes = false;
  PrayerTime? _selectedPrayerTime;
  TimeRelation? _selectedTimeRelation;
  int? _minutesBeforeAfter;
  Duration? _duration;

  // Start-/Endzeit
  DateTime? _startTime;
  DateTime? _endTime;
  AppLocalizations? _loc;

  // Ort (Land / Stadt)
  String? _selectedCountry;
  String? _selectedCity;
  Map<String, List<String>> _countryCityData = {};

  // NEU: Google Kalender Synchronisierung
  bool _syncWithGoogleCalendar = false;

  // Wiederkehrende Termine
  bool _isRecurring = false;
  sf.RecurrenceType _recurrenceType = sf.RecurrenceType.daily;
  // Flag, ob eine benutzerdefinierte Wiederholung verwendet wird
  bool _isCustomRecurrence = false;
  int _recurrenceInterval = 1;
  sf.RecurrenceRange _recurrenceRange = sf.RecurrenceRange.noEndDate;
  int? _recurrenceCount;
  DateTime? _recurrenceEndDate;
  List<DateTime> _exceptionDates = [];
  List<bool> _selectedWeekDays = List.filled(7, false);

  // Kategorie/Farbe
  Color _color = Colors.blue;
  final CategoryRepository _categoryRepo = CategoryRepository();
  List<CategoryModel> _allCategories = [];
  CategoryModel? _selectedCategory;

  // Erinnerung (Benachrichtigung)
  int? _selectedReminderMinutes;
  final List<int?> _reminderOptions = [null, 5, 15, 30, 60, 120, 1440];
  // NEU: Liste für mehrere Erinnerungen
  List<int> _remindersList = [];
  final int _maxReminders = 4;

  // Repository
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // Umschalter für erweiterte Optionen
  bool _showAdvancedOptions = false;

  // Zeitformat (24h vs. AM/PM)
  bool _use24hFormat = false;

  // Interne Variable, die die (ggf. frisch erzeugte) Appointment-ID hält
  int? _currentAppointmentId;

  // AZIZ: isCategoryDropdownClicked
  final bool _isCategoryDropdownClicked = false;

  // >>> NEU: Um Mehrfachklicks zu verhindern
  bool _isSaving = false;

  bool get _isIos => Platform.isIOS;

  /// Wandelt den internen AppLanguage-Wert in einen Locale-Code (String) um.
  AppLanguage? _lastLanguage;

  // Repositories und Services
  final NotificationService _notificationService = NotificationService();
  final PrayerTimeService _prayerTimeService =
      PrayerTimeService(PrayerTimeRepository());

  // Füge die _location Variable hinzu (nach den anderen Deklarationen)
  String? _location;

  // CalendarSyncService
  late CalendarSyncService _calendarSyncService;

  // Füge die Hilfsmethode für die Konvertierung von Wochentagen ein (vor der _loadAppointmentData Methode)
  // Hilfsmethode für die Umwandlung von String-Tagesbezeichnungen in WeekDays Enum
  WeekDays _stringToWeekDay(String dayStr) {
    switch (dayStr) {
      case "MO":
        return WeekDays.monday;
      case "TU":
        return WeekDays.tuesday;
      case "WE":
        return WeekDays.wednesday;
      case "TH":
        return WeekDays.thursday;
      case "FR":
        return WeekDays.friday;
      case "SA":
        return WeekDays.saturday;
      case "SU":
        return WeekDays.sunday;
      default:
        return WeekDays.monday; // Fallback
    }
  }

  // Füge die Methode zur Analyse des Wiederholungstyps hinzu
  sf.RecurrenceType _parseRecurrenceType(String? recurrenceRule) {
    if (recurrenceRule == null) {
      return sf.RecurrenceType.daily; // Verwende daily als Ersatz für 'none'
    }

    if (recurrenceRule.contains("FREQ=DAILY")) {
      return sf.RecurrenceType.daily;
    } else if (recurrenceRule.contains("FREQ=WEEKLY")) {
      return sf.RecurrenceType.weekly;
    } else if (recurrenceRule.contains("FREQ=MONTHLY")) {
      return sf.RecurrenceType.monthly;
    } else if (recurrenceRule.contains("FREQ=YEARLY")) {
      return sf.RecurrenceType.yearly;
    }

    return sf.RecurrenceType.daily; // Fallback
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _loadUserPrefs();
    _loadCountryCityData();

    // Immer die Kategorien neu laden, um sicherzustellen, dass auch neu importierte Kategorien angezeigt werden
    _loadCategories();

    // Zuerst Kategorien laden, dann Termindaten, um sicherzustellen, dass die Kategorien verfügbar sind
    _loadCategories().then((_) {
      debugPrint("📂 Kategorien geladen: ${_allCategories.length}");
      if (widget.appointmentId != null) {
        debugPrint("🔍 Lade Termin mit ID: ${widget.appointmentId}");
      }
      _initDefaultValues();
      _loadAppointmentData();
    });

    // Listener zur automatischen Kategorisierung
    _titleController.addListener(_autoCategorizeIfNeeded);
    _descriptionController.addListener(_autoCategorizeIfNeeded);

    _currentAppointmentId = widget.appointmentId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang =
        Provider.of<AppLocalizations>(context, listen: false).currentLanguage;
    if (_lastLanguage != currentLang) {
      _lastLanguage = currentLang;
      // Bei Sprachwechsel neu laden:
      _loadCountryCityData();
    }

    // CalendarSyncService registrieren
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: true);

    // Listener hinzufügen, um auf Änderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoCategorizeIfNeeded);
    _descriptionController.removeListener(_autoCategorizeIfNeeded);
    _titleController.dispose();
    _descriptionController.dispose();
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);
    super.dispose();
  }

  /// Lädt das Zeitformat aus SharedPreferences
  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24hFormat = prefs.getBool('use24hFormat') ?? false;
    });
  }

  /// Land/Stadt-JSON laden
  Future<void> _loadCountryCityData() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final languageCode = loc.mapAppLanguageToCode(loc.currentLanguage);
    final String response =
        await rootBundle.loadString('assets/country_city_$languageCode.json');
    final Map<String, dynamic> data = json.decode(response);
    setState(() {
      _countryCityData = data.map((key, value) =>
          MapEntry<String, List<String>>(key, List<String>.from(value)));
    });
  }

  /// Standardwerte (nur wenn appointmentId == null)
  void _initDefaultValues() async {
    if (widget.appointmentId == null) {
      // Land & Stadt
      final prefs = await SharedPreferences.getInstance();
      final country = prefs.getString('defaultCountry');
      final city = prefs.getString('defaultCity');
      if (country != null && city != null) {
        setState(() {
          _selectedCountry = country;
          _selectedCity = city;
        });
      }

      // Gebetszeit-Defaults
      _selectedPrayerTime = PrayerTime.dhuhr;
      _minutesBeforeAfter = 15;
      _selectedTimeRelation = TimeRelation.after;
      _duration = const Duration(minutes: 30);
      _isAllDay = false;

      // Wiederholung = weekly
      _recurrenceType = sf.RecurrenceType.weekly;

      // Datum: entweder widget.selectedDate oder "heute"
      final baseDate = widget.selectedDate ??
          DateTime(DateTime.now().day, DateTime.now().month, DateTime.now().day,
              12, 0);

      // >>> Startzeit 12:00, Endzeit 12:30
      _startTime = DateTime(baseDate.year, baseDate.month, baseDate.day,
          baseDate.hour, baseDate.minute);
      _endTime = _startTime!.add(const Duration(minutes: 30));

      // Wochentag markieren
      _selectedWeekDays = List.filled(7, false);
      final index = (_startTime!.weekday - 1) % 7;
      _selectedWeekDays[index] = true;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryRepo.getAllCategories();
    setState(() {
      _allCategories = categories;
      if (widget.appointmentId == null && _allCategories.isNotEmpty) {
        _selectedCategory = _allCategories.first;
        _color = _selectedCategory!.color;
      }
    });
  }

  /// Termin laden (falls appointmentId != null)
  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId != null) {
      try {
        final appointment =
            await _appointmentRepo.getAppointment(widget.appointmentId!);
        if (appointment != null) {
          setState(() {
            // Debug-Info
            debugPrint(
                "🔄 Lade Termin ID: ${appointment.id}, Kategorie-ID: ${appointment.categoryId}");

            // Titel & Beschreibung
            _titleController.text = appointment.subject;
            _descriptionController.text = appointment.notes ?? '';

            // Zeit & Dauer
            _startTime = appointment.startTime;
            _endTime = appointment.endTime;
            _isAllDay = appointment.isAllDay;

            // Wiederholung & Ausnahmetage
            _isRecurring = appointment.recurrenceRule != null;
            _recurrenceType = _parseRecurrenceType(appointment.recurrenceRule);
            _recurrenceRange = sf.RecurrenceRange.noEndDate;
            _isCustomRecurrence =
                false; // Standardmäßig ist es kein benutzerdefinierter Typ

            _color = appointment.color;

            // Gebetszeitverknüpfung
            _isRelatedToPrayerTimes = appointment.isRelatedToPrayerTimes;
            _selectedPrayerTime = appointment.prayerTime;
            _selectedTimeRelation = appointment.timeRelation;
            _minutesBeforeAfter = appointment.minutesBeforeAfter ?? 0;
            _duration = appointment.duration ?? const Duration(minutes: 30);

            // Setze den Reminder-Wert
            _selectedReminderMinutes = appointment.reminderMinutesBefore;

            // Rücksetzen der Reminder-Liste
            _remindersList = [];

            // Wenn eine Erinnerung vorhanden ist, füge sie der Liste hinzu
            if (appointment.reminderMinutesBefore != null &&
                appointment.reminderMinutesBefore! > 0) {
              _remindersList.add(appointment.reminderMinutesBefore!);
            }

            // Standort
            _location = appointment.location ?? '';
            if (appointment.location != null) {
              final parts = appointment.location!.split(',');
              if (parts.length == 2) {
                _selectedCity = parts[0].trim();
                _selectedCountry = parts[1].trim();
              }
            }

            // Setze Google Calendar Sync Flag
            _syncWithGoogleCalendar = appointment.externalIdGoogle != null;

            // Extraktion der Wochentage für wöchentliche Wiederholung
            if (_recurrenceType == sf.RecurrenceType.weekly &&
                appointment.recurrenceRule != null) {
              final rule = appointment.recurrenceRule!;
              final weekDaysMatch = RegExp(r'BYDAY=([^;]+)').firstMatch(rule);
              if (weekDaysMatch != null) {
                final weekDaysStr = weekDaysMatch.group(1)!;
                final weekDays = weekDaysStr.split(',');
                for (var dayStr in weekDays) {
                  final wd = _stringToWeekDay(dayStr);
                  if (wd == WeekDays.monday) _selectedWeekDays[0] = true;
                  if (wd == WeekDays.tuesday) _selectedWeekDays[1] = true;
                  if (wd == WeekDays.wednesday) _selectedWeekDays[2] = true;
                  if (wd == WeekDays.thursday) _selectedWeekDays[3] = true;
                  if (wd == WeekDays.friday) _selectedWeekDays[4] = true;
                  if (wd == WeekDays.saturday) _selectedWeekDays[5] = true;
                  if (wd == WeekDays.sunday) _selectedWeekDays[6] = true;
                }
              }
            }
            _exceptionDates = appointment.recurrenceExceptionDates ?? [];

            // Kategorie
            if (appointment.categoryId != null) {
              // Debug-Ausgabe zur Fehlersuche
              debugPrint(
                  "🔍 Suche Kategorie für Termin: ID=${appointment.categoryId}");
              debugPrint(
                  "📋 Verfügbare Kategorien: ${_allCategories.map((c) => '${c.id}:${c.name}').join(', ')}");

              final catIndex = _allCategories.indexWhere(
                  (element) => element.id == appointment.categoryId);

              if (catIndex != -1) {
                _selectedCategory = _allCategories[catIndex];
                debugPrint(
                    "✅ Kategorie gefunden und ausgewählt: ${_selectedCategory!.name} (ID: ${_selectedCategory!.id})");
                // Setze auch die Farbe der Kategorie
                _color = _selectedCategory!.color;
              } else {
                debugPrint(
                    "⚠️ Keine passende Kategorie gefunden für ID=${appointment.categoryId}");
                // Fallback: Verwende die erste Kategorie
                if (_allCategories.isNotEmpty) {
                  _selectedCategory = _allCategories.first;
                  debugPrint(
                      "🔄 Fallback auf erste Kategorie: ${_selectedCategory!.name}");
                }
              }
            } else {
              debugPrint("ℹ️ Termin hat keine Kategorie-ID, verwende Standard");
              // Fallback: Verwende die erste Kategorie
              if (_allCategories.isNotEmpty) {
                _selectedCategory = _allCategories.first;
              }
            }

            // NEU: Unsere lokale ID-Variable
            _currentAppointmentId = appointment.id;
          });
        }
      } catch (e) {
        debugPrint("Fehler beim Laden des Termins: $e");
      }
    }
  }

  /// NEU: automatische Kategorisierung, wenn noch keine manuelle Kategorie gewählt wurde
  void _autoCategorizeIfNeeded() {
    // Falls User schon manuell ausgewählt hat => nicht überschreiben
    if (!_isCategoryDropdownClicked) {
      final title = _titleController.text.trim();
      final notes = _descriptionController.text.trim();
      final suggestion = AutomaticCategoryService.suggestCategoryName(
          title, notes.isEmpty ? null : notes);

      if (suggestion != null) {
        // Gibt es in _allCategories einen Eintrag mit .name == suggestion?
        final idx = _allCategories.indexWhere(
          (cat) => cat.name.toUpperCase() == suggestion.toUpperCase(),
        );
        if (idx != -1) {
          setState(() {
            _selectedCategory = _allCategories[idx];
            _color = _selectedCategory!.color;
          });
        }
      }
    }
  }

  /// Termin speichern (Neu oder Update)
  Future<void> _saveAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    // Verhindern, dass Speichern mehrfach aufgerufen wird
    if (_isSaving) return;

    // Zunächst Formular validieren
    if (!_formKey.currentState!.validate()) {
      // Wenn die Validierung fehlschlägt, Fehler anzeigen und abbrechen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte füllen Sie alle erforderlichen Felder aus')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_formKey.currentState!.validate()) {
        if (_startTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseSelectStartTimeError)),
          );
          return;
        }

        // Endzeit-Validierung und -Berechnung
        if (_isRelatedToPrayerTimes) {
          // Bei gebetszeitabhängigen Terminen berechnen wir die Endzeit aus der Dauer
          if (_duration == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bitte geben Sie eine Dauer an')),
            );
            return;
          }

          // Die Endzeit wird automatisch aus der berechneten Startzeit und der Dauer ermittelt
          // Wir müssen hier nichts tun, da die Berechnung in der PrayerTimeService geschieht
        } else {
          // Bei normalen Terminen prüfen wir, ob eine Endzeit angegeben wurde
          _endTime ??= _startTime!.add(const Duration(minutes: 30));
        }

        // Aktualisiere _selectedReminderMinutes aus der _remindersList
        if (_remindersList.isNotEmpty) {
          _selectedReminderMinutes = _remindersList.first;
        }

        final location = (_isRelatedToPrayerTimes &&
                _selectedCity != null &&
                _selectedCountry != null)
            ? '$_selectedCity,$_selectedCountry'
            : (!_isRelatedToPrayerTimes &&
                    _selectedCity != null &&
                    _selectedCountry != null)
                ? '$_selectedCity,$_selectedCountry'
                : null;

        // Recurrence generieren (falls Schalter an)
        String? recurrenceRule;
        if (_isRecurring) {
          final safeStart = _startTime ?? DateTime.now();
          final safeEnd =
              _endTime ?? safeStart.add(const Duration(minutes: 30));

          // Konvertiere unser RecurrenceType in das Syncfusion RecurrenceType
          var sfRecurrenceType = sf.RecurrenceType.daily;
          switch (_recurrenceType) {
            case sf.RecurrenceType.daily:
              sfRecurrenceType = sf.RecurrenceType.daily;
              break;
            case sf.RecurrenceType.weekly:
              sfRecurrenceType = sf.RecurrenceType.weekly;
              break;
            case sf.RecurrenceType.monthly:
              sfRecurrenceType = sf.RecurrenceType.monthly;
              break;
            case sf.RecurrenceType.yearly:
              sfRecurrenceType = sf.RecurrenceType.yearly;
              break;
            default:
              // Für benutzerdefinierte Wiederholungen verwenden wir den ausgewählten Typ
              sfRecurrenceType = _recurrenceType;
              break;
          }

          final recurrence = RecurrenceProperties(
            startDate: safeStart,
            recurrenceType: sfRecurrenceType,
            interval: _recurrenceInterval,
            recurrenceRange: _recurrenceRange,
          );

          if (_recurrenceType == sf.RecurrenceType.weekly) {
            recurrence.weekDays.clear();
            if (_selectedWeekDays[0]) recurrence.weekDays.add(WeekDays.monday);
            if (_selectedWeekDays[1]) recurrence.weekDays.add(WeekDays.tuesday);
            if (_selectedWeekDays[2]) {
              recurrence.weekDays.add(WeekDays.wednesday);
            }
            if (_selectedWeekDays[3]) {
              recurrence.weekDays.add(WeekDays.thursday);
            }
            if (_selectedWeekDays[4]) recurrence.weekDays.add(WeekDays.friday);
            if (_selectedWeekDays[5]) {
              recurrence.weekDays.add(WeekDays.saturday);
            }
            if (_selectedWeekDays[6]) recurrence.weekDays.add(WeekDays.sunday);
          } else if (_recurrenceType == sf.RecurrenceType.monthly) {
            recurrence.dayOfMonth = safeStart.day;
          } else if (_recurrenceType == sf.RecurrenceType.yearly) {
            recurrence.month = safeStart.month;
            recurrence.dayOfMonth = safeStart.day;
          }

          if (_recurrenceRange == sf.RecurrenceRange.count) {
            _recurrenceCount = _recurrenceCount ?? 1;
            recurrence.recurrenceCount = _recurrenceCount!;
          } else if (_recurrenceRange == sf.RecurrenceRange.endDate) {
            recurrence.endDate = _recurrenceEndDate;
          }

          recurrenceRule =
              SfCalendar.generateRRule(recurrence, safeStart, safeEnd);
        }

        final appointment = AppointmentModel(
          id: _currentAppointmentId,
          subject: _titleController.text,
          notes: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          isAllDay: _isAllDay,
          isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
          prayerTime: _isRelatedToPrayerTimes ? _selectedPrayerTime : null,
          timeRelation: _isRelatedToPrayerTimes ? _selectedTimeRelation : null,
          minutesBeforeAfter:
              _isRelatedToPrayerTimes ? _minutesBeforeAfter : null,
          duration: _isRelatedToPrayerTimes ? _duration : null,
          location: location,
          recurrenceRule: recurrenceRule,
          recurrenceExceptionDates:
              _exceptionDates.isNotEmpty ? _exceptionDates : null,
          recurrenceEndDate: _recurrenceRange == sf.RecurrenceRange.endDate
              ? _recurrenceEndDate
              : null,
          color: _color,
          startTime: _startTime,
          // Bei gebetszeitabhängigen Terminen setzen wir die Endzeit auf null,
          // da die korrekte Endzeit später durch den Service berechnet wird
          endTime: _isRelatedToPrayerTimes ? null : _endTime,
          categoryId: _selectedCategory?.id,
          reminderMinutesBefore: _selectedReminderMinutes,
          // NEU: Flag für Google Kalender Synchronisierung
          syncWithGoogleCalendar: _syncWithGoogleCalendar,
        );

        if (_currentAppointmentId == null) {
          // Neuer Termin
          final newId = await _appointmentRepo.insertAppointment(appointment);

          // Wenn der Termin gebetszeitabhängig ist, müssen wir die berechneten Zeiten abrufen
          if (_isRelatedToPrayerTimes && appointment.prayerTime != null) {
            final baseDate = DateTime(
              appointment.startTime!.year,
              appointment.startTime!.month,
              appointment.startTime!.day,
            );

            // Berechnete Start- und Endzeiten abrufen
            final calculatedStart =
                await _prayerTimeService.getCalculatedStartTime(
              appointment,
              baseDate,
            );
            final calculatedEnd = await _prayerTimeService.getCalculatedEndTime(
              appointment,
              baseDate,
            );

            if (calculatedStart != null && calculatedEnd != null) {
              // Neues Appointment mit berechneten Zeiten erstellen
              final finalAppointment = appointment.copyWith(
                id: newId,
                startTime: calculatedStart,
                endTime: calculatedEnd,
              );

              // In DB aktualisieren
              await _appointmentRepo.updateAppointment(finalAppointment);
            }
          }

          if (_selectedReminderMinutes != null &&
              _selectedReminderMinutes! > 0 &&
              appointment.startTime != null) {
            final reminderTime = appointment.startTime!
                .subtract(Duration(minutes: _selectedReminderMinutes!));
            await NotificationService().scheduleNotification(
              appointmentId: newId,
              title: '${loc.reminderTitle}: ${appointment.subject}',
              body: loc.reminderBody,
              dateTime: reminderTime,
            );
          }

          // NEU: Google Kalender Synchronisierung für neuen Termin
          if (_syncWithGoogleCalendar) {
            _syncWithGoogle(appointment.copyWith(id: newId));
          }
        } else {
          // Update Termin
          await NotificationService()
              .cancelNotification(_currentAppointmentId!);
          await _appointmentRepo.updateAppointment(appointment);

          // Wenn der Termin gebetszeitabhängig ist, müssen wir die berechneten Zeiten abrufen
          if (_isRelatedToPrayerTimes && appointment.prayerTime != null) {
            final baseDate = DateTime(
              appointment.startTime!.year,
              appointment.startTime!.month,
              appointment.startTime!.day,
            );

            // Berechnete Start- und Endzeiten abrufen
            final calculatedStart =
                await _prayerTimeService.getCalculatedStartTime(
              appointment,
              baseDate,
            );
            final calculatedEnd = await _prayerTimeService.getCalculatedEndTime(
              appointment,
              baseDate,
            );

            if (calculatedStart != null && calculatedEnd != null) {
              // Neues Appointment mit berechneten Zeiten erstellen
              final finalAppointment = appointment.copyWith(
                startTime: calculatedStart,
                endTime: calculatedEnd,
              );

              // In DB aktualisieren
              await _appointmentRepo.updateAppointment(finalAppointment);
            }
          }

          if (_selectedReminderMinutes != null &&
              _selectedReminderMinutes! > 0 &&
              appointment.startTime != null) {
            final reminderTime = appointment.startTime!
                .subtract(Duration(minutes: _selectedReminderMinutes!));
            await NotificationService().scheduleNotification(
              appointmentId: _currentAppointmentId!,
              title: '${loc.reminderTitle}: ${appointment.subject}',
              body: loc.reminderBody,
              dateTime: reminderTime,
            );
          }

          // NEU: Google Kalender Synchronisierung für aktualisierten Termin
          if (_syncWithGoogleCalendar) {
            _syncWithGoogle(appointment);
          }
        }

        if (!mounted) return;

        Navigator.pop(context, true);
      }
    } catch (e) {
      // Im Fehlerfall -> Snackbar
      final loc = Provider.of<AppLocalizations>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorSavingAppointment}: $e')),
      );
    } finally {
      // Danach wieder Freigabe fürs Speichern
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Fügt ein Ausnahme-Datum hinzu
  void _addExceptionDate() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final picked = await _showAdaptiveDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: loc.addExceptionDate,
    );
    if (picked != null) {
      setState(() {
        _exceptionDates.add(picked);
      });
    }
  }

  /// NEU: Separate Methoden für Datum und Zeit (unverändert)
  Future<void> _pickStartDate() async {
    final pickedDate = await _showAdaptiveDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pick Start Date',
    );
    if (pickedDate != null) {
      setState(() {
        if (_startTime != null) {
          // Uhrzeit übernehmen
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _startTime!.hour,
            _startTime!.minute,
          );
        } else {
          _startTime = pickedDate;
        }

        // Wenn AllDay oder gebetszeit-bezogen => Endzeit anpassen
        if (_isAllDay) {
          // Bei ganztägigen Terminen endet der Tag um 23:59
          _endTime = DateTime(
            _startTime!.year,
            _startTime!.month,
            _startTime!.day,
            23,
            59,
          );
        } else if (_isRelatedToPrayerTimes && _duration != null) {
          // Wenn an Gebetszeit gebunden, Endzeit basierend auf Startzeit + Dauer setzen
          _endTime = _startTime!.add(_duration!);
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    _startTime ??= DateTime.now();
    final pickedTime = await _pickAdaptiveTime(_startTime!);
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        // Endzeit ggf. anpassen
        if (_isAllDay) {
          // Bei ganztägigen Terminen endet der Tag um 23:59
          _endTime = DateTime(
            _startTime!.year,
            _startTime!.month,
            _startTime!.day,
            23,
            59,
          );
        } else if (_endTime != null && _endTime!.isBefore(_startTime!)) {
          // Wenn Endzeit vor Start liegt, Standard = +30min
          _endTime = _startTime!.add(const Duration(minutes: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await _showAdaptiveDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pick End Date',
    );
    if (pickedDate != null) {
      setState(() {
        if (_endTime != null) {
          if (_isAllDay) {
            // Bei ganztägigen Terminen endet der Tag um 23:59
            _endTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              23,
              59,
            );
          } else {
            _endTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _endTime!.hour,
              _endTime!.minute,
            );
          }
        } else {
          if (_isAllDay) {
            _endTime = DateTime(
                pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
          } else {
            _endTime = pickedDate;
          }
        }

        // Sicherstellen, dass das Enddatum nicht vor dem Startdatum liegt
        if (_startTime != null && _endTime!.isBefore(_startTime!)) {
          // End-Datum ist vor Start-Datum => nimm Start + 1h oder Ende des Tages bei ganztägigen
          if (_isAllDay) {
            _endTime = DateTime(
                _startTime!.year, _startTime!.month, _startTime!.day, 23, 59);
          } else {
            _endTime = _startTime!.add(const Duration(hours: 1));
          }
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    _endTime ??= _startTime ?? DateTime.now();
    final pickedTime = await _pickAdaptiveTime(_endTime!);
    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
        if (_startTime != null && _endTime!.isBefore(_startTime!)) {
          // Endzeit vor Start => +30min
          _endTime = _startTime!.add(const Duration(minutes: 30));
        }
      });
    }
  }

  /// Hilfsmethode zum Formatieren der Zeit (unverändert)
  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  /// NEU: Hilfsmethode zum Formatieren des Datums
  String _formatDate(DateTime dt) {
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  /// Gibt den Text für die ausgewählte Wiederholungsoption zurück
  String _getRecurrenceText(AppLocalizations loc) {
    if (!_isRecurring) {
      return loc.noRecurrence;
    }

    if (_isCustomRecurrence) {
      return loc.getRecurrenceTypeLabel("custom");
    }

    switch (_recurrenceType) {
      case sf.RecurrenceType.daily:
        return loc.getRecurrenceTypeLabel("daily");
      case sf.RecurrenceType.weekly:
        return loc.getRecurrenceTypeLabel("weekly");
      case sf.RecurrenceType.monthly:
        return loc.getRecurrenceTypeLabel("monthly");
      case sf.RecurrenceType.yearly:
        return loc.getRecurrenceTypeLabel("yearly");
      default:
        return loc.getRecurrenceTypeLabel("weekly");
    }
  }

  // --------------------------------------------------------------------------
  // NEU: Aufbau des UI – Google Kalender–Stil
  Widget _buildGoogleCalendarForm(AppLocalizations loc) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Titel (groß, ohne Rahmen)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextFormField(
            controller: _titleController,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: loc.titleLabel,
              border: InputBorder.none,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Titel ist erforderlich'
                : null,
          ),
        ),
        const Divider(height: 1),

        // All-Day Schalter - nur anzeigen, wenn nicht an Gebetszeiten gebunden
        if (!_isRelatedToPrayerTimes)
          Material(
            elevation: 0,
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              secondary: const Icon(Icons.access_time),
              title: Text(loc.allDay),
              value: _isAllDay,
              onChanged: (bool value) {
                setState(() {
                  _isAllDay = value;
                  // Ganztägige Termine können nicht an Gebetszeiten gebunden sein
                  if (value) {
                    _isRelatedToPrayerTimes = false;
                    if (_startTime != null) {
                      // Bei ganztägigen Terminen endet der Tag um 23:59
                      _endTime = DateTime(
                        _startTime!.year,
                        _startTime!.month,
                        _startTime!.day,
                        23,
                        59,
                      );
                    }
                  }
                });
              },
            ),
          ),

        // Gebetszeit-Schalter (aus den fortgeschrittenen Optionen hierher verschoben)
        Material(
          elevation: 0,
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.mosque),
            title: Text(loc.relatedToPrayerTimes),
            value: _isRelatedToPrayerTimes,
            onChanged: (bool value) {
              setState(() {
                _isRelatedToPrayerTimes = value;
                // Gebetszeitbezogene Termine können nicht ganztägig sein
                if (value) {
                  _isAllDay = false;
                  if (_startTime != null && _duration != null) {
                    _endTime = _startTime!.add(_duration!);
                  }
                }
              });
            },
          ),
        ),

        // NEU: Google Kalender Synchronisierung
        Material(
          elevation: 0,
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.sync),
            title: const Text("Mit Google Kalender synchronisieren"),
            subtitle:
                const Text("Termin automatisch mit Google Kalender teilen"),
            value: _syncWithGoogleCalendar,
            onChanged: (bool value) {
              setState(() {
                _syncWithGoogleCalendar = value;
              });
            },
          ),
        ),

        // Gebetszeit-Einstellungen direkt im Hauptbereich
        if (_isRelatedToPrayerTimes)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Überschrift für den Abschnitt
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    loc.prayerTimeSettings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Datum auswählen
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(loc.selectDate),
                  subtitle: Text(
                      _startTime != null ? _formatDate(_startTime!) : '---'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await _pickStartDate();
                  },
                  // Größere Touch-Fläche für iOS
                  contentPadding: _isIos
                      ? const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0)
                      : const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                // Gebetszeit auswählen
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(loc.prayerTime),
                  subtitle: Text(_selectedPrayerTime != null
                      ? loc.getPrayerTimeLabel(_selectedPrayerTime!)
                      : loc.selectPrayerTime),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showPrayerTimeSelectionDialog(loc);
                  },
                  // Größere Touch-Fläche für iOS
                  contentPadding: _isIos
                      ? const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0)
                      : const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                // Zeit-Relation (vor/nach)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(loc.timeRelation),
                  subtitle: Text(_selectedTimeRelation != null
                      ? loc.getTimeRelationLabel(_selectedTimeRelation!)
                      : loc.timeRelation),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showTimeRelationSelectionDialog(loc);
                  },
                  // Größere Touch-Fläche für iOS
                  contentPadding: _isIos
                      ? const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0)
                      : const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                // Minuten vor/nach & Dauer
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minutesBeforeAfter?.toString() ?? '15',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.minutesBeforeAfter,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _minutesBeforeAfter = int.tryParse(value) ?? 15;
                              // Aktualisiere auch bei Änderung der Minuten die berechnete Endzeit
                              if (_isRelatedToPrayerTimes &&
                                  _startTime != null &&
                                  _duration != null) {
                                // Wir versuchen, die Startzeit neu zu berechnen
                                _updateCalculatedTimes();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _duration?.inMinutes.toString() ?? '30',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.durationMinutes,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _duration =
                                  Duration(minutes: int.tryParse(value) ?? 30);
                              // Aktualisiere auch die Endzeit basierend auf der neuen Dauer
                              if (_isRelatedToPrayerTimes &&
                                  _startTime != null) {
                                // Bei gebetszeitabhängigen Terminen die Endzeit automatisch aktualisieren
                                _updateCalculatedTimes();
                              } else if (_startTime != null) {
                                // Bei normalen Terminen die Endzeit berechnen
                                _endTime = _startTime!.add(_duration!);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Startzeit und Endzeit nur anzeigen, wenn NICHT an Gebetszeit gebunden
        Container(
          child: Column(
            children: [
              if (!_isRelatedToPrayerTimes) ...[
                // Startzeit
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: ListTile(
                          title: Center(
                            child: Text(
                                _startTime != null
                                    ? _formatDate(_startTime!)
                                    : '---',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          onTap: () async {
                            await _pickStartDate();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24, child: VerticalDivider()),
                    Expanded(
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: ListTile(
                          title: Center(
                            child: Text(
                                _startTime != null
                                    ? _formatTime(_startTime!)
                                    : '--:--',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          onTap: () async {
                            await _pickStartTime();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Endzeit
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: ListTile(
                          title: Center(
                            child: Text(
                                _endTime != null
                                    ? _formatDate(_endTime!)
                                    : '---',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          onTap: () async {
                            await _pickEndDate();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24, child: VerticalDivider()),
                    Expanded(
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: ListTile(
                          title: Center(
                            child: Text(
                                _endTime != null
                                    ? _formatTime(_endTime!)
                                    : '--:--',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          onTap: () async {
                            await _pickEndTime();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Wiederholungs-Widget
        Material(
          elevation: 0,
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.autorenew),
            title: Row(
              children: [
                Expanded(child: Text(_getRecurrenceText(loc))),
                Switch.adaptive(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      // Wenn Wiederholung aktiviert wird, zeige den Dialog zur Konfiguration
                      if (value) {
                        // Wir verzögern den Dialog leicht, damit der Switch-Zustand aktualisiert wird
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _showRecurrenceSelectionDialog();
                        });
                      }
                    });
                  },
                ),
              ],
            ),
            trailing: _isRecurring
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      _showRecurrenceSelectionDialog();
                    },
                  )
                : null,
            onTap: _isRecurring
                ? () {
                    _showRecurrenceSelectionDialog();
                  }
                : null,
          ),
        ),

        // Erinnerung
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bereits hinzugefügte Erinnerungen
            ..._remindersList.map((minutes) {
              String text;
              if (minutes < 60) {
                text = loc.minutesBefore(minutes);
              } else if (minutes < 1440) {
                text = loc.hoursBefore(minutes ~/ 60);
              } else {
                text = loc.daysBefore(minutes ~/ 1440);
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _remindersList.remove(minutes);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

            // Button zum Hinzufügen neuer Erinnerungen
            if (_remindersList.length < _maxReminders)
              Material(
                elevation: 0,
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: Text(loc.addNotifications),
                  onTap: () {
                    _showReminderSelectionDialog(loc);
                  },
                ),
              ),

            const Divider(height: 1),
          ],
        ),

        // Kategorie & Farbe
        Material(
          elevation: 0,
          color: Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _color,
            ),
            title: Text(_selectedCategory != null
                ? _selectedCategory!.name
                : loc.selectCategoryLabel),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showCategorySelectionDialog(loc);
            },
          ),
        ),

        // Beschreibung
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: loc.description),
            minLines: 1,
            maxLines: 3,
          ),
        ),

        const Divider(height: 1),

        // Mehr Optionen ein-/ausklappen
        Material(
          elevation: 0,
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.more_horiz),
            title: Text(
                _showAdvancedOptions ? loc.fewerOptions : loc.advancedOptions),
            trailing: Icon(
              _showAdvancedOptions
                  ? Icons.arrow_drop_up
                  : Icons.arrow_drop_down,
            ),
            onTap: () {
              setState(() {
                _showAdvancedOptions = !_showAdvancedOptions;
              });
            },
          ),
        ),

        if (_showAdvancedOptions) ...[
          // Die Gebetszeit-Einstellungen wurden in den Hauptbereich verschoben

          // Standort (Länder/City)
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(loc.country),
            subtitle: Text(_selectedCountry ?? loc.selectCountry),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showCountrySelectionDialog(loc);
            },
          ),
          if (_selectedCountry != null)
            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text(loc.city),
              subtitle: Text(_selectedCity ?? loc.selectCity),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showCitySelectionDialog(loc);
              },
            ),
        ],

        // Save Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isIos
              ? CupertinoButton.filled(
                  onPressed: _saveAppointment,
                  child: Text(loc.save),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _saveAppointment,
                  child: Text(loc.save),
                ),
        ),
      ],
    );
  }
  // --------------------------------------------------------------------------
  // ENDE NEU: UI im Google Kalender-Stil
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    if (_isIos) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.appointmentId == null
              ? loc.createAppointment
              : loc.editAppointment),
          trailing: GestureDetector(
            onTap: _saveAppointment,
            child: Text(
              loc.save,
              style: const TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: _buildGoogleCalendarForm(loc),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.appointmentId == null
              ? loc.createAppointment
              : loc.editAppointment),
        ),
        body: Form(
          key: _formKey,
          child: _buildGoogleCalendarForm(loc),
        ),
      );
    }
  }

  /// Adaptive Dialog (Bestätigung)
  Future<bool> _showAdaptiveDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
  }) async {
    if (Platform.isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
      return result ?? false;
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
      return result ?? false;
    }
  }

  /// Adaptive DatePicker
  Future<DateTime?> _showAdaptiveDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
  }) async {
    if (Platform.isIOS) {
      DateTime tempDate = initialDate;
      bool confirmed = false;
      await showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  initialDateTime: initialDate,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDate = newDateTime;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CupertinoButton(
                    child: Text(helpText ?? 'Cancel'),
                    onPressed: () {
                      confirmed = false;
                      Navigator.of(ctx).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () {
                      confirmed = true;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      return confirmed ? tempDate : null;
    } else {
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: helpText,
      );
    }
  }

  /// Adaptive TimePicker
  Future<DateTime?> _pickAdaptiveTime(DateTime dateBase) async {
    if (Platform.isIOS) {
      DateTime tempDateTime = dateBase;
      bool confirmed = false;
      await showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: dateBase,
                  use24hFormat: _use24hFormat,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = DateTime(
                      dateBase.year,
                      dateBase.month,
                      dateBase.day,
                      newDateTime.hour,
                      newDateTime.minute,
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      confirmed = false;
                      Navigator.of(ctx).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () {
                      confirmed = true;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      return confirmed ? tempDateTime : null;
    } else {
      final timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: dateBase.hour, minute: dateBase.minute),
        initialEntryMode: TimePickerEntryMode.input,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: _use24hFormat),
            child: _OverwriteOnFocus(child: child ?? const SizedBox()),
          );
        },
      );
      if (timeOfDay == null) return null;
      return DateTime(
        dateBase.year,
        dateBase.month,
        dateBase.day,
        timeOfDay.hour,
        timeOfDay.minute,
        dateBase.second,
        dateBase.millisecond,
        dateBase.microsecond,
      );
    }
  }

  /// Aktualisiert sowohl die Erinnerungsliste als auch den selectedReminderMinutes-Wert
  void _updateReminderState(int minutes) {
    setState(() {
      if (!_remindersList.contains(minutes) &&
          _remindersList.length < _maxReminders) {
        _remindersList.add(minutes);
        _selectedReminderMinutes = minutes;
      }
    });
  }

  Future<void> _showReminderSelectionDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.reminderInMinutes),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                RadioListTile<int>(
                  title: const Text("5 minutes before"),
                  value: 5,
                  groupValue: null,
                  onChanged: (value) {
                    _updateReminderState(5);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<int>(
                  title: const Text("10 minutes before"),
                  value: 10,
                  groupValue: null,
                  onChanged: (value) {
                    _updateReminderState(10);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<int>(
                  title: const Text("30 minutes before"),
                  value: 30,
                  groupValue: null,
                  onChanged: (value) {
                    _updateReminderState(30);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<int>(
                  title: const Text("1 hour before"),
                  value: 60,
                  groupValue: null,
                  onChanged: (value) {
                    _updateReminderState(60);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<int>(
                  title: const Text("1 day before"),
                  value: 1440,
                  groupValue: null,
                  onChanged: (value) {
                    _updateReminderState(1440);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<int>(
                  title: const Text("Custom..."),
                  value: -1,
                  groupValue: null,
                  onChanged: (int? value) {
                    Navigator.pop(context);
                    _showCustomReminderDialog(loc);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog für benutzerdefinierte Erinnerung
  Future<void> _showCustomReminderDialog(AppLocalizations loc) async {
    int customMinutes = 15;

    await showDialog(
      context: context,
      builder: (context) {
        if (_isIos) {
          return CupertinoAlertDialog(
            title: const Text("Custom reminder"),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CupertinoTextField(
                keyboardType: TextInputType.number,
                placeholder: "Minutes before event",
                onChanged: (value) {
                  customMinutes = int.tryParse(value) ?? 15;
                },
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  if (customMinutes > 0) {
                    _updateReminderState(customMinutes);
                  }
                  Navigator.pop(context);
                },
                child: Text(loc.save),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text("Custom reminder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Minutes before event",
                  ),
                  onChanged: (value) {
                    customMinutes = int.tryParse(value) ?? 15;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (customMinutes > 0) {
                    _updateReminderState(customMinutes);
                  }
                  Navigator.pop(context);
                },
                child: Text(loc.save),
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _showPrayerTimeSelectionDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.prayerTime),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: PrayerTime.values.map((pt) {
                return ListTile(
                  title: Text(loc.getPrayerTimeLabel(pt)),
                  onTap: () {
                    setState(() {
                      _selectedPrayerTime = pt;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTimeRelationSelectionDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.timeRelation),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: TimeRelation.values.map((tr) {
                return ListTile(
                  title: Text(loc.getTimeRelationLabel(tr)),
                  onTap: () {
                    setState(() {
                      _selectedTimeRelation = tr;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCountrySelectionDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.selectCountry),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _countryCityData.keys.map((country) {
                return ListTile(
                  title: Text(country),
                  onTap: () {
                    setState(() {
                      _selectedCountry = country;
                      _selectedCity = null;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCitySelectionDialog(AppLocalizations loc) async {
    if (_selectedCountry == null) return;
    List<String> cities = _countryCityData[_selectedCountry]!;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.selectCity),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: cities.map((city) {
                return ListTile(
                  title: Text(city),
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// NEU: Dialog zur Kategoriewahl
  Future<void> _showCategorySelectionDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(loc.selectCategoryLabel),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: _allCategories.map((cat) {
                  return CupertinoDialogAction(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = cat;
                        _color = cat.color;
                      });
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cat.color,
                          radius: 10,
                        ),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        } else {
          return AlertDialog(
            title: Text(loc.selectCategoryLabel),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _allCategories.map((cat) {
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: cat.color),
                    title: Text(cat.name),
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _color = cat.color;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _showRecurrenceSelectionDialog() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          // iOS-optimierter Dialog mit größeren Elementen und plattformspezifischem Styling
          return CupertinoAlertDialog(
            title: Text(loc.recurrence, style: const TextStyle(fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wiederholungstypen direkt anzeigen ohne Switch

                // Täglich
                CupertinoDialogAction(
                  child: Text(
                    loc.getRecurrenceTypeLabel("daily"),
                    style: TextStyle(
                      color: _recurrenceType == sf.RecurrenceType.daily &&
                              !_isCustomRecurrence
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                      fontWeight: _recurrenceType == sf.RecurrenceType.daily &&
                              !_isCustomRecurrence
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _recurrenceType = sf.RecurrenceType.daily;
                      _isCustomRecurrence = false;
                    });
                  },
                ),

                // Wöchentlich
                CupertinoDialogAction(
                  child: Text(
                    loc.getRecurrenceTypeLabel("weekly"),
                    style: TextStyle(
                      color: _recurrenceType == sf.RecurrenceType.weekly &&
                              !_isCustomRecurrence
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                      fontWeight: _recurrenceType == sf.RecurrenceType.weekly &&
                              !_isCustomRecurrence
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _recurrenceType = sf.RecurrenceType.weekly;
                      _isCustomRecurrence = false;
                    });
                  },
                ),

                // Monatlich
                CupertinoDialogAction(
                  child: Text(
                    loc.getRecurrenceTypeLabel("monthly"),
                    style: TextStyle(
                      color: _recurrenceType == sf.RecurrenceType.monthly &&
                              !_isCustomRecurrence
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                      fontWeight:
                          _recurrenceType == sf.RecurrenceType.monthly &&
                                  !_isCustomRecurrence
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _recurrenceType = sf.RecurrenceType.monthly;
                      _isCustomRecurrence = false;
                    });
                  },
                ),

                // Jährlich
                CupertinoDialogAction(
                  child: Text(
                    loc.getRecurrenceTypeLabel("yearly"),
                    style: TextStyle(
                      color: _recurrenceType == sf.RecurrenceType.yearly &&
                              !_isCustomRecurrence
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                      fontWeight: _recurrenceType == sf.RecurrenceType.yearly &&
                              !_isCustomRecurrence
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _recurrenceType = sf.RecurrenceType.yearly;
                      _isCustomRecurrence = false;
                    });
                  },
                ),

                // Benutzerdefiniert
                CupertinoDialogAction(
                  child: Text(
                    loc.getRecurrenceTypeLabel("custom"),
                    style: TextStyle(
                      color: _isCustomRecurrence
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                      fontWeight: _isCustomRecurrence
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isCustomRecurrence = true;
                    });
                    _showCustomRecurrenceDialog(loc);
                  },
                ),

                const SizedBox(height: 10),

                // Ausnahmedaten
                CupertinoDialogAction(
                  child: Text(
                    loc.recurrenceExceptionDates,
                    style: const TextStyle(color: CupertinoColors.label),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showExceptionDateDialog();
                  },
                ),

                // Enddatum
                CupertinoDialogAction(
                  child: Text(
                    loc.recurrenceEndDate,
                    style: const TextStyle(color: CupertinoColors.label),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRecurrenceEndDateDialog();
                  },
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(loc.recurrence),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wiederholungstypen direkt anzeigen ohne Switch

                    // Täglich
                    RadioListTile<sf.RecurrenceType>(
                      title: Text(loc.getRecurrenceTypeLabel("daily")),
                      value: sf.RecurrenceType.daily,
                      groupValue: _isCustomRecurrence ? null : _recurrenceType,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() {
                          _recurrenceType = value!;
                          _isCustomRecurrence = false;
                        });
                      },
                    ),

                    // Wöchentlich
                    RadioListTile<sf.RecurrenceType>(
                      title: Text(loc.getRecurrenceTypeLabel("weekly")),
                      value: sf.RecurrenceType.weekly,
                      groupValue: _isCustomRecurrence ? null : _recurrenceType,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() {
                          _recurrenceType = value!;
                          _isCustomRecurrence = false;
                        });
                      },
                    ),

                    // Monatlich
                    RadioListTile<sf.RecurrenceType>(
                      title: Text(loc.getRecurrenceTypeLabel("monthly")),
                      value: sf.RecurrenceType.monthly,
                      groupValue: _isCustomRecurrence ? null : _recurrenceType,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() {
                          _recurrenceType = value!;
                          _isCustomRecurrence = false;
                        });
                      },
                    ),

                    // Jährlich
                    RadioListTile<sf.RecurrenceType>(
                      title: Text(loc.getRecurrenceTypeLabel("yearly")),
                      value: sf.RecurrenceType.yearly,
                      groupValue: _isCustomRecurrence ? null : _recurrenceType,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() {
                          _recurrenceType = value!;
                          _isCustomRecurrence = false;
                        });
                      },
                    ),

                    // Custom Option hinzufügen
                    RadioListTile<String>(
                      title: Text(loc.getRecurrenceTypeLabel("custom")),
                      value: "custom",
                      groupValue: _isCustomRecurrence ? "custom" : null,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() {
                          _recurrenceType = sf
                              .RecurrenceType.daily; // Verwende daily als Basis
                          _isCustomRecurrence = true;
                        });
                        _showCustomRecurrenceDialog(loc);
                      },
                    ),

                    const Divider(),

                    // Füge einen neuen Eintrag für Ausnahmedaten hinzu
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: Text(loc.recurrenceExceptionDates),
                      subtitle: Text(_exceptionDates.isEmpty
                          ? loc.recurrenceExceptionDatesHint
                          : "${_exceptionDates.length} ${loc.exceptionDatesSelected}"),
                      onTap: () {
                        Navigator.pop(context);
                        _showExceptionDateDialog();
                      },
                    ),

                    // Füge einen neuen Eintrag für das Enddatum hinzu
                    ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(loc.recurrenceEndDate),
                      subtitle: Text(_recurrenceEndDate != null
                          ? _formatDate(_recurrenceEndDate!)
                          : loc.noEndDate),
                      onTap: () {
                        Navigator.pop(context);
                        _showRecurrenceEndDateDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
            ],
          );
        }
      },
    );
  }

  // Füge diese Methode hinzu, um einen Dialog für Ausnahmedaten anzuzeigen
  Future<void> _showExceptionDateDialog() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    List<DateTime> tempExceptionDates = List.from(_exceptionDates);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.recurrenceExceptionDates),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Liste der Ausnahmedaten
                if (tempExceptionDates.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempExceptionDates.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(_formatDate(tempExceptionDates[index])),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () {
                              setState(() {
                                tempExceptionDates.removeAt(index);
                              });
                            },
                            tooltip: loc.removeExceptionDate,
                          ),
                        );
                      },
                    ),
                  ),

                // Button zum Hinzufügen einer Ausnahme
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(loc.addExceptionDate),
                    onPressed: () async {
                      final pickedDate = await _showAdaptiveDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                        helpText: loc.recurrenceExceptionDatesHint,
                      );

                      if (pickedDate != null) {
                        // Prüfen, ob das Datum bereits in der Liste ist
                        bool dateExists = tempExceptionDates.any((date) =>
                            date.year == pickedDate.year &&
                            date.month == pickedDate.month &&
                            date.day == pickedDate.day);

                        if (!dateExists) {
                          setState(() {
                            tempExceptionDates.add(pickedDate);
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _exceptionDates = tempExceptionDates;
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.ok),
            ),
          ],
        ),
      ),
    );
  }

  // Füge diese Methode hinzu, um ein Enddatum für die Wiederholung auszuwählen
  Future<void> _showRecurrenceEndDateDialog() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    final pickedDate = await _showAdaptiveDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 Jahre
      helpText: loc.recurrenceEndDateHint,
    );

    if (pickedDate != null) {
      setState(() {
        _recurrenceEndDate = pickedDate;
        _recurrenceRange = sf.RecurrenceRange.endDate;
      });
    }
  }

  // NEU: Hilfsmethode zur Google Kalender Synchronisierung
  Future<void> _syncWithGoogle(AppointmentModel appointment) async {
    try {
      // CalendarSyncService verwenden
      final loc = Provider.of<AppLocalizations>(context, listen: false);

      // Fortschrittsanzeige anzeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Starte Synchronisierung mit Google...')),
        );
      }

      debugPrint(
          "🔄 Verbesserte Google-Synchronisierung mit CalendarSyncService");

      // SyncWithGoogleCalendar-Flag aktivieren, falls noch nicht geschehen
      if (!appointment.syncWithGoogleCalendar) {
        debugPrint("Aktiviere syncWithGoogleCalendar Flag");
        appointment = appointment.copyWith(syncWithGoogleCalendar: true);
        await _appointmentRepo.updateAppointment(appointment);
        debugPrint("Flag in Datenbank aktualisiert");
      }

      // 1. Alle Wiederholungsregeln korrigieren
      await _calendarSyncService.fixInvalidRecurrenceRules();

      // 2. Sync-Flag für diesen Termin aktivieren (damit er sicher exportiert wird)
      await _appointmentRepo.setGoogleSyncStatus(appointment.id!, true);

      // 3. Export durchführen - nutzt optimierten GoogleCalendarSyncService oder Fallback
      await _calendarSyncService.exportToGoogleCalendarOnly();

      // Feedback anzeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mit Google Kalender synchronisiert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sync Fehler: $e')),
        );
      }
    }
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    debugPrint("🔄 Kategorien wurden geändert, lade neu...");
    _loadCategories();
  }

  // Methode für benutzerdefinierte Wiederholungen
  Future<void> _showCustomRecurrenceDialog(AppLocalizations loc) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.getRecurrenceTypeLabel("custom")),
          content: SizedBox(
            width: double.maxFinite, // Maximale Breite begrenzen
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intervall-Auswahl
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("${loc.recurrenceInterval}:",
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  DropdownButton<int>(
                    isExpanded: true, // Volle Breite nutzen
                    value: _recurrenceInterval,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _recurrenceInterval = value;
                        });
                      }
                    },
                    items: List.generate(30, (index) => index + 1).map((i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text('$i'),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Wiederholungstyp
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("${loc.recurrence}:",
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  DropdownButton<sf.RecurrenceType>(
                    isExpanded: true, // Volle Breite nutzen
                    value: _recurrenceType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _recurrenceType = value;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem<sf.RecurrenceType>(
                        value: sf.RecurrenceType.daily,
                        child: Text(loc.getRecurrenceTypeLabel("daily")),
                      ),
                      DropdownMenuItem<sf.RecurrenceType>(
                        value: sf.RecurrenceType.weekly,
                        child: Text(loc.getRecurrenceTypeLabel("weekly")),
                      ),
                      DropdownMenuItem<sf.RecurrenceType>(
                        value: sf.RecurrenceType.monthly,
                        child: Text(loc.getRecurrenceTypeLabel("monthly")),
                      ),
                      DropdownMenuItem<sf.RecurrenceType>(
                        value: sf.RecurrenceType.yearly,
                        child: Text(loc.getRecurrenceTypeLabel("yearly")),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Wiederholungsbereich
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("${loc.recurrenceRange}:",
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  DropdownButton<sf.RecurrenceRange>(
                    isExpanded: true, // Volle Breite nutzen
                    value: _recurrenceRange,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _recurrenceRange = value;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem<sf.RecurrenceRange>(
                        value: sf.RecurrenceRange.noEndDate,
                        child: Text(loc.noEndDate),
                      ),
                      DropdownMenuItem<sf.RecurrenceRange>(
                        value: sf.RecurrenceRange.endDate,
                        child: Text(loc.recurrenceEndDate),
                      ),
                      DropdownMenuItem<sf.RecurrenceRange>(
                        value: sf.RecurrenceRange.count,
                        child: Text(loc.recurrenceCount),
                      ),
                    ],
                  ),

                  // Anzahl der Wiederholungen (nur wenn RecurrenceRange.count ausgewählt ist)
                  if (_recurrenceRange == sf.RecurrenceRange.count)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextFormField(
                        initialValue: _recurrenceCount?.toString() ?? '10',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.recurrenceCount,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final count = int.tryParse(value);
                          if (count != null && count > 0) {
                            setState(() {
                              _recurrenceCount = count;
                            });
                          }
                        },
                      ),
                    ),

                  // Enddatum auswählen (nur wenn RecurrenceRange.endDate ausgewählt ist)
                  if (_recurrenceRange == sf.RecurrenceRange.endDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await _showRecurrenceEndDateDialog();
                          _showCustomRecurrenceDialog(loc);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.recurrenceEndDate,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(_recurrenceEndDate != null
                                ? _formatDate(_recurrenceEndDate!)
                                : loc.noEndDate),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () {
                this.setState(() {
                  // Die Änderungen werden durch die StatefulBuilder bereits in den State-Variablen gespeichert
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.ok),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecurrenceTypeSelectionDialog(AppLocalizations loc) async {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(loc.selectRecurrenceType),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _recurrenceType = sf.RecurrenceType.daily;
                  });
                  Navigator.pop(context);
                },
                child: Text(loc.getRecurrenceTypeLabel("daily")),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _recurrenceType = sf.RecurrenceType.weekly;
                  });
                  Navigator.pop(context);
                },
                child: Text(loc.getRecurrenceTypeLabel("weekly")),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _recurrenceType = sf.RecurrenceType.monthly;
                  });
                  Navigator.pop(context);
                },
                child: Text(loc.getRecurrenceTypeLabel("monthly")),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _recurrenceType = sf.RecurrenceType.yearly;
                  });
                  Navigator.pop(context);
                },
                child: Text(loc.getRecurrenceTypeLabel("yearly")),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _isCustomRecurrence = true;
                  });
                  Navigator.pop(context);
                  _showCustomRecurrenceDialog(loc);
                },
                child: Text(loc.getRecurrenceTypeLabel("custom")),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              isDestructiveAction: true,
              child: Text(loc.cancel),
            ),
          );
        },
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(loc.selectRecurrenceType),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _recurrenceType = sf.RecurrenceType.daily;
                });
                Navigator.pop(context);
              },
              child: ListTile(
                title: Text(loc.getRecurrenceTypeLabel("daily")),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _recurrenceType = sf.RecurrenceType.weekly;
                });
                Navigator.pop(context);
              },
              child: ListTile(
                title: Text(loc.getRecurrenceTypeLabel("weekly")),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _recurrenceType = sf.RecurrenceType.monthly;
                });
                Navigator.pop(context);
              },
              child: ListTile(
                title: Text(loc.getRecurrenceTypeLabel("monthly")),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _recurrenceType = sf.RecurrenceType.yearly;
                });
                Navigator.pop(context);
              },
              child: ListTile(
                title: Text(loc.getRecurrenceTypeLabel("yearly")),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _isCustomRecurrence = true;
                });
                Navigator.pop(context);
                _showCustomRecurrenceDialog(loc);
              },
              child: ListTile(
                title: Text(loc.getRecurrenceTypeLabel("custom")),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Füge eine neue Methode hinzu, um die berechneten Zeiten zu aktualisieren
  Future<void> _updateCalculatedTimes() async {
    if (!_isRelatedToPrayerTimes || _startTime == null) return;

    // Referenzdatum basierend auf aktuellem Startdatum
    final baseDate = DateTime(
      _startTime!.year,
      _startTime!.month,
      _startTime!.day,
    );

    // Versuche eine Demo-Berechnung des Start-/Endzeitpunkts
    // Wir erstellen ein temporäres AppointmentModel für die Berechnung
    final demoAppointment = AppointmentModel(
      subject: "Temp",
      isAllDay: false,
      isRelatedToPrayerTimes: true,
      prayerTime: _selectedPrayerTime,
      timeRelation: _selectedTimeRelation,
      minutesBeforeAfter: _minutesBeforeAfter,
      duration: _duration,
      location: _selectedCity != null && _selectedCountry != null
          ? "$_selectedCity,$_selectedCountry"
          : null,
      color: Colors.blue,
      startTime: baseDate,
    );

    try {
      // Wir verwenden die Service-Methoden, um eine Vorschau zu generieren
      final calculatedStart = await _prayerTimeService.getCalculatedStartTime(
        demoAppointment,
        baseDate,
      );

      if (calculatedStart != null && _duration != null) {
        final calculatedEnd = calculatedStart.add(_duration!);

        setState(() {
          // Setze die berechneten Werte für Anzeigezwecke
          _startTime = calculatedStart;
          _endTime = calculatedEnd;
        });
      }
    } catch (e) {
      debugPrint("Fehler bei der Vorschauberechnung: $e");
    }
  }
}

/// >>> NEU: Hilfs-Widget zum automatischen Selektieren beim Fokus (wie im Original)
class _OverwriteOnFocus extends StatelessWidget {
  final Widget child;
  const _OverwriteOnFocus({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      return _SelectAllOnFocusChild(child: child);
    });
  }
}

class _SelectAllOnFocusChild extends StatefulWidget {
  final Widget child;
  const _SelectAllOnFocusChild({required this.child, super.key});

  @override
  State<_SelectAllOnFocusChild> createState() => _SelectAllOnFocusChildState();
}

class _SelectAllOnFocusChildState extends State<_SelectAllOnFocusChild> {
  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: _SelectAllInterceptor(child: widget.child),
    );
  }
}

class _SelectAllInterceptor extends StatelessWidget {
  final Widget child;
  const _SelectAllInterceptor({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return _SelectAllTextOnFocusInherited(
      child: child,
    );
  }
}

class _SelectAllTextOnFocusInherited extends InheritedWidget {
  const _SelectAllTextOnFocusInherited({super.key, required super.child});

  @override
  bool updateShouldNotify(_SelectAllTextOnFocusInherited oldWidget) => false;
}
