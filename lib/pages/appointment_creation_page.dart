import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/prayer_time_appointment.dart';
import '../database/database_helper.dart';

class AppointmentCreationPage extends StatefulWidget {
  final PrayerTimeAppointment? appointment;

  AppointmentCreationPage({this.appointment});

  @override
  _AppointmentCreationPageState createState() => _AppointmentCreationPageState();
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
    _titleController = TextEditingController(text: widget.appointment?.subject ?? '');
    _descriptionController = TextEditingController(text: widget.appointment?.notes ?? '');
    _isAllDay = widget.appointment?.isAllDay ?? false;
    _isRelatedToPrayerTimes = widget.appointment?.isRelatedToPrayerTimes ?? false;
    _selectedPrayerTime = widget.appointment?.prayerTime;
    _selectedTimeRelation = widget.appointment?.timeRelation;
    _minutesBeforeAfter = widget.appointment?.minutesBeforeAfter;
    _duration = widget.appointment?.duration ?? Duration(minutes: 30);
    _startTime = widget.appointment?.startTime ?? DateTime.now();
    _endTime = widget.appointment?.endTime ?? DateTime.now().add(Duration(minutes: 30));
    _color = widget.appointment?.color ?? Colors.blue;
    _loadCountryCityData();
  }

  Future<void> _loadCountryCityData() async {
    final String response = await rootBundle.loadString('assets/country_city_data.json');
    final Map<String, dynamic> data = json.decode(response);
    setState(() {
      _countryCityData = data.map((key, value) => MapEntry<String, List<String>>(key, List<String>.from(value)));
    });
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _color,
              onColorChanged: (Color color) {
                setState(() {
                  _color = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? 'Create Appointment' : 'Edit Appointment'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                SwitchListTile(
                  title: Text('All Day'),
                  value: _isAllDay,
                  onChanged: !_isRelatedToPrayerTimes ? (bool value) {
                    setState(() {
                      _isAllDay = value;
                      if (value) {
                        _endTime = _startTime!.add(Duration(hours: 1));
                      }
                    });
                  } : null,
                ),
                SwitchListTile(
                  title: Text('Related to Prayer Times'),
                  value: _isRelatedToPrayerTimes,
                  onChanged: !_isAllDay ? (bool value) {
                    setState(() {
                      _isRelatedToPrayerTimes = value;
                      if (value) {
                        _endTime = _startTime!.add(Duration(hours: 1));
                      }
                    });
                  } : null,
                ),
                if (_isRelatedToPrayerTimes) ...[
                  ListTile(
                    title: Text('Select Date'),
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
                          _startTime = DateTime(picked.year, picked.month, picked.day);
                          _endTime = _startTime!.add(Duration(hours: 1));
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<PrayerTime>(
                    value: _selectedPrayerTime,
                    hint: Text('Select Prayer Time'),
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
                  DropdownButtonFormField<TimeRelation>(
                    items: TimeRelation.values.map((timeRelation) {
                      return DropdownMenuItem<TimeRelation>(
                        value: timeRelation,
                        child: Text(timeRelation.toString().split('.').last),
                      );
                    },).toList(), 
                    onChanged: (value) {
                    setState(() {
                      _selectedTimeRelation = value;
                    });
                  },
                  ),
                  TextFormField(
                    initialValue: _minutesBeforeAfter?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Minutes Before/After'),
                    onChanged: (value) {
                      _minutesBeforeAfter = int.tryParse(value);
                    },
                  ),
                  TextFormField(
                    initialValue: _duration?.inMinutes.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Duration (minutes)'),
                    onChanged: (value) {
                      _duration = Duration(minutes: int.tryParse(value) ?? 30);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    hint: Text('Select Country'),
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
                  if (_selectedCountry != null)
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: Text('Select City'),
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
                  ListTile(
                    title: Text('Start Time'),
                    subtitle: Text(_startTime != null ? _startTime.toString() : 'Select Start Time'),
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
                            initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
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
                            _endTime = _startTime!.add(Duration(hours: 1));
                          }
                        });
                      }
                    },
                  ),
                  if (!_isAllDay)
                    ListTile(
                      title: Text('End Time'),
                      subtitle: Text(_endTime != null ? _endTime.toString() : 'Select End Time'),
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
                            initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
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
                SwitchListTile(
                  title: Text('Recurring Event'),
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
                    decoration: InputDecoration(labelText: 'Recurrence Type'),
                  ),
                  if (_recurrenceType == RecurrenceType.weekly)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recurrence Days', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            children: List.generate(7, (index) {
                              return FilterChip(
                                label: Text(['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][index]),
                                selected: _selectedWeekDays[index],
                                shape: StadiumBorder(),
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedWeekDays[index] = selected;
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  TextFormField(
                    initialValue: _recurrenceInterval.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Recurrence Interval'),
                    onChanged: (value) {
                      _recurrenceInterval = int.tryParse(value) ?? 1;
                    },
                  ),
                  DropdownButtonFormField<RecurrenceRange>(
                    value: _recurrenceRange,
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
                    decoration: InputDecoration(labelText: 'Recurrence Range'),
                  ),
                  if (_recurrenceRange == RecurrenceRange.count)
                    TextFormField(
                      initialValue: _recurrenceCount?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Recurrence Count'),
                      onChanged: (value) {
                        _recurrenceCount = int.tryParse(value);
                      },
                    ),
                  if (_recurrenceRange == RecurrenceRange.endDate)
                    ListTile(
                      title: Text('Recurrence End Date'),
                      subtitle: Text(_recurrenceEndDate?.toString() ?? 'Select End Date'),
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
                  ElevatedButton(
                    onPressed: _addExceptionDate,
                    child: Text('Add Exception Date'),
                  ),
                  if (_exceptionDates.isNotEmpty)
                    Column(
                      children: _exceptionDates.map((date) => ListTile(
                        title: Text(date.toString()),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _exceptionDates.remove(date);
                            });
                          },
                        ),
                      )).toList(),
                    ),
                ],
                ListTile(
                  title: Text('Appointment Color'),
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
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _saveAppointment,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return days.asMap().entries
        .where((entry) => _selectedWeekDays[entry.key])
        .map((entry) => entry.value)
        .join(',');
  }
  void _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      final location = _isRelatedToPrayerTimes && _selectedCity != null && _selectedCountry != null
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
                case 'MO': return WeekDays.monday;
                case 'TU': return WeekDays.tuesday;
                case 'WE': return WeekDays.wednesday;
                case 'TH': return WeekDays.thursday;
                case 'FR': return WeekDays.friday;
                case 'SA': return WeekDays.saturday;
                case 'SU': return WeekDays.sunday;
                default: throw Exception('Invalid day');
              }
            }).toList();
          }
        }
        else if (_recurrenceType == RecurrenceType.monthly) {
          recurrence.dayOfMonth = _startTime!.day;
        } else if (_recurrenceType == RecurrenceType.daily) {
          // Günlük tekrar için özel bir ayar gerekmeyebilir,
          // çünkü RecurrenceType.daily zaten günlük tekrarı ifade eder.
          // Ancak gerekirse burada ek ayarlar yapılabilir.
        } else if (_recurrenceType == RecurrenceType.yearly) {
          // Yıllık tekrar için ayarlar
          recurrence.month = _startTime!.month;
          recurrence.dayOfMonth = _startTime!.day;
        }
        if (_recurrenceRange == RecurrenceRange.count) {
          recurrence.recurrenceCount = _recurrenceCount! * _recurrenceInterval;
        } else if (_recurrenceRange == RecurrenceRange.endDate) {
          recurrence.endDate = _recurrenceEndDate;
        }
        recurrenceRule = SfCalendar.generateRRule(recurrence, _startTime!, _endTime!);
      }

      final appointment = PrayerTimeAppointment(
        prayerTime: _isRelatedToPrayerTimes ? _selectedPrayerTime : null,
        timeRelation: _isRelatedToPrayerTimes ? _selectedTimeRelation : null,
        minutesBeforeAfter: _isRelatedToPrayerTimes ? _minutesBeforeAfter : null,
        isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
        duration: _isRelatedToPrayerTimes ? _duration : null,
        isAllDay: _isAllDay,
        startTime: _isRelatedToPrayerTimes ? _startTime : _startTime,
        endTime: _isRelatedToPrayerTimes ? _startTime?.add(_duration!) : _endTime,
        subject: _titleController.text,
        notes: _descriptionController.text,
        location: location,
        recurrenceRule: recurrenceRule,
        recurrenceExceptionDates: _exceptionDates.isNotEmpty ? _exceptionDates : null,
        color: _color,
      );

      final db = DatabaseHelper();
      if (widget.appointment == null) {
        await db.insertAppointment(appointment);
      } else {
        appointment.id = widget.appointment!.id;
        await db.updateAppointment(appointment);
      }

      Navigator.pop(context);
    }
  }
}