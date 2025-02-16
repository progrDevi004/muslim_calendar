import 'dart:convert';
import 'dart:io' show Platform; // Für isIOS
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models & Enums
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/enums.dart';

// Localization
import 'package:muslim_calendar/localization/app_localizations.dart';

// Repositories
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';

// Models
import 'package:muslim_calendar/models/category_model.dart';

// Notification Service
import 'package:muslim_calendar/data/services/notification_service.dart';

// Für das Zeitformat
import 'package:intl/intl.dart';

// AutomaticCategoryService
import 'package:muslim_calendar/data/services/automatic_category_service.dart';

class AppointmentCreationPage extends StatefulWidget {
  final int? appointmentId;
  final DateTime? selectedDate;

  const AppointmentCreationPage({
    this.appointmentId,
    this.selectedDate,
    Key? key,
  }) : super(key: key);

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

  // Ort (Land / Stadt)
  String? _selectedCountry;
  String? _selectedCity;
  Map<String, List<String>> _countryCityData = {};

  // Wiederkehrende Termine
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  RecurrenceRange _recurrenceRange = RecurrenceRange.noEndDate;
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

  // Repository
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // Umschalter für erweiterte Optionen
  bool _showAdvancedOptions = false;

  // Zeitformat (24h vs. AM/PM)
  bool _use24hFormat = false;

  // Interne Variable, die die (ggf. frisch erzeugte) Appointment-ID hält
  int? _currentAppointmentId;

  // AZIZ: isCategoryDropdownClicked
  bool _isCategoryDropdownClicked = false;

  // >>> NEU: Um Mehrfachklicks zu verhindern
  bool _isSaving = false;

  bool get _isIos => Platform.isIOS;

