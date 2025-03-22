import 'package:flutter/material.dart';
import 'package:Taqvimi/ui/pages/appointment_creation_page.dart';
import 'package:Taqvimi/localization/app_localizations.dart';

class AddAppointmentFAB extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onAppointmentAdded;
  final Color logoColor;
  final AppLocalizations localizations;

  const AddAppointmentFAB({
    super.key,
    required this.selectedDate,
    required this.onAppointmentAdded,
    required this.logoColor,
    required this.localizations,
  });

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
