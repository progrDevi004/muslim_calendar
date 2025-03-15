import 'package:flutter/material.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

class AddAppointmentFAB extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onAppointmentAdded;
  final Color logoColor;
  final AppLocalizations localizations;

  const AddAppointmentFAB({
    Key? key,
    required this.selectedDate,
    required this.onAppointmentAdded,
    required this.logoColor,
    required this.localizations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: localizations.addNewAppointment,
      backgroundColor: logoColor,
      foregroundColor: Colors.white,
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AppointmentCreationPage(
              selectedDate: selectedDate,
            ),
          ),
        );
        if (result == true) {
          onAppointmentAdded();
        }
      },
      child: const Icon(Icons.add),
    );
  }
}