  /// Wandelt den internen AppLanguage-Wert in einen Locale-Code (String) um.
  AppLanguage? _lastLanguage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _loadUserPrefs();
    _loadCountryCityData();
    _loadCategories();
    _initDefaultValues();
    _loadAppointmentData();

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
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoCategorizeIfNeeded);
    _descriptionController.removeListener(_autoCategorizeIfNeeded);
    _titleController.dispose();
    _descriptionController.dispose();
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
      _recurrenceType = RecurrenceType.weekly;

      // Datum: entweder widget.selectedDate oder "heute"
      final baseDate = widget.selectedDate ?? DateTime.now();

      // >>> Startzeit 12:00, Endzeit 12:30
      _startTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 0);
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
            // Felder füllen
            _titleController.text = appointment.subject;
            _descriptionController.text = appointment.notes ?? '';
            _isAllDay = appointment.isAllDay;
            _isRelatedToPrayerTimes = appointment.isRelatedToPrayerTimes;
            _selectedPrayerTime = appointment.prayerTime;
            _selectedTimeRelation = appointment.timeRelation;
            _minutesBeforeAfter = appointment.minutesBeforeAfter;
            _duration = appointment.duration ?? const Duration(minutes: 30);
            _startTime = appointment.startTime ?? DateTime.now();
            _endTime = appointment.endTime ??
                _startTime!.add(const Duration(minutes: 30));
            _color = appointment.color;
            _selectedReminderMinutes = appointment.reminderMinutesBefore;

            if (appointment.location != null) {
              final parts = appointment.location!.split(',');
              if (parts.length == 2) {
                _selectedCity = parts[0].trim();
                _selectedCountry = parts[1].trim();
              }
            }

            // Wiederkehrend
            if (appointment.recurrenceRule != null) {
              final recurrenceProperties = SfCalendar.parseRRule(
                appointment.recurrenceRule!,
                appointment.startTime ?? DateTime.now(),
              );
              _isRecurring = true;
              _recurrenceType = recurrenceProperties.recurrenceType;
              _recurrenceInterval = recurrenceProperties.interval;
              _recurrenceRange = recurrenceProperties.recurrenceRange;
              _recurrenceCount = recurrenceProperties.recurrenceCount;
              _recurrenceEndDate = recurrenceProperties.endDate;

              if (_recurrenceType == RecurrenceType.weekly) {
                _selectedWeekDays = List.filled(7, false);
                for (var wd in recurrenceProperties.weekDays) {
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
              final catIndex = _allCategories.indexWhere(
                  (element) => element.id == appointment.categoryId);
              if (catIndex != -1) {
                _selectedCategory = _allCategories[catIndex];
              }
            }

            // NEU: Unsere lokale ID-Variable
            _currentAppointmentId = appointment.id;
          });
        }
      } catch (e) {
        final loc = Provider.of<AppLocalizations>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorLoadingAppointment}: $e')),
        );
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

  /// Termin löschen (angepasst!)
  Future<void> _deleteAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    if (_currentAppointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noAppointmentToDelete)),
      );
      return;
    }

    bool confirmDelete = await _showAdaptiveDialog(
      context: context,
      title: loc.deleteAppointmentTitle,
      content: loc.deleteAppointmentConfirmation,
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

    if (confirmDelete) {
      try {
        // 1) Termin in DB löschen
        await _appointmentRepo.deleteAppointment(_currentAppointmentId!);

        // 2) Notification stornieren
        try {
          await NotificationService()
              .cancelNotification(_currentAppointmentId!);
        } catch (notifErr) {
          debugPrint('iOS-Knackpunkt (CreationPage): $notifErr');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.appointmentDeletedSuccessfully)),
        );

        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorDeletingAppointment)),
        );
      }
    }
  }

  /// Termin speichern (Neu oder Update)
  Future<void> _saveAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    // >>> NEU: Mehrfaches Klicken verhindern
    if (_isSaving) {
      return; // Wenn gerade am Speichern, nichts tun
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

        _endTime ??= _startTime!.add(const Duration(minutes: 30));

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
          final recurrence = RecurrenceProperties(
            startDate: safeStart,
            recurrenceType: _recurrenceType,
            interval: _recurrenceInterval,
            recurrenceRange: _recurrenceRange,
          );

          if (_recurrenceType == RecurrenceType.weekly) {
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
          } else if (_recurrenceType == RecurrenceType.monthly) {
            recurrence.dayOfMonth = safeStart.day;
          } else if (_recurrenceType == RecurrenceType.yearly) {
            recurrence.month = safeStart.month;
            recurrence.dayOfMonth = safeStart.day;
          }

          if (_recurrenceRange == RecurrenceRange.count) {
            _recurrenceCount = _recurrenceCount ?? 1;
            recurrence.recurrenceCount = _recurrenceCount!;
          } else if (_recurrenceRange == RecurrenceRange.endDate) {
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
          color: _color,
          startTime: _startTime,
          endTime: _endTime,
          categoryId: _selectedCategory?.id,
          reminderMinutesBefore: _selectedReminderMinutes,
        );

        if (_currentAppointmentId == null) {
          // Neuer Termin
          final newId = await _appointmentRepo.insertAppointment(appointment);

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

          setState(() {
            _currentAppointmentId = newId;
          });
        } else {
          // Update Termin
          await NotificationService()
              .cancelNotification(_currentAppointmentId!);
          await _appointmentRepo.updateAppointment(appointment);

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

  // --------------------------------------------------------------------------
  // NEU: Separate Methoden für Datum und Zeit (unverändert)
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
        // Wenn AllDay => Endzeit = +1h vom Start
        if (_isAllDay) {
          _endTime = _startTime!.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    if (_startTime == null) {
      // Falls noch kein Start-Datum gewählt, nimm "Heute"
      _startTime = DateTime.now();
    }
    final pickedTime = await _pickAdaptiveTime(_startTime!);
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        // Endzeit ggf. anpassen
        if (_isAllDay) {
          _endTime = _startTime!.add(const Duration(hours: 1));
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
          _endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _endTime!.hour,
            _endTime!.minute,
          );
        } else {
          _endTime = pickedDate;
        }
        if (_isAllDay &&
            _startTime != null &&
            _endTime!.isBefore(_startTime!)) {
          // End-Datum ist vor Start-Datum => nimm Start + 1h
          _endTime = _startTime!.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    if (_endTime == null) {
      // Falls noch kein End-Datum gewählt, nimm StartTime oder Heute
      _endTime = _startTime ?? DateTime.now();
    }
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
  // --------------------------------------------------------------------------
  // ENDE NEU

  /// Hilfsmethode zum Formatieren der Zeit (unverändert)
  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  /// NEU: Hilfsmethode zum Formatieren des Datums
  String _formatDate(DateTime dt) {
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  // --------------------------------------------------------------------------
  // NEU: Aufbau des UI – Google Kalender–Stil
  Widget _buildGoogleCalendarForm(AppLocalizations loc) {
    return Form(
      key: _formKey,
      child: ListView(
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
              validator: (value) =>
                  (value == null || value.isEmpty) ? loc.titleLabel : null,
            ),
          ),
          const Divider(height: 1),
          // Startzeit
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Start'),
            subtitle: Text(_startTime != null
                ? '${_formatDate(_startTime!)}, ${_formatTime(_startTime!)}'
                : '---'),
            onTap: () async {
              await _pickStartDate();
              await _pickStartTime();
            },
          ),
          // Endzeit
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End'),
            subtitle: Text(_endTime != null
                ? '${_formatDate(_endTime!)}, ${_formatTime(_endTime!)}'
                : '---'),
            onTap: () async {
              await _pickEndDate();
              await _pickEndTime();
            },
          ),
          // All-Day Schalter
          SwitchListTile.adaptive(
            title: Text(loc.allDay),
            value: _isAllDay,
            onChanged: (bool value) {
              setState(() {
                _isAllDay = value;
                if (value && _startTime != null) {
                  _endTime = _startTime!.add(const Duration(hours: 1));
                }
              });
            },
          ),
          const Divider(height: 1),
          // Kategorie & Farbe
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _color,
            ),
            title: Text(_selectedCategory != null
                ? _selectedCategory!.name
                : loc.selectCategoryLabel),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showCategorySelectionDialog(loc);
            },
          ),
          // Erinnerung
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(loc.reminderInMinutes),
            subtitle: Text(_selectedReminderMinutes != null
                ? (_selectedReminderMinutes! < 60
                    ? loc.minutesBefore(_selectedReminderMinutes!)
                    : _selectedReminderMinutes! < 1440
                        ? loc.hoursBefore(_selectedReminderMinutes! ~/ 60)
                        : loc.daysBefore(_selectedReminderMinutes! ~/ 1440))
                : loc.noReminder),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showReminderSelectionDialog(loc);
            },
          ),
          const Divider(height: 1),
          // Mehr Optionen ein-/ausklappen
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: Text(
                _showAdvancedOptions ? loc.fewerOptions : loc.advancedOptions),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () {
              setState(() {
                _showAdvancedOptions = !_showAdvancedOptions;
              });
            },
          ),
          if (_showAdvancedOptions) ...[
            // Beschreibung
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: loc.description),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            // Gebetszeit Einstellungen
            SwitchListTile.adaptive(
              title: Text(loc.relatedToPrayerTimes),
              subtitle: Text(loc.relatedToPrayerTimesSubtitle),
              value: _isRelatedToPrayerTimes,
              onChanged: (bool value) {
                setState(() {
                  _isRelatedToPrayerTimes = value;
                  if (value && _startTime != null) {
                    _endTime = _startTime!.add(const Duration(hours: 1));
                  }
                });
              },
            ),
            if (_isRelatedToPrayerTimes) ...[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(loc.selectDate),
                subtitle: Text(_startTime != null
                    ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year}'
                    : loc.selectDate),
                onTap: () async {
                  final picked = await _showAdaptiveDatePicker(
                    context: context,
                    initialDate: _startTime ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _startTime = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        _startTime?.hour ?? 12,
                        _startTime?.minute ?? 0,
                      );
                      _endTime = _startTime!.add(const Duration(hours: 1));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: Text(loc.prayerTime),
                subtitle: Text(_selectedPrayerTime != null
                    ? loc.getPrayerTimeLabel(_selectedPrayerTime!)
                    : loc.selectPrayerTime),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showPrayerTimeSelectionDialog(loc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(loc.timeRelation),
                subtitle: Text(_selectedTimeRelation != null
                    ? loc.getTimeRelationLabel(_selectedTimeRelation!)
                    : loc.timeRelation),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showTimeRelationSelectionDialog(loc);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minutesBeforeAfter?.toString(),
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: loc.minutesBeforeAfter),
                        onChanged: (value) {
                          setState(() {
                            _minutesBeforeAfter = int.tryParse(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _duration?.inMinutes.toString(),
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: loc.durationMinutes),
                        onChanged: (value) {
                          setState(() {
                            _duration =
                                Duration(minutes: int.tryParse(value) ?? 30);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            // Recurrence
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(loc.recurrence),
              subtitle: Text(_isRecurring ? loc.recurringEvent : ''),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  _isRecurring = !_isRecurring;
                });
              },
            ),
            if (_isRecurring) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<RecurrenceType>(
                  value: _recurrenceType,
                  decoration: InputDecoration(labelText: loc.recurrenceType),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceType = value!;
                      if (_recurrenceType == RecurrenceType.weekly) {
                        _selectedWeekDays = List.filled(7, false);
                        if (_startTime != null) {
                          final index = (_startTime!.weekday - 1) % 7;
                          _selectedWeekDays[index] = true;
                        }
                      }
                    });
                  },
                  items: RecurrenceType.values.map((type) {
                    return DropdownMenuItem<RecurrenceType>(
                      value: type,
                      child: Text(loc.getRecurrenceTypeLabel(type)),
                    );
                  }).toList(),
                ),
              ),
              if (_recurrenceType == RecurrenceType.weekly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: List.generate(7, (index) {
                      final dayNames = [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN'
                      ];
                      return FilterChip(
                        label: Text(dayNames[index]),
                        selected: _selectedWeekDays[index],
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedWeekDays[index] = selected;
                          });
                        },
                      );
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  initialValue: _recurrenceInterval.toString(),
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: loc.recurrenceInterval),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceInterval = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<RecurrenceRange>(
                  value: _recurrenceRange,
                  decoration: InputDecoration(labelText: loc.recurrenceRange),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceRange = value!;
                    });
                  },
                  items: RecurrenceRange.values.map((range) {
                    return DropdownMenuItem<RecurrenceRange>(
                      value: range,
                      child: Text(loc.getRecurrenceRangeLabel(range)),
                    );
                  }).toList(),
                ),
              ),
              if (_recurrenceRange == RecurrenceRange.count)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    initialValue: _recurrenceCount?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.recurrenceCount),
                    onChanged: (value) {
                      setState(() {
                        _recurrenceCount = int.tryParse(value);
                      });
                    },
                  ),
                ),
              if (_recurrenceRange == RecurrenceRange.endDate)
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: Text(loc.recurrenceEndDate),
                  subtitle:
                      Text(_recurrenceEndDate?.toString() ?? loc.selectEndDate),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final selectedDate = await _showAdaptiveDatePicker(
                      context: context,
                      initialDate: _recurrenceEndDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _recurrenceEndDate = selectedDate;
                      });
                    }
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FilledButton(
                  onPressed: _addExceptionDate,
                  child: Text(loc.addExceptionDate),
                ),
              ),
              if (_exceptionDates.isNotEmpty)
                Column(
                  children: _exceptionDates.map((date) {
                    return ListTile(
                      title: Text(date.toIso8601String()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _exceptionDates.remove(date);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isIos
                ? CupertinoButton.filled(
                    child: Text(loc.save),
                    onPressed: _saveAppointment,
                  )
                : FilledButton(
                    onPressed: _saveAppointment,
                    child: Text(loc.save),
                  ),
          ),
        ],
      ),
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
          child: _buildGoogleCalendarForm(loc),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.appointmentId == null
              ? loc.createAppointment
              : loc.editAppointment),
        ),
        body: _buildGoogleCalendarForm(loc),
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
}

