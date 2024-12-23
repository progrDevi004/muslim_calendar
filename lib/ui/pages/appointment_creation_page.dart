import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';

// Kategorie-Importe
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/models/category_model.dart';

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

  /// Pflichtfelder
  late TextEditingController _titleController;

  /// Optionale Felder
  late TextEditingController _descriptionController;

  /// Gebetszeiten & Standard-Einstellungen
  bool _isAllDay = false;
  bool _isRelatedToPrayerTimes = false;
  PrayerTime? _selectedPrayerTime;
  TimeRelation? _selectedTimeRelation;
  int? _minutesBeforeAfter;
  Duration? _duration;

  /// Datum/Uhrzeit
  DateTime? _startTime;
  DateTime? _endTime;

  /// Location (Voreinstellung)
  String? _defaultCountry;
  String? _defaultCity;
  String? _selectedCountry;
  String? _selectedCity;
  Map<String, List<String>> _countryCityData = {};

  /// Wiederkehrende Termine
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  RecurrenceRange _recurrenceRange = RecurrenceRange.noEndDate;
  int? _recurrenceCount;
  DateTime? _recurrenceEndDate;
  List<DateTime> _exceptionDates = [];
  Color _color = Colors.blue;

  /// Wochentage bei wöchentlicher Wiederholung
  List<bool> _selectedWeekDays = List.filled(7, false);

  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  // Kategorie-Handling
  final CategoryRepository _categoryRepo = CategoryRepository();
  List<CategoryModel> _allCategories = [];
  CategoryModel? _selectedCategory;

  // Schalter für erweiterte Optionen
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _loadCountryCityData();
    _loadCategories();

    _initDefaultValues(); // Voreinstellungen setzen (falls neuer Termin)
    _loadAppointmentData(); // Termin laden, falls bereits vorhanden
  }

  /// Lädt Land/Stadt aus SharedPreferences und setzt weitere Defaults
  /// nur, wenn ein neuer Termin erstellt wird.
  void _initDefaultValues() async {
    if (widget.appointmentId == null) {
      // 1) Werte aus Einstellungen laden (Land, Stadt)
      final prefs = await SharedPreferences.getInstance();
      final country = prefs.getString('defaultCountry');
      final city = prefs.getString('defaultCity');
      if (country != null && city != null) {
        setState(() {
          _selectedCountry = country;
          _selectedCity = city;
        });
      }

      // 2) Gebetszeit = Dhuhr
      _selectedPrayerTime = PrayerTime.dhuhr;

      // 3) Minuten Vor/Nachher = 0
      _minutesBeforeAfter = 0;

      // 4) Zeitbezug = after
      _selectedTimeRelation = TimeRelation.after;

      // 5) Dauer = 30 Minuten, AllDay = false
      _duration = const Duration(minutes: 30);
      _isAllDay = false;

      // 6) Wiederholungstyp = Weekly
      _recurrenceType = RecurrenceType.weekly;

      // >>> FIX: Wochentag basierend auf Startzeit sofort markieren <<<
      final now = DateTime.now();
      _startTime = widget.selectedDate ?? now;
      _endTime = _startTime!.add(const Duration(minutes: 30));

      if (_recurrenceType == RecurrenceType.weekly) {
        _selectedWeekDays = List.filled(7, false);
        if (_startTime != null) {
          final index = (_startTime!.weekday - 1) % 7;
          _selectedWeekDays[index] = true;
        }
      }

      setState(() {});
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryRepo.getAllCategories();
    setState(() {
      _allCategories = categories;
      // Falls neuer Termin und noch keine Kategorie ausgewählt,
      // Standard: nimm erste Kategorie (z. B. "Privat")
      if (widget.appointmentId == null && _allCategories.isNotEmpty) {
        _selectedCategory = _allCategories.first;
        _color = _selectedCategory!.color;
      }
    });
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId != null) {
      try {
        final appointment =
            await _appointmentRepo.getAppointment(widget.appointmentId!);
        if (appointment != null) {
          setState(() {
            // Felder befüllen
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

            // Ort
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

            // Kategorie laden
            if (appointment.categoryId != null) {
              final catIndex = _allCategories.indexWhere(
                  (element) => element.id == appointment.categoryId);
              if (catIndex != -1) {
                _selectedCategory = _allCategories[catIndex];
              }
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointment: $e')),
        );
      }
    }
  }

  Future<void> _loadCountryCityData() async {
    final String response =
        await rootBundle.loadString('assets/country_city_data.json');
    final Map<String, dynamic> data = json.decode(response);
    setState(() {
      _countryCityData = data.map((key, value) =>
          MapEntry<String, List<String>>(key, List<String>.from(value)));
    });
  }

  Future<void> _deleteAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    if (widget.appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No appointment to delete.')),
      );
      return;
    }

    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(loc.deleteAppointmentTitle),
              content: Text(loc.deleteAppointmentConfirmation),
              actions: <Widget>[
                TextButton(
                  child: Text(loc.cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                FilledButton(
                  child: Text(loc.delete),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        await _appointmentRepo.deleteAppointment(widget.appointmentId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment deleted successfully.')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error deleting appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting appointment.')),
        );
      }
    }
  }

  void _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      final loc = Provider.of<AppLocalizations>(context, listen: false);
      final location = (_isRelatedToPrayerTimes &&
              _selectedCity != null &&
              _selectedCountry != null)
          ? '$_selectedCity,$_selectedCountry'
          : (!_isRelatedToPrayerTimes &&
                  _selectedCity != null &&
                  _selectedCountry != null)
              ? '$_selectedCity,$_selectedCountry'
              : null;

      String? recurrenceRule;
      if (_isRecurring) {
        RecurrenceProperties recurrence = RecurrenceProperties(
          startDate: _startTime!,
          recurrenceType: _recurrenceType,
          interval: _recurrenceInterval,
          recurrenceRange: _recurrenceRange,
        );

        // Wöchentlich
        if (_recurrenceType == RecurrenceType.weekly) {
          recurrence.weekDays.clear();
          if (_selectedWeekDays[0]) recurrence.weekDays.add(WeekDays.monday);
          if (_selectedWeekDays[1]) recurrence.weekDays.add(WeekDays.tuesday);
          if (_selectedWeekDays[2]) recurrence.weekDays.add(WeekDays.wednesday);
          if (_selectedWeekDays[3]) recurrence.weekDays.add(WeekDays.thursday);
          if (_selectedWeekDays[4]) recurrence.weekDays.add(WeekDays.friday);
          if (_selectedWeekDays[5]) recurrence.weekDays.add(WeekDays.saturday);
          if (_selectedWeekDays[6]) recurrence.weekDays.add(WeekDays.sunday);
        } else if (_recurrenceType == RecurrenceType.monthly) {
          recurrence.dayOfMonth = _startTime!.day;
        } else if (_recurrenceType == RecurrenceType.yearly) {
          recurrence.month = _startTime!.month;
          recurrence.dayOfMonth = _startTime!.day;
        }

        if (_recurrenceRange == RecurrenceRange.count) {
          _recurrenceCount = _recurrenceCount ?? 1;
          recurrence.recurrenceCount = _recurrenceCount!;
        } else if (_recurrenceRange == RecurrenceRange.endDate) {
          recurrence.endDate = _recurrenceEndDate;
        }

        recurrenceRule =
            SfCalendar.generateRRule(recurrence, _startTime!, _endTime!);
      }

      final appointment = AppointmentModel(
        id: widget.appointmentId,
        prayerTime: _isRelatedToPrayerTimes ? _selectedPrayerTime : null,
        timeRelation: _isRelatedToPrayerTimes ? _selectedTimeRelation : null,
        minutesBeforeAfter:
            _isRelatedToPrayerTimes ? _minutesBeforeAfter : null,
        isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
        duration: _isRelatedToPrayerTimes ? _duration : null,
        isAllDay: _isAllDay,
        startTime: _startTime,
        endTime: (_isRelatedToPrayerTimes && _duration != null)
            ? _startTime?.add(_duration!)
            : _endTime,
        subject: _titleController.text,
        notes: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        location: location,
        recurrenceRule: recurrenceRule,
        recurrenceExceptionDates:
            _exceptionDates.isNotEmpty ? _exceptionDates : null,
        color: _color,
        categoryId: _selectedCategory?.id,
      );

      if (widget.appointmentId == null) {
        await _appointmentRepo.insertAppointment(appointment);
      } else {
        await _appointmentRepo.updateAppointment(appointment);
      }

      Navigator.pop(context);
    }
  }

  /// Das Hinzufügen einer Exception
  void _addExceptionDate() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: loc.addExceptionDate,
    );
    if (selectedDate != null) {
      setState(() {
        _exceptionDates.add(selectedDate);
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<DateTime?> _pickDate(DateTime initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<DateTime?> _pickTime(DateTime initial) async {
    TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (timeOfDay != null) {
      return DateTime(
        initial.year,
        initial.month,
        initial.day,
        timeOfDay.hour,
        timeOfDay.minute,
        initial.second,
        initial.millisecond,
        initial.microsecond,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    final headlineStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointmentId == null
            ? loc.createAppointment
            : loc.editAppointment),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // Schnelleingabe + erweiterte Optionen
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================
              // Schnelleingabe
              // ====================
              Text(
                loc.general,
                style: headlineStyle,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '${loc.titleLabel} *'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? loc.titleLabel : null,
              ),
              const SizedBox(height: 12),

              // Start-/Endzeit
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked =
                            await _pickDate(_startTime ?? DateTime.now());
                        if (picked != null) {
                          final timePicked = _isAllDay
                              ? picked
                              : await _pickTime(picked) ?? picked;
                          setState(() {
                            _startTime = timePicked;
                            if (_isAllDay) {
                              _endTime =
                                  _startTime!.add(const Duration(hours: 1));
                            } else {
                              _endTime ??=
                                  _startTime!.add(const Duration(minutes: 30));
                            }
                          });
                        }
                      },
                      child: _buildDateTimeDisplay(
                        label: loc.startTime,
                        dateTime: _startTime,
                        isAllDay: _isAllDay,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: !_isAllDay
                        ? InkWell(
                            onTap: () async {
                              if (_startTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(loc.selectStartTime),
                                  ),
                                );
                                return;
                              }
                              final picked =
                                  await _pickDate(_endTime ?? _startTime!);
                              if (picked != null) {
                                final timePicked = await _pickTime(picked);
                                if (timePicked != null) {
                                  setState(() {
                                    _endTime = timePicked;
                                  });
                                }
                              }
                            },
                            child: _buildDateTimeDisplay(
                              label: loc.endTime,
                              dateTime: _endTime,
                              isAllDay: false,
                            ),
                          )
                        : Container(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Kategorie & Farbe
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      decoration:
                          const InputDecoration(labelText: 'Kategorie wählen'),
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

              // AllDay
              SwitchListTile(
                activeColor: Colors.green,
                activeTrackColor: Colors.greenAccent,
                title: Text(loc.allDay),
                subtitle: Text(loc.allDaySubtitle),
                value: _isAllDay,
                onChanged: !_isRelatedToPrayerTimes
                    ? (bool value) {
                        setState(() {
                          _isAllDay = value;
                          if (value && _startTime != null) {
                            _endTime =
                                _startTime!.add(const Duration(hours: 1));
                          }
                        });
                      }
                    : null,
              ),

              const SizedBox(height: 20),

              // Erweiterte Optionen
              FilledButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                child: Text(_showAdvancedOptions
                    ? 'Weniger Optionen'
                    : 'Erweiterte Optionen'),
              ),
              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showAdvancedOptions
                    ? Column(
                        key: const ValueKey('advancedOptions'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 1,
                            maxLines: 3,
                            decoration:
                                InputDecoration(labelText: loc.description),
                          ),
                          const SizedBox(height: 12),
                          Text(loc.prayerTimeSettings, style: headlineStyle),
                          SwitchListTile(
                            activeColor: Colors.green,
                            activeTrackColor: Colors.greenAccent,
                            title: Text(loc.relatedToPrayerTimes),
                            subtitle: Text(loc.relatedToPrayerTimesSubtitle),
                            value: _isRelatedToPrayerTimes,
                            onChanged: !_isAllDay
                                ? (bool value) {
                                    setState(() {
                                      _isRelatedToPrayerTimes = value;
                                      if (value && _startTime != null) {
                                        _endTime = _startTime!
                                            .add(const Duration(hours: 1));
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
                                final picked = await _pickDate(
                                    _startTime ?? DateTime.now());
                                if (picked != null) {
                                  setState(() {
                                    _startTime = DateTime(
                                        picked.year, picked.month, picked.day);
                                    _endTime = _startTime!
                                        .add(const Duration(hours: 1));
                                  });
                                }
                              },
                            ),
                            DropdownButtonFormField<PrayerTime>(
                              value: _selectedPrayerTime,
                              hint: Text(loc.selectPrayerTime),
                              decoration:
                                  InputDecoration(labelText: loc.prayerTime),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPrayerTime = value;
                                });
                              },
                              items: PrayerTime.values.map((prayerTime) {
                                return DropdownMenuItem<PrayerTime>(
                                  value: prayerTime,
                                  child: Text(
                                      prayerTime.toString().split('.').last),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TimeRelation>(
                              value: _selectedTimeRelation,
                              decoration:
                                  InputDecoration(labelText: loc.timeRelation),
                              items: TimeRelation.values.map((timeRelation) {
                                return DropdownMenuItem<TimeRelation>(
                                  value: timeRelation,
                                  child: Text(
                                      timeRelation.toString().split('.').last),
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
                              decoration: InputDecoration(
                                  labelText: loc.minutesBeforeAfter),
                              onChanged: (value) {
                                _minutesBeforeAfter = int.tryParse(value);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: _duration?.inMinutes.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: loc.durationMinutes),
                              onChanged: (value) {
                                _duration = Duration(
                                    minutes: int.tryParse(value) ?? 30);
                              },
                            ),
                            const SizedBox(height: 12),
                            // >>> BUG FIX: Fallback, falls _selectedCountry nicht existiert <<<
                            DropdownButtonFormField<String>(
                              value: _countryCityData.keys
                                      .contains(_selectedCountry)
                                  ? _selectedCountry
                                  : null,
                              hint: Text(loc.selectCountry),
                              decoration:
                                  InputDecoration(labelText: loc.country),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountry = value;
                                  _selectedCity = null;
                                });
                              },
                              items: _countryCityData.keys.map((country) {
                                return DropdownMenuItem<String>(
                                  value: country,
                                  child: Text(country),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedCountry != null)
                              DropdownButtonFormField<String>(
                                // Falls city nicht in der Liste, setze auf null
                                value: (_selectedCity != null &&
                                        _countryCityData[_selectedCountry]!
                                            .contains(_selectedCity))
                                    ? _selectedCity
                                    : null,
                                hint: Text(loc.selectCity),
                                decoration:
                                    InputDecoration(labelText: loc.city),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCity = value;
                                  });
                                },
                                items: _countryCityData[_selectedCountry]!
                                    .map((city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                              ),
                          ],
                          const SizedBox(height: 24),
                          Text(loc.recurrence, style: headlineStyle),
                          SwitchListTile(
                            activeColor: Colors.green,
                            activeTrackColor: Colors.greenAccent,
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
                              decoration: InputDecoration(
                                  labelText: loc.recurrenceType),
                              onChanged: (value) {
                                setState(() {
                                  _recurrenceType = value!;
                                  // Sobald wöchentlich gewählt,
                                  // Wochentag des Startdatums markieren
                                  if (_recurrenceType ==
                                      RecurrenceType.weekly) {
                                    _selectedWeekDays = List.filled(7, false);
                                    if (_startTime != null) {
                                      final index =
                                          (_startTime!.weekday - 1) % 7;
                                      _selectedWeekDays[index] = true;
                                    }
                                  }
                                });
                              },
                              items: RecurrenceType.values.map((type) {
                                return DropdownMenuItem<RecurrenceType>(
                                  value: type,
                                  child: Text(type.toString().split('.').last),
                                );
                              }).toList(),
                            ),
                            if (_recurrenceType == RecurrenceType.weekly) ...[
                              const SizedBox(height: 12),
                              Text(loc.recurrenceDays,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
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
                              decoration: InputDecoration(
                                  labelText: loc.recurrenceInterval),
                              onChanged: (value) {
                                _recurrenceInterval = int.tryParse(value) ?? 1;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<RecurrenceRange>(
                              value: _recurrenceRange,
                              decoration: InputDecoration(
                                  labelText: loc.recurrenceRange),
                              onChanged: (value) {
                                setState(() {
                                  _recurrenceRange = value!;
                                });
                              },
                              items: RecurrenceRange.values.map((range) {
                                return DropdownMenuItem<RecurrenceRange>(
                                  value: range,
                                  child: Text(range.toString().split('.').last),
                                );
                              }).toList(),
                            ),
                            if (_recurrenceRange == RecurrenceRange.count) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _recurrenceCount?.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: loc.recurrenceCount),
                                onChanged: (value) {
                                  _recurrenceCount = int.tryParse(value);
                                },
                              ),
                            ],
                            if (_recurrenceRange ==
                                RecurrenceRange.endDate) ...[
                              const SizedBox(height: 12),
                              ListTile(
                                title: Text(loc.recurrenceEndDate),
                                subtitle: Text(_recurrenceEndDate?.toString() ??
                                    loc.selectEndDate),
                                onTap: () async {
                                  DateTime? selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _recurrenceEndDate ?? DateTime.now(),
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
                                children: _exceptionDates
                                    .map((date) => ListTile(
                                          title: Text(date.toIso8601String()),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                _exceptionDates.remove(date);
                                              });
                                            },
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ],
                      )
                    : const SizedBox(),
              ),

              const SizedBox(height: 24),
              // Speichern / Löschen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _saveAppointment,
                    child: Text(loc.save),
                  ),
                  if (widget.appointmentId != null) ...[
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
      ),
    );
  }

  // Hilfswidget, um Datum/Zeit kompakt anzuzeigen
  Widget _buildDateTimeDisplay({
    required String label,
    required DateTime? dateTime,
    required bool isAllDay,
  }) {
    final text = dateTime != null
        ? isAllDay
            ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
            : '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}'
        : '---';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context) {
    Color tempColor = _color;
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.select),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _color,
              onColorChanged: (Color color) {
                tempColor = color;
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
      },
    );
  }
}
