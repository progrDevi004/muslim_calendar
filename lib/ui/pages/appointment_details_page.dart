// lib/ui/pages/appointment_details_page.dart

import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/data/services/notification_service.dart';
import 'package:muslim_calendar/data/services/google_calendar_service.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';
import 'package:muslim_calendar/data/services/google_calendar_sync_service.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import 'package:muslim_calendar/models/category_model.dart';
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
  CategoryModel? _category;

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

        // Lade die Kategorie
        final category =
            await _appointmentRepo.getCategoryById(appt.categoryId ?? 1);

        setState(() {
          _appointment = appt;
          _category = category;
          _computedStartTime = start ?? appt.startTime;
          _computedEndTime = end ?? appt.endTime;
          _isLoading = false;
        });
      } else {
        setState(() {
          _appointment = null;
          _category = null;
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

        // 2) Dann Notification stornieren
        try {
          await NotificationService().cancelNotification(_appointment!.id!);
        } catch (notifErr) {
          debugPrint(
              'iOS-Knackpunkt: Notification-Cancel schlug fehl: $notifErr');
        }

        // 3) Google Calendar Eintrag löschen, falls vorhanden
        if (_appointment!.syncWithGoogleCalendar &&
            _appointment!.externalIdGoogle != null) {
          try {
            // Den GoogleCalendarService mit PrayerTimeService initialisieren
            final googleService =
                GoogleCalendarService.withPrayerTimeService(_prayerTimeService);
            googleService.setLocalizations(
                Provider.of<AppLocalizations>(context, listen: false));
            await googleService
                .deleteEventFromGoogleCalendar(_appointment!.externalIdGoogle!);
          } catch (googleErr) {
            debugPrint(
                'Fehler beim Löschen des Google Kalender Eintrags: $googleErr');
          }
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

  /// NEU: Mit Google Kalender synchronisieren (mit Kategorie-zu-Kalender-Mapping)
  Future<void> _syncWithGoogleCalendar() async {
    if (_appointment == null) return;

    debugPrint("🔄 _syncWithGoogleCalendar wurde aufgerufen");
    final loc = Provider.of<AppLocalizations>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final mounted = this.mounted;

    try {
      // Fortschrittsanzeige zeigen
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(loc.syncGoogleCalendarNow)),
        );
      }

      // CalendarSyncService aus dem Provider holen
      final calendarSyncService =
          Provider.of<CalendarSyncService>(context, listen: false);
      debugPrint("CalendarSyncService aus Provider geladen");

      // SyncWithGoogleCalendar-Flag aktivieren, falls noch nicht geschehen
      AppointmentModel updatedAppointment = _appointment!;
      debugPrint(
          "Aktueller Sync-Status: ${_appointment!.syncWithGoogleCalendar}");
      if (!_appointment!.syncWithGoogleCalendar) {
        debugPrint("Aktiviere syncWithGoogleCalendar Flag");
        updatedAppointment =
            _appointment!.copyWith(syncWithGoogleCalendar: true);
        await _appointmentRepo.updateAppointment(updatedAppointment);
        debugPrint("Flag in Datenbank aktualisiert");
      }

      // NEU: Hole alle Termine, um verwaiste Google-Kalendereinträge zu bereinigen
      final allAppointments = await _appointmentRepo.getAllAppointments();
      debugPrint(
          "Alle Termine geladen für Bereinigung von verwaisten Google-Einträgen");

      // Termin einzeln synchronisieren
      debugPrint(
          "Starte Synchronisierung mit kategoriebasiertem Kalender-Mapping");

      // 1. Alle Wiederholungsregeln korrigieren
      await calendarSyncService.fixInvalidRecurrenceRules();
      debugPrint("✅ Wiederholungsregeln korrigiert");

      // 2. Sync-Flag für diesen Termin aktivieren
      await _appointmentRepo.setGoogleSyncStatus(updatedAppointment.id!, true);
      debugPrint(
          "✅ Sync-Flag für Termin ID ${updatedAppointment.id} aktiviert");

      // 3. Export durchführen - nutzt kategoriebasiertes Mapping
      debugPrint("🔄 Starte Export mit exportToGoogleCalendarOnly()");
      await calendarSyncService.exportToGoogleCalendarOnly(
          useCategoryMapping: true);
      debugPrint("✅ Export abgeschlossen");

      // 4. NEU: Verwaiste Google-Kalendereinträge bereinigen
      // Wir verwenden direkt den CalendarSyncService für die Bereinigung
      debugPrint("🧹 Bereinige verwaiste Google-Kalendereinträge...");
      await calendarSyncService.cleanupOrphanedGoogleEvents(allAppointments);
      debugPrint("✅ Bereinigung abgeschlossen");

      // Laden des aktualisierten Termins
      await _loadAppointment();
      debugPrint("✅ Termin neu geladen");

      // Erfolgsanzeige - NEU: Wir löschen zuerst die alte Snackbar
      if (mounted) {
        scaffoldMessenger.clearSnackBars(); // Bestehende Snackbars löschen
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(loc.exportCompleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Fehler bei der Google-Synchronisierung: $e");
      // Fehlermeldung anzeigen
      if (mounted) {
        scaffoldMessenger.clearSnackBars(); // Bestehende Snackbars löschen
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(loc.syncError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

        // Kategorie
        Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.category, color: _category?.color ?? Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${loc.categoryLabel}: ${_category?.name ?? loc.privateCategory}',
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
        // FIX: Nur anzeigen, wenn mindestens eine Bedingung true ist.
        if (_appointment!.isAllDay || _appointment!.isRelatedToPrayerTimes)
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                loc.relatedToPrayerTimes,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_appointment!.prayerTime != null) ...[
                                Text(
                                  ': ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  loc.getPrayerTimeLabel(
                                      _appointment!.prayerTime!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          if (_appointment!.timeRelation != null &&
                              _appointment!.prayerTime != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${loc.getTimeRelationLabel(_appointment!.timeRelation!)} ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (_appointment!.minutesBeforeAfter != null)
                                  Text(
                                    '(${_appointment!.minutesBeforeAfter} ${loc.minutesBeforeAfter})',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // NEU: Wiederholungsregel anzeigen, falls vorhanden
        if (_appointment!.recurrenceRule != null &&
            _appointment!.recurrenceRule!.isNotEmpty)
          Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.repeat, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.recurrence,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRecurrenceTypeText(
                              _appointment!.recurrenceRule!, loc),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Erinnerung anzeigen (wenn vorhanden)
        if (_appointment!.reminderMinutesBefore != null &&
            _appointment!.reminderMinutesBefore! > 0)
          Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatReminderText(
                          _appointment!.reminderMinutesBefore!, loc),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Buttons - Neu angeordnet, um Overflow zu vermeiden
        Column(
          children: [
            // Erste Zeile: Löschen und Bearbeiten
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildAdaptiveOutlinedButton(
                    icon: Icons.delete,
                    label: loc.delete,
                    onPressed: _deleteAppointment,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAdaptiveFilledButton(
                    icon: Icons.edit,
                    label: loc.editAppointment,
                    onPressed: _editAppointment,
                  ),
                ),
              ],
            ),

            // Zweite Zeile: Google Sync Button (volle Breite)
            const SizedBox(height: 12),

            // Info-Anzeige über den Google-Sync-Status
            if (_appointment!.syncWithGoogleCalendar ||
                _appointment!.externalIdGoogle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _appointment!.externalIdGoogle != null
                          ? Icons.check_circle
                          : Icons.pending,
                      color: _appointment!.externalIdGoogle != null
                          ? Colors.green
                          : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _appointment!.externalIdGoogle != null
                            ? _appointment!.lastSyncedAt != null
                                ? "Zuletzt synchronisiert: ${DateFormat('dd.MM.yyyy, HH:mm').format(_appointment!.lastSyncedAt!)}"
                                : "Mit Google Kalender synchronisiert"
                            : "Synchronisierung mit Google Kalender aktiviert",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: _buildAdaptiveOutlinedButton(
                icon: _appointment!.syncWithGoogleCalendar
                    ? Icons.sync
                    : Icons.sync_disabled,
                label: _appointment!.syncWithGoogleCalendar &&
                        _appointment!.externalIdGoogle != null
                    ? "Mit Google erneut synchronisieren"
                    : "Mit Google synchronisieren",
                onPressed: () async {
                  // Direkt die Synchronisierungsmethode aufrufen
                  debugPrint("Google Sync Button wurde gedrückt");
                  await _syncWithGoogleCalendar();
                },
              ),
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

  String _formatReminderText(int minutesBefore, AppLocalizations loc) {
    if (minutesBefore < 60) {
      return loc.minutesBefore(minutesBefore);
    } else if (minutesBefore < 1440) {
      final hours = (minutesBefore / 60).floor();
      return loc.hoursBefore(hours);
    } else {
      final days = (minutesBefore / 1440).floor();
      return loc.daysBefore(days);
    }
  }

  // Helper-Methode, um die Wiederholungsregel in lesbaren Text umzuwandeln
  String _getRecurrenceTypeText(String recurrenceRule, AppLocalizations loc) {
    // Prüfen auf benutzerdefinierte Parameter (COUNT, UNTIL, BYDAY mit mehreren Tagen)
    bool isCustom = recurrenceRule.contains("COUNT=") ||
        recurrenceRule.contains("UNTIL=") ||
        (recurrenceRule.contains("BYDAY=") &&
            (recurrenceRule.contains(",") ||
                !recurrenceRule
                    .contains("BYDAY=" + _getDayOfWeekCode(DateTime.now()))));

    if (isCustom) {
      return loc.getRecurrenceTypeLabel("custom");
    } else if (recurrenceRule.contains("FREQ=DAILY")) {
      return loc.getRecurrenceTypeLabel("daily");
    } else if (recurrenceRule.contains("FREQ=WEEKLY")) {
      return loc.getRecurrenceTypeLabel("weekly");
    } else if (recurrenceRule.contains("FREQ=MONTHLY")) {
      return loc.getRecurrenceTypeLabel("monthly");
    } else if (recurrenceRule.contains("FREQ=YEARLY")) {
      return loc.getRecurrenceTypeLabel("yearly");
    } else {
      return loc.getRecurrenceTypeLabel("custom");
    }
  }

  // Hilfsmethod zum Bestimmen des Wochentagscodes
  String _getDayOfWeekCode(DateTime date) {
    final weekDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return weekDays[
        date.weekday - 1]; // weekday gibt 1-7 zurück, wobei 1=Montag
  }

  // Aktualisiere den Termin mit berechneten Gebetszeiten
  /*
  Future<void> _updateAppointment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Erstelle ein aktualisiertes Appointment Objekt mit den eingegebenen Daten
        AppointmentModel updatedAppointment = AppointmentModel(
          id: _appointment!.id,
          subject: _subjectController.text,
          notes: _notesController.text,
          isAllDay: _isAllDay,
          isRelatedToPrayerTimes: _isRelatedToPrayerTimes,
          prayerTime: _selectedPrayerTime,
          timeRelation: _selectedTimeRelation,
          minutesBeforeAfter: _minutesBeforeAfter,
          duration: _duration,
          location: _locationController.text,
          recurrenceRule: _recurrenceRule,
          recurrenceExceptionDates: _appointment!.recurrenceExceptionDates,
          color: _selectedColor,
          startTime: _selectedDate,
          endTime: _selectedDate != null && _duration != null
              ? _selectedDate!.add(_duration!)
              : null,
          categoryId: _selectedCategoryId,
          reminderMinutesBefore: _reminderMinutes,
          syncWithGoogleCalendar: _appointment!.syncWithGoogleCalendar,
          externalIdGoogle: _appointment!.externalIdGoogle,
          externalIdOutlook: _appointment!.externalIdOutlook,
          externalIdApple: _appointment!.externalIdApple,
          lastSyncedAt: _appointment!.lastSyncedAt,
        );

        // Vor dem Speichern des Appointments prüfen, ob es gebetszeitabhängig ist
        // und wenn ja, die berechneten Zeiten abrufen und im Appointment aktualisieren

        // Speichern
        await _appointmentRepo.updateAppointment(updatedAppointment);

        // Wenn der Termin gebetszeitabhängig ist, müssen wir die berechneten Zeiten abrufen
        if (updatedAppointment.isRelatedToPrayerTimes && updatedAppointment.prayerTime != null) {
          final baseDate = DateTime(
            updatedAppointment.startTime!.year,
            updatedAppointment.startTime!.month,
            updatedAppointment.startTime!.day,
          );

          // Berechnete Start- und Endzeiten abrufen
          final calculatedStart = await _prayerTimeService.getCalculatedStartTime(
            updatedAppointment,
            baseDate,
          );
          final calculatedEnd = await _prayerTimeService.getCalculatedEndTime(
            updatedAppointment,
            baseDate,
          );

          if (calculatedStart != null && calculatedEnd != null) {
            // Neues Appointment mit berechneten Zeiten erstellen
            final finalAppointment = updatedAppointment.copyWith(
              startTime: calculatedStart,
              endTime: calculatedEnd,
            );

            // In DB aktualisieren
            await _appointmentRepo.updateAppointment(finalAppointment);
          }
        }

        // Benachrichtigung senden, wenn gewünscht
        if (updatedAppointment.reminderMinutesBefore != null &&
            updatedAppointment.reminderMinutesBefore! > 0 &&
            updatedAppointment.startTime != null) {
          final reminderTime = updatedAppointment.startTime!
              .subtract(Duration(minutes: updatedAppointment.reminderMinutesBefore!));
          await NotificationService().scheduleNotification(
            appointmentId: updatedAppointment.id!,
            title: 'Erinnerung: ${updatedAppointment.subject}',
            body: 'Du hast bald einen Termin',
            dateTime: reminderTime,
          );
        }

        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        // Warte kurz und gehe dann zurück
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(true);
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Fehler beim Speichern: $e";
        });
      }
    }
  }
  */
}