/// >>> NEU: Hilfs-Widget zum automatischen Selektieren beim Fokus (wie im Original)
class _OverwriteOnFocus extends StatelessWidget {
  final Widget child;
  const _OverwriteOnFocus({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      return _SelectAllOnFocusChild(child: child);
    });
  }
}

class _SelectAllOnFocusChild extends StatefulWidget {
  final Widget child;
  const _SelectAllOnFocusChild({required this.child, Key? key})
      : super(key: key);

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
  const _SelectAllInterceptor({required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SelectAllTextOnFocusInherited(
      child: child,
    );
  }
}

class _SelectAllTextOnFocusInherited extends InheritedWidget {
  const _SelectAllTextOnFocusInherited({Key? key, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_SelectAllTextOnFocusInherited oldWidget) => false;
}

// --------------------------------------------------------------------------
// NEU: Zusätzliche Dialog-Methoden für Reminder, Gebetszeit, Länder/City, Kategorie etc.
// --------------------------------------------------------------------------

extension _DialogHelpers on _AppointmentCreationPageState {
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
              children: _reminderOptions.map((option) {
                String text;
                if (option == null) {
                  text = loc.noReminder;
                } else if (option < 60) {
                  text = loc.minutesBefore(option);
                } else if (option < 1440) {
                  text = loc.hoursBefore(option ~/ 60);
                } else {
                  text = loc.daysBefore(option ~/ 1440);
                }
                return ListTile(
                  title: Text(text),
                  onTap: () {
                    setState(() {
                      _selectedReminderMinutes = option;
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
            // cancelButton: CupertinoDialogAction(
            //   onPressed: () => Navigator.pop(context),
            //   child: Text(loc.cancel),
            // ),
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
}
