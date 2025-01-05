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

    // Neu: Listeners zur automatischen Kategorisierung
    _titleController.addListener(_autoCategorizeIfNeeded);
    _descriptionController.addListener(_autoCategorizeIfNeeded);

    _currentAppointmentId = widget.appointmentId;
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
    final String response =
        await rootBundle.loadString('assets/country_city_data.json');
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

  /// Termin löschen
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
        await NotificationService().cancelNotification(_currentAppointmentId!);
        await _appointmentRepo.deleteAppointment(_currentAppointmentId!);

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
  // NEU: Vier separate Methoden zum Auswählen von Start-/End-Datum und -Zeit
  // --------------------------------------------------------------------------

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
    final pickedTime = await _pickTime(_startTime!);
    if (pickedTime != null) {
      setState(() {
        _startTime = DateTime(
          _startTime!.year,
          _startTime!.month,
          _startTime!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
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
    final pickedTime = await _pickTime(_endTime!);
    if (pickedTime != null) {
      setState(() {
        _endTime = DateTime(
          _endTime!.year,
          _endTime!.month,
          _endTime!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (_startTime != null && _endTime!.isBefore(_startTime!)) {
          // Endzeit vor Start => +30min
          _endTime = _startTime!.add(const Duration(minutes: 30));
        }
      });
    }
  }

  // --------------------------------------------------------------------------
  // Ende NEU
  // --------------------------------------------------------------------------

  /// Hilfsfunktion: Datum+Zeit-Picker (nicht mehr für Start-/Endzeit genutzt,
  /// aber behalten für andere Einsatzzwecke)
  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required bool isAllDay,
  }) async {
    final date = await _showAdaptiveDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    if (isAllDay) {
      return date;
    }

    // Zeit abfragen
    final newDateTime = await _pickTime(date);
    return newDateTime ?? date;
  }

  /// >>> TimePicker
  Future<DateTime?> _pickTime(DateTime dateBase) async {
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

  /// Anzeigeformat
  String _formatTime(DateTime dt) {
    final pattern = _use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final headlineStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return _isIos
        ? CupertinoPageScaffold(
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
              child: _buildMainBody(headlineStyle, loc),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(widget.appointmentId == null
                  ? loc.createAppointment
                  : loc.editAppointment),
            ),
            body: _buildMainBody(headlineStyle, loc),
          );
  }

  Widget _buildMainBody(TextStyle? headlineStyle, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.general, style: headlineStyle),
            const SizedBox(height: 12),

            // Titel
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '${loc.titleLabel} *'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? loc.titleLabel : null,
            ),
            const SizedBox(height: 12),

            // NUR sichtbar, wenn NICHT auf PrayerTimes bezogen
            if (!_isRelatedToPrayerTimes) ...[
              // NEU: Start-Datum/-Zeit + End-Datum/-Zeit separat
              Text(loc.startDate,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Start-Datum
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: _buildDateDisplay(
                        label: loc.date,
                        dateTime: _startTime,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Start-Zeit
                  if (!_isAllDay)
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        child: _buildTimeDisplay(
                          label: loc.time,
                          dateTime: _startTime,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(loc.endDate, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  // End-Datum
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: _buildDateDisplay(
                        label: loc.date,
                        dateTime: _endTime,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // End-Zeit
                  if (!_isAllDay)
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        child: _buildTimeDisplay(
                          label: loc.time,
                          dateTime: _endTime,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Kategorie & Farbe
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CategoryModel>(
                    value: _selectedCategory,
                    decoration:
                        InputDecoration(labelText: loc.selectCategoryLabel),
                    items: _allCategories.map((cat) {
                      return DropdownMenuItem<CategoryModel>(
                        value: cat,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _isCategoryDropdownClicked = true;
                        if (_selectedCategory != null) {
                          _color = _selectedCategory!.color;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _pickColor(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.color_lens,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ganztägig
            SwitchListTile.adaptive(
              title: Text(loc.allDay),
              subtitle: Text(loc.allDaySubtitle),
              value: _isAllDay,
              onChanged: !_isRelatedToPrayerTimes
                  ? (bool value) {
                      setState(() {
                        _isAllDay = value;
                        if (value && _startTime != null) {
                          _endTime = _startTime!.add(const Duration(hours: 1));
                        }
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            // Erinnerung
            DropdownButtonFormField<int?>(
              value: _selectedReminderMinutes,
              decoration: InputDecoration(labelText: loc.reminderInMinutes),
              onChanged: (val) {
                setState(() {
                  _selectedReminderMinutes = val;
                });
              },
              items: _reminderOptions.map((option) {
                if (option == null) {
                  return DropdownMenuItem<int?>(
                    value: null,
                    child: Text(loc.noReminder),
                  );
                } else if (option < 60) {
                  return DropdownMenuItem<int?>(
                    value: option,
                    child: Text(loc.minutesBefore(option)),
                  );
                } else if (option < 1440) {
                  final h = option ~/ 60;
                  return DropdownMenuItem<int?>(
                    value: option,
                    child: Text(loc.hoursBefore(h)),
                  );
                } else {
                  final d = option ~/ 1440;
                  return DropdownMenuItem<int?>(
                    value: option,
                    child: Text(loc.daysBefore(d)),
                  );
                }
              }).toList(),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {
                setState(() {
                  _showAdvancedOptions = !_showAdvancedOptions;
                });
              },
              child: Text(
                _showAdvancedOptions ? loc.fewerOptions : loc.advancedOptions,
              ),
            ),
            const SizedBox(height: 8),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showAdvancedOptions
                  ? _buildAdvancedOptions(loc, headlineStyle)
                  : const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Speichern / Löschen Buttons (nur bei Android in der Footer-Leiste, bei iOS ins Nav)
            if (!_isIos)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _saveAppointment,
                    child: Text(loc.save),
                  ),
                  if (_currentAppointmentId != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _deleteAppointment,
                      child: Text(loc.delete),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Erweitere Optionen
  Widget _buildAdvancedOptions(AppLocalizations loc, TextStyle? headlineStyle) {
    return Column(
      key: const ValueKey('advancedOptions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(labelText: loc.description),
        ),
        const SizedBox(height: 12),
        Text(loc.prayerTimeSettings, style: headlineStyle),
        SwitchListTile.adaptive(
          title: Text(loc.relatedToPrayerTimes),
          subtitle: Text(loc.relatedToPrayerTimesSubtitle),
          value: _isRelatedToPrayerTimes,
          onChanged: !_isAllDay
              ? (bool value) {
                  setState(() {
                    _isRelatedToPrayerTimes = value;
                    if (value && _startTime != null) {
                      _endTime = _startTime!.add(const Duration(hours: 1));
                    }
                  });
                }
              : null,
        ),
        if (_isRelatedToPrayerTimes) ...[
          ListTile(
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
                  );
                  _endTime = _startTime!.add(const Duration(hours: 1));
                });
              }
            },
          ),
          DropdownButtonFormField<PrayerTime>(
            value: _selectedPrayerTime,
            hint: Text(loc.selectPrayerTime),
            decoration: InputDecoration(labelText: loc.prayerTime),
            onChanged: (value) {
              setState(() {
                _selectedPrayerTime = value;
              });
            },
            items: PrayerTime.values.map((pt) {
              return DropdownMenuItem<PrayerTime>(
                value: pt,
                child: Text(loc.getPrayerTimeLabel(pt)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TimeRelation>(
            value: _selectedTimeRelation,
            decoration: InputDecoration(labelText: loc.timeRelation),
            items: TimeRelation.values.map((timeRelation) {
              return DropdownMenuItem<TimeRelation>(
                value: timeRelation,
                child: Text(loc.getTimeRelationLabel(timeRelation)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeRelation = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _minutesBeforeAfter?.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: loc.minutesBeforeAfter),
            onChanged: (value) {
              _minutesBeforeAfter = int.tryParse(value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _duration?.inMinutes.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: loc.durationMinutes),
            onChanged: (value) {
              _duration = Duration(minutes: int.tryParse(value) ?? 30);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _countryCityData.keys.contains(_selectedCountry)
                ? _selectedCountry
                : null,
            hint: Text(loc.selectCountry),
            decoration: InputDecoration(labelText: loc.country),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedCity = null;
              });
            },
            items: _countryCityData.keys.map((c) {
              return DropdownMenuItem<String>(
                value: c,
                child: Text(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_selectedCountry != null)
            DropdownButtonFormField<String>(
              value: (_selectedCity != null &&
                      _countryCityData[_selectedCountry]!
                          .contains(_selectedCity))
                  ? _selectedCity
                  : null,
              hint: Text(loc.selectCity),
              decoration: InputDecoration(labelText: loc.city),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
              items: _countryCityData[_selectedCountry]!.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
            ),
        ],
        const SizedBox(height: 24),
        Text(loc.recurrence, style: headlineStyle),
        SwitchListTile.adaptive(
          title: Text(loc.recurringEvent),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
        ),
        if (_isRecurring) ...[
          DropdownButtonFormField<RecurrenceType>(
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
          if (_recurrenceType == RecurrenceType.weekly) ...[
            const SizedBox(height: 12),
            Text(
              loc.recurrenceDays,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
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
                  shape: const StadiumBorder(),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedWeekDays[index] = selected;
                    });
                  },
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _recurrenceInterval.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: loc.recurrenceInterval),
            onChanged: (value) {
              _recurrenceInterval = int.tryParse(value) ?? 1;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RecurrenceRange>(
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
          if (_recurrenceRange == RecurrenceRange.count) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _recurrenceCount?.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.recurrenceCount),
              onChanged: (value) {
                _recurrenceCount = int.tryParse(value);
              },
            ),
          ],
          if (_recurrenceRange == RecurrenceRange.endDate) ...[
            const SizedBox(height: 12),
            ListTile(
              title: Text(loc.recurrenceEndDate),
              subtitle: Text(
                _recurrenceEndDate?.toString() ?? loc.selectEndDate,
              ),
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
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _addExceptionDate,
            child: Text(loc.addExceptionDate),
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
    );
  }

  // >>> NEU: Separate UI-Bausteine für Datum und Zeit

  Widget _buildDateDisplay({
    required String label,
    required DateTime? dateTime,
  }) {
    final text = (dateTime != null)
        ? '${dateTime.day}.${dateTime.month}.${dateTime.year}'
        : '---';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor =
        isDark ? Colors.grey[800]! : const Color.fromARGB(255, 245, 245, 245);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required DateTime? dateTime,
  }) {
    final text = (dateTime != null) ? _formatTime(dateTime) : '---';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor =
        isDark ? Colors.grey[800]! : const Color.fromARGB(255, 245, 245, 245);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Farbwahl
  void _pickColor(BuildContext context) {
    Color tempColor = _color;
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final dialog = AlertDialog(
          title: Text(loc.select),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _color,
              onColorChanged: (Color c) {
                tempColor = c;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(loc.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: Text(loc.select),
              onPressed: () {
                setState(() {
                  _color = tempColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );

        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: Text(loc.select),
                content: SizedBox(
                  height: 300,
                  child: BlockPicker(
                    pickerColor: _color,
                    onColorChanged: (Color c) {
                      tempColor = c;
                    },
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      setState(() {
                        _color = tempColor;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(loc.select),
                  ),
                ],
              )
            : dialog;
      },
    );
  }

  /// Zeigt einen adaptiven Dialog (Bestätigung)
  Future<bool> _showAdaptiveDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
  }) async {
    if (Platform.isIOS) {
      // Cupertino
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
      // Material
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

  /// Zeigt einen adaptiven DatePicker (vereinfacht)
  Future<DateTime?> _showAdaptiveDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
  }) async {
    if (Platform.isIOS) {
      // iOS: Wir zeigen ein CupertinoDatePicker in einem Modal
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
      // Android / Material
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: helpText,
      );
    }
  }
}

/// >>> NEU: Hilfs-Widget, um bei Eingabe-Feldern (Std/Min) alles zu selektieren,
/// sodass direkt überschrieben wird.
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

/// Kümmert sich darum, die Flutter-internen Textfelder für Stunden/Minuten
/// zu finden und bei Fokus alles zu markieren.
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
