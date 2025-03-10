import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/models/selected_calendar.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';

class CalendarSelectionDialog extends StatefulWidget {
  final List<SelectedCalendar> calendars;

  const CalendarSelectionDialog({
    Key? key,
    required this.calendars,
  }) : super(key: key);

  @override
  State<CalendarSelectionDialog> createState() =>
      _CalendarSelectionDialogState();
}

class _CalendarSelectionDialogState extends State<CalendarSelectionDialog> {
  late List<SelectedCalendar> _calendars;

  @override
  void initState() {
    super.initState();
    _calendars = List.from(widget.calendars);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return AlertDialog(
      title: Text(loc.selectCalendars),
      content: SizedBox(
        width: double.maxFinite,
        child: _calendars.isEmpty
            ? Center(child: Text(loc.noCalendarsFound))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _calendars.length,
                itemBuilder: (context, index) {
                  final calendar = _calendars[index];
                  return CheckboxListTile(
                    title: Text(calendar.title),
                    value: calendar.isSelected,
                    onChanged: (value) {
                      setState(() {
                        _calendars[index] =
                            calendar.copyWith(isSelected: value ?? false);
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () async {
            // Mindestens ein Kalender muss ausgewählt sein
            if (_calendars.any((calendar) => calendar.isSelected)) {
              Navigator.of(context).pop(_calendars);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.selectAtLeastOneCalendar)),
              );
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}

// Funktion zum Anzeigen des Dialogs
Future<List<SelectedCalendar>?> showCalendarSelectionDialog(
    BuildContext context, List<SelectedCalendar> calendars) async {
  return await showDialog<List<SelectedCalendar>>(
    context: context,
    builder: (context) => CalendarSelectionDialog(calendars: calendars),
  );
}
