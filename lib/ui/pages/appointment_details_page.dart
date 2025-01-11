// lib/ui/pages/appointment_details_page.dart

import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NEU: Für berechnete Start-/Endzeiten
import 'package:muslim_calendar/data/services/prayer_time_service.dart';
import 'package:muslim_calendar/data/repositories/prayer_time_repository.dart';

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

  // NEU: Für berechnete Zeiten
  final PrayerTimeService _prayerTimeService =
      PrayerTimeService(PrayerTimeRepository());
  DateTime? _computedStartTime;
  DateTime? _computedEndTime;

  bool get _isIos => Platform.isIOS;

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
    final datePattern = 'yyyy-MM-dd';
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
      if (appt != null) {
        // NEU: Computed Times
        final baseDate = appt.startTime != null
            ? DateTime(
                appt.startTime!.year,
                appt.startTime!.month,
                appt.startTime!.day,
              )
            : DateTime.now();

        final start = await _prayerTimeService.getCalculatedStartTime(
          appt,
          baseDate,
        );
        final end = await _prayerTimeService.getCalculatedEndTime(
          appt,
          baseDate,
        );

        setState(() {
          _appointment = appt;
          _computedStartTime = start ?? appt.startTime;
          _computedEndTime = end ?? appt.endTime;
          _isLoading = false;
        });
      } else {
        setState(() {
          _appointment = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment: $e')),
      );
    }
  }

  /// Termin löschen (angepasst!)
  Future<void> _deleteAppointment() async {
    final loc = Provider.of<AppLocalizations>(context, listen: false);

    bool confirmDelete = await _showAdaptiveDialog(
      context: context,
      title: loc.deleteAppointmentTitle,
      content: loc.deleteAppointmentConfirmation,
      confirmText: loc.delete,
      cancelText: loc.cancel,
    );

    if (confirmDelete && _appointment?.id != null) {
      try {
        // 1) Zuerst: Datenbank-Löschen
        await _appointmentRepo.deleteAppointment(_appointment!.id!);

        // 2) Dann Notification stornieren (falls das fehlschlägt,
        //    NICHT den DB-Löschvorgang "zurückrollen"):
        try {
          await NotificationService().cancelNotification(_appointment!.id!);
        } catch (notifErr) {
          // Nur loggen oder ignorieren
          debugPrint(
              'iOS-Knackpunkt: Notification-Cancel schlug fehl: $notifErr');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.appointmentDeletedSuccessfully)),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorDeletingAppointment)),
        );
      }
    }
  }

  /// Termin bearbeiten
  Future<void> _editAppointment() async {
    if (_appointment?.id == null) return;

    await Navigator.of(context).push(
      _isIos
          ? CupertinoPageRoute(
              builder: (context) => AppointmentCreationPage(
                appointmentId: _appointment!.id,
              ),
            )
          : MaterialPageRoute(
              builder: (context) => AppointmentCreationPage(
                appointmentId: _appointment!.id,
              ),
            ),
    );

    _loadAppointment();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    if (_isIos) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(loc.editAppointment),
        ),
        child: SafeArea(
          child: _buildBody(loc),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.editAppointment),
        ),
        body: _buildBody(loc),
      );
    }
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointment == null) {
      return Center(
        child: Text(
          'Appointment not found.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _buildDetailsContent(loc),
    );
  }

  Widget _buildDetailsContent(AppLocalizations loc) {
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
            color: Theme.of(context).cardColor,
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
          color: Theme.of(context).cardColor,
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
                        '${loc.startTime}: ${_formatDateTime(_computedStartTime)}',
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
                        '${loc.endTime}: ${_formatDateTime(_computedEndTime)}',
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
            color: Theme.of(context).cardColor,
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
          color: Theme.of(context).cardColor,
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

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAdaptiveOutlinedButton(
              icon: Icons.delete,
              label: loc.delete,
              onPressed: _deleteAppointment,
            ),
            _buildAdaptiveFilledButton(
              icon: Icons.edit,
              label: loc.editAppointment,
              onPressed: _editAppointment,
            ),
          ],
        ),
      ],
    );
  }

  /// Adaptive Bestätigungs-Dialog
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

  Widget _buildAdaptiveOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    if (_isIos) {
      return CupertinoButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.activeBlue),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: CupertinoColors.activeBlue)),
          ],
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
  }

  Widget _buildAdaptiveFilledButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    if (_isIos) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: CupertinoColors.white)),
          ],
        ),
      );
    } else {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
  }
}
