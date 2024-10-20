import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class AppointmentCreationPage extends StatefulWidget {
  @override
  _AppointmentCreationPageState createState() => _AppointmentCreationPageState();
}

class _AppointmentCreationPageState extends State<AppointmentCreationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(Duration(hours: 1));
  DateTime? _repeatEndDate;
  DateTime? _prayerDate;
  bool _isAllDay = false;
  bool _isRecurring = false;
  bool _isRelatedToPrayerTimes = false;
  int _repeatInterval = 1;
  RepeatFrequency _repeatFrequency = RepeatFrequency.daily;
  String _subject = '';
  String _notes = '';
  String _location = '';
  Color _color = Colors.lightBlue;
  PrayerTime? _prayerTime;
  TimeRelation _timeRelation = TimeRelation.before;
  int _offsetMinutes = 0;
  int _durationMinutes = 60; // Yeni özellik: Süre

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_isRelatedToPrayerTimes && _prayerTime != null && _prayerDate != null) {
        DateTime prayerDateTime = _prayerDate!;
        Duration offset = Duration(minutes: _offsetMinutes);
        Duration duration = Duration(minutes: _durationMinutes);
        _startTime = _timeRelation == TimeRelation.before
            ? prayerDateTime.subtract(offset)
            : prayerDateTime;
        _endTime = _timeRelation == TimeRelation.before
            ? prayerDateTime.subtract(offset).add(duration)
            : prayerDateTime.add(offset).add(duration);
      }

      final appointment = Appointment(
        startTime: _startTime,
        endTime: _endTime,
        isAllDay: _isAllDay,
        subject: _subject,
        notes: _notes,
        location: _location,
        color: _color,
        isRecurring: _isRecurring,
        isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
        repeatInterval: _isRecurring ? _repeatInterval : null,
        repeatFrequency: _isRecurring ? _repeatFrequency : null,
        repeatEndDate: _isRecurring ? _repeatEndDate : null,
        prayerTime: _prayerTime,
        timeRelation: _timeRelation,
        offsetDuration: Duration(minutes: _offsetMinutes),
        duration: Duration(minutes: _durationMinutes),
        prayerDate: _prayerDate,
      );
      _saveAppointment(appointment);
      print('Appointment Created: $appointment');
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveAppointment(Appointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> appointmentList = prefs.getStringList('appointments') ?? [];
    appointmentList.add(jsonEncode({
      'startTime': appointment.startTime.toIso8601String(),
      'endTime': appointment.endTime.toIso8601String(),
      'isAllDay': appointment.isAllDay,
      'subject': appointment.subject,
      'notes': appointment.notes,
      'location': appointment.location,
      'color': appointment.color.value.toString(),
      'isRecurring': appointment.isRecurring,
      'isRelatedToPrayerTimes': appointment.isRelatedToPrayerTimes,
      'repeatInterval': appointment.repeatInterval,
      'repeatFrequency': appointment.repeatFrequency?.index,
      'repeatEndDate': appointment.repeatEndDate?.toIso8601String(),
      'prayerTime': appointment.prayerTime?.index,
      'timeRelation': appointment.timeRelation?.index,
      'offsetDuration': appointment.offsetDuration?.inMinutes,
      'duration': appointment.duration?.inMinutes,
      'prayerDate': appointment.prayerDate?.toIso8601String(),
    }));
    await prefs.setStringList('appointments', appointmentList);
  }

  Future<void> _selectPrayerDate(BuildContext context) async {
    DateTime initialDate = _prayerDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _prayerDate = pickedDate;
      });
    }
  }
  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    DateTime initialDate = isStart ? _startTime : _endTime;
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _selectRepeatEndDate(BuildContext context) async {
    DateTime initialDate = _repeatEndDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _repeatEndDate = pickedDate;
      });
    }
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
        title: Text('Create Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Subject'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                  onSaved: (value) => _subject = value ?? '',
                ),
                SwitchListTile(
                  title: Text('All Day'),
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() {
                      _isAllDay = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('Recurring'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                ),
                if (_isRecurring) ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Repeat Interval'),
                    keyboardType: TextInputType.number,
                    initialValue: _repeatInterval.toString(),
                    onSaved: (value) => _repeatInterval = int.parse(value ?? '1'),
                  ),
                  DropdownButtonFormField<RepeatFrequency>(
                    decoration: InputDecoration(labelText: 'Repeat Frequency'),
                    value: _repeatFrequency,
                    items: RepeatFrequency.values.map((RepeatFrequency frequency) {
                      return DropdownMenuItem<RepeatFrequency>(
                        value: frequency,
                        child: Text(frequency.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _repeatFrequency = value!;
                      });
                    },
                  ),
                  ListTile(
                    title: Text('Repeat End Date: ${_repeatEndDate?.toString() ?? "Not Set"}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectRepeatEndDate(context),
                  ),
                ],
                SwitchListTile(
                  title: Text('Related to Prayer Times'),
                  value: _isRelatedToPrayerTimes,
                  onChanged: (value) {
                    setState(() {
                      _isRelatedToPrayerTimes = value;
                    });
                  },
                ),
                if (_isRelatedToPrayerTimes) ...[
                  ListTile(
                    title: Text('Prayer Date: ${_prayerDate?.toString() ?? "Not Set"}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectPrayerDate(context),
                  ),
                  DropdownButtonFormField<PrayerTime>(
                    decoration: InputDecoration(labelText: 'Prayer Time'),
                    value: _prayerTime,
                    items: PrayerTime.values.map((PrayerTime prayer) {
                      return DropdownMenuItem<PrayerTime>(
                        value: prayer,
                        child: Text(prayer.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _prayerTime = value!;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TimeRelation>(
                          decoration: InputDecoration(labelText: 'Relation'),
                          value: _timeRelation,
                          items: TimeRelation.values.map((TimeRelation relation) {
                            return DropdownMenuItem<TimeRelation>(
                              value: relation,
                              child: Text(relation.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _timeRelation = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Offset (minutes)'),
                          keyboardType: TextInputType.number,
                          initialValue: _offsetMinutes.toString(),
                          onChanged: (value) {
                            setState(() {
                              _offsetMinutes = int.parse(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    initialValue: _durationMinutes.toString(),
                    onChanged: (value) {
                                            setState(() {
                        _durationMinutes = int.parse(value);
                      });
                    },
                  ),
                ],
                if (!_isRelatedToPrayerTimes) ...[
                  ListTile(
                    title: Text('Start Time: ${_startTime.toString()}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, true),
                  ),
                  ListTile(
                    title: Text('End Time: ${_endTime.toString()}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context, false),
                  ),
                ],
                ListTile(
                  title: Text('Color:'),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    color: _color,
                  ),
                  onTap: () => _pickColor(context),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Notes'),
                  onSaved: (value) => _notes = value ?? '',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Location'),
                  onSaved: (value) => _location = value ?? '',
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Create Appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: AppointmentCreationPage(),
));
                       