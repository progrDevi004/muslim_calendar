import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/prayer_time_appointment.dart';
import '../database/database_helper.dart';

class AppointmentCreationPage extends StatefulWidget {
  final int? appointmentId;

  AppointmentCreationPage({this.appointmentId});

  @override
  _AppointmentCreationPageState createState() =>
      _AppointmentCreationPageState();
}

class _AppointmentCreationPageState extends State<AppointmentCreationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isAllDay = false;
  bool _isRelatedToPrayerTimes = false;
  PrayerTime? _selectedPrayerTime;
  TimeRelation? _selectedTimeRelation;
  int? _minutesBeforeAfter;
  Duration? _duration;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedCountry;
  String? _selectedCity;
  Map<String, List<String>> _countryCityData = {};
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  RecurrenceRange _recurrenceRange = RecurrenceRange.noEndDate;
  int? _recurrenceCount;
  DateTime? _recurrenceEndDate;
  List<DateTime> _exceptionDates = [];
  Color _color = Colors.blue;
  List<bool> _selectedWeekDays = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadCountryCityData();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId != null) {
      final db = DatabaseHelper();
      try {
        final appointment = await db.getAppointment(widget.appointmentId!);
        if (appointment != null) {
          setState(() {
            _titleController.text = appointment.subject;
            _descriptionController.text = appointment.notes ?? '';
            _isAllDay = appointment.isAllDay;
            _isRelatedToPrayerTimes = appointment.isRelatedToPrayerTimes!;
            _selectedPrayerTime = appointment.prayerTime;
            _selectedTimeRelation = appointment.timeRelation;
            _minutesBeforeAfter = appointment.minutesBeforeAfter;
            _duration = appointment.duration ?? const Duration(minutes: 30);
            _startTime = appointment.startTime;
            _endTime = appointment.endTime;
            _color = appointment.color;

            if (appointment.location != null) {
              final locationParts = appointment.location!.split(',');
              if (locationParts.length == 2) {
                _selectedCity = locationParts[0].trim();
                _selectedCountry = locationParts[1].trim();
              }
            }

            if (appointment.recurrenceRule != null) {
              _isRecurring = true;
              final recurrenceProperties = SfCalendar.parseRRule(
                  appointment.recurrenceRule!, appointment.startTime);

              _recurrenceType = recurrenceProperties.recurrenceType;
              _recurrenceInterval = recurrenceProperties.interval;
              _recurrenceRange = recurrenceProperties.recurrenceRange;
              _recurrenceCount = recurrenceProperties.recurrenceCount;
              _recurrenceEndDate = recurrenceProperties.endDate;

              if (_recurrenceType == RecurrenceType.weekly) {
                _selectedWeekDays = List.filled(7, false);
                recurrenceProperties.weekDays.forEach((weekDay) {
                  _selectedWeekDays[(weekDay.index + 6) % 7] = true;
                });
              }
            }

            _exceptionDates = appointment.recurrenceExceptionDates ?? [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Appointment not found. Creating a new one.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointment: $e')),
        );
      }
    } else {
      setState(() {
        _startTime = DateTime.now();
        _endTime = _startTime!.add(const Duration(minutes: 30));
        _duration = const Duration(minutes: 30);
      });
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

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _color;
        return AlertDialog(
          title: const Text('Pick a color!'),
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Select'),
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

  void _addExceptionDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _exceptionDates.add(selectedDate);
      });
    }
  }

  String _getBYDAYString() {
    List<String> days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return days
        .asMap()
        .entries
        .where((entry) => _selectedWeekDays[entry.key])
        .map((entry) => entry.value)
        .join(',');
  }

  Future<void> _deleteAppointment() async {
    if (widget.appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No appointment to delete.')),
      );
      return;
    }

    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Appointment'),
              content: const Text(
                  'Are you sure you want to delete this appointment?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                FilledButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        final db = DatabaseHelper();
        await db.deleteAppointment(widget.appointmentId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted successfully.')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error deleting appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting appointment.')),
        );
      }
    }
  }

  void _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      final location = _isRelatedToPrayerTimes &&
              _selectedCity != null &&
              _selectedCountry != null
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

        if (_recurrenceType == RecurrenceType.weekly) {
          String byday = _getBYDAYString();
          if (byday.isNotEmpty) {
            recurrence.weekDays = byday.split(',').map((day) {
              switch (day) {
                case 'MO':
                  return WeekDays.monday;
                case 'TU':
                  return WeekDays.tuesday;
                case 'WE':
                  return WeekDays.wednesday;
                case 'TH':
                  return WeekDays.thursday;
                case 'FR':
                  return WeekDays.friday;
                case 'SA':
                  return WeekDays.saturday;
                case 'SU':
                  return WeekDays.sunday;
                default:
                  throw Exception('Invalid day');
              }
            }).toList();
          }
        } else if (_recurrenceType == RecurrenceType.monthly) {
          recurrence.dayOfMonth = _startTime!.day;
        } else if (_recurrenceType == RecurrenceType.yearly) {
          recurrence.month = _startTime!.month;
          recurrence.dayOfMonth = _startTime!.day;
        }

        if (_recurrenceRange == RecurrenceRange.count) {
          recurrence.recurrenceCount = _recurrenceCount!;
        } else if (_recurrenceRange == RecurrenceRange.endDate) {
          recurrence.endDate = _recurrenceEndDate;
        }
        recurrenceRule =
            SfCalendar.generateRRule(recurrence, _startTime!, _endTime!);
      }

      final appointment = PrayerTimeAppointment(
        id: widget.appointmentId,
        prayerTime: _isRelatedToPrayerTimes ? _selectedPrayerTime : null,
        timeRelation: _isRelatedToPrayerTimes ? _selectedTimeRelation : null,
        minutesBeforeAfter:
            _isRelatedToPrayerTimes ? _minutesBeforeAfter : null,
        isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
        duration: _isRelatedToPrayerTimes ? _duration : null,
        isAllDay: _isAllDay,
        startTime: _isRelatedToPrayerTimes ? _startTime : _startTime,
        endTime:
            _isRelatedToPrayerTimes ? _startTime?.add(_duration!) : _endTime,
        subject: _titleController.text,
        notes: _descriptionController.text,
        location: location,
        recurrenceRule: recurrenceRule,
        recurrenceExceptionDates:
            _exceptionDates.isNotEmpty ? _exceptionDates : null,
        color: _color,
      );
      final db = DatabaseHelper();
      if (widget.appointmentId == null) {
        await db.insertAppointment(appointment);
      } else {
        await db.updateAppointment(appointment);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointmentId == null
            ? 'Create Appointment'
            : 'Edit Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General', style: headlineStyle),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('All Day'),
                subtitle: const Text('Event lasts the whole day'),
                value: _isAllDay,
                onChanged: !_isRelatedToPrayerTimes
                    ? (bool value) {
                        setState(() {
                          _isAllDay = value;
                          if (value) {
                            _endTime =
                                _startTime!.add(const Duration(hours: 1));
                          }
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 24),
              Text('Prayer Time Settings', style: headlineStyle),
              SwitchListTile(
                title: const Text('Related to Prayer Times'),
                subtitle:
                    const Text('Event time depends on daily prayer times'),
                value: _isRelatedToPrayerTimes,
                onChanged: !_isAllDay
                    ? (bool value) {
                        setState(() {
                          _isRelatedToPrayerTimes = value;
                          if (value) {
                            _endTime =
                                _startTime!.add(const Duration(hours: 1));
                          }
                        });
                      }
                    : null,
              ),
              if (_isRelatedToPrayerTimes) ...[
                ListTile(
                  title: const Text('Select Date'),
                  subtitle: Text(_startTime != null
                      ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year}'
                      : 'Select a date'),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startTime ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != _startTime) {
                      setState(() {
                        _startTime =
                            DateTime(picked.year, picked.month, picked.day);
                        _endTime = _startTime!.add(const Duration(hours: 1));
                      });
                    }
                  },
                ),
                DropdownButtonFormField<PrayerTime>(
                  value: _selectedPrayerTime,
                  hint: const Text('Select Prayer Time'),
                  decoration: const InputDecoration(labelText: 'Prayer Time'),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrayerTime = value;
                    });
                  },
                  items: PrayerTime.values.map((prayerTime) {
                    return DropdownMenuItem<PrayerTime>(
                      value: prayerTime,
                      child: Text(prayerTime.toString().split('.').last),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TimeRelation>(
                  value: _selectedTimeRelation,
                  decoration: const InputDecoration(labelText: 'Time Relation'),
                  items: TimeRelation.values.map((timeRelation) {
                    return DropdownMenuItem<TimeRelation>(
                      value: timeRelation,
                      child: Text(timeRelation.toString().split('.').last),
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
                  decoration:
                      const InputDecoration(labelText: 'Minutes Before/After'),
                  onChanged: (value) {
                    _minutesBeforeAfter = int.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _duration?.inMinutes.toString(),
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                  onChanged: (value) {
                    _duration = Duration(minutes: int.tryParse(value) ?? 30);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  hint: const Text('Select Country'),
                  decoration: const InputDecoration(labelText: 'Country'),
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
                    value: _selectedCity,
                    hint: const Text('Select City'),
                    decoration: const InputDecoration(labelText: 'City'),
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
              ] else ...[
                const SizedBox(height: 24),
                Text('Time Settings', style: headlineStyle),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime != null
                      ? _startTime.toString()
                      : 'Select Start Time'),
                  onTap: () async {
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _startTime ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      if (!_isAllDay) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _startTime ?? DateTime.now()),
                        );
                        if (selectedTime != null) {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                        }
                      }
                      setState(() {
                        _startTime = selectedDate;
                        if (_isAllDay) {
                          _endTime = _startTime!.add(const Duration(hours: 1));
                        }
                      });
                    }
                  },
                ),
                if (!_isAllDay)
                  ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime != null
                        ? _endTime.toString()
                        : 'Select End Time'),
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _endTime ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _endTime ?? DateTime.now()),
                        );
                        if (selectedTime != null) {
                          setState(() {
                            _endTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
              ],
              const SizedBox(height: 24),
              Text('Recurrence', style: headlineStyle),
              SwitchListTile(
                title: const Text('Recurring Event'),
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
                  decoration:
                      const InputDecoration(labelText: 'Recurrence Type'),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceType = value!;
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
                  Text('Recurrence Days',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(7, (index) {
                      return FilterChip(
                        label: Text([
                          'MON',
                          'TUE',
                          'WED',
                          'THU',
                          'FRI',
                          'SAT',
                          'SUN'
                        ][index]),
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
                  decoration:
                      const InputDecoration(labelText: 'Recurrence Interval'),
                  onChanged: (value) {
                    _recurrenceInterval = int.tryParse(value) ?? 1;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecurrenceRange>(
                  value: _recurrenceRange,
                  decoration:
                      const InputDecoration(labelText: 'Recurrence Range'),
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
                    decoration:
                        const InputDecoration(labelText: 'Recurrence Count'),
                    onChanged: (value) {
                      _recurrenceCount = int.tryParse(value);
                    },
                  ),
                ],
                if (_recurrenceRange == RecurrenceRange.endDate) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Recurrence End Date'),
                    subtitle: Text(
                        _recurrenceEndDate?.toString() ?? 'Select End Date'),
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
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
                  child: const Text('Add Exception Date'),
                ),
                if (_exceptionDates.isNotEmpty)
                  Column(
                    children: _exceptionDates
                        .map((date) => ListTile(
                              title: Text(date.toString()),
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
              const SizedBox(height: 24),
              Text('Color', style: headlineStyle),
              ListTile(
                title: const Text('Appointment Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => _pickColor(context),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _saveAppointment,
                    child: const Text('Save'),
                  ),
                  if (widget.appointmentId != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _deleteAppointment,
                      child: const Text('Delete'),
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
}
