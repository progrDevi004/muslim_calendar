// lib/ui/pages/appointment_details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailsPage({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  AppointmentModel? _appointment;
  bool _isLoading = true;

  // Neu: für Zeitformat
  bool _use24hFormat = false;

  @override
  void initState() {
    super.initState();
    _loadUserPrefs().then((_) {
      _loadAppointment();
    });
  }

  /// Zeitformat aus SharedPreferences laden
  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _use24hFormat = prefs.getBool('use24hFormat') ?? false;
  }

  /// Hilfsfunktion, um das Datum/Uhrzeit im richtigen Format zu zeigen
  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    // Datum und Uhrzeit zusammen
    final datePattern = 'yyyy-MM-dd'; // z.B. "2024-12-24"
    final timePattern = _use24hFormat ? 'HH:mm' : 'h:mm a';

    final dateStr = DateFormat(datePattern).format(dt);
    final timeStr = DateFormat(timePattern).format(dt);

    return '$dateStr, $timeStr';
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final appt = await _appointmentRepo.getAppointment(widget.appointmentId);
      setState(() {
        _appointment = appt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment: $e')),
      );
    }
  }

  /// Termin löschen
  Future<void> _deleteAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(loc.deleteAppointmentTitle),
              content: Text(loc.deleteAppointmentConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(loc.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(loc.delete),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete && _appointment?.id != null) {
      try {
        // Notification ggf. stornieren
        await NotificationService().cancelNotification(_appointment!.id!);
        await _appointmentRepo.deleteAppointment(_appointment!.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted successfully.')),
        );
        // Nach dem Löschen zurück
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting appointment.')),
        );
      }
    }
  }

  /// Termin bearbeiten
  Future<void> _editAppointment() async {
    if (_appointment?.id == null) return;

    // Navigiert zur AppointmentCreationPage mit der vorhandenen ID
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppointmentCreationPage(
          appointmentId: _appointment!.id,
        ),
      ),
    );

    // Nach Rückkehr: Reload, damit Änderungen sichtbar sind
    _loadAppointment();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.editAppointment), // oder "Termindetails"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointment == null
              ? Center(
                  child: Text(
                    'Appointment not found.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDetailsContent(loc),
                ),
    );
  }

  Widget _buildDetailsContent(AppLocalizations loc) {
    // Wir packen die Infos in ein Card-Layout, damit es ansprechender aussieht
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Überschrift
        Text(
          _appointment!.subject,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Beschreibung
        if ((_appointment!.notes?.isNotEmpty ?? false))
          Card(
            color: Colors.grey.shade50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _appointment!.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Start/End Times
        Card(
          color: Colors.grey.shade50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${loc.startTime}: ${_formatDateTime(_appointment!.startTime)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${loc.endTime}: ${_formatDateTime(_appointment!.endTime)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Standort, falls vorhanden
        if (_appointment!.location != null &&
            _appointment!.location!.isNotEmpty)
          Card(
            color: Colors.grey.shade50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc.location}: ${_appointment!.location!}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Gebetszeiten-Info + Ganztägig
        Card(
          color: Colors.grey.shade50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                if (_appointment!.isAllDay) ...[
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    loc.allDay,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                ],
                if (_appointment!.isRelatedToPrayerTimes) ...[
                  const Icon(Icons.star, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    loc.relatedToPrayerTimes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Buttons (Löschen & Bearbeiten)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _deleteAppointment,
              icon: const Icon(Icons.delete),
              label: Text(loc.delete),
            ),
            FilledButton.icon(
              onPressed: _editAppointment,
              icon: const Icon(Icons.edit),
              label: Text(loc.editAppointment),
            ),
          ],
        ),
      ],
    );
  }
}
