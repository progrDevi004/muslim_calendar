import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import 'package:muslim_calendar/ui/pages/appointment_details_page.dart';
import 'package:muslim_calendar/ui/pages/appointment_creation_page.dart';

class CalendarViewWidget extends StatelessWidget {
  final CalendarView selectedView;
  final CalendarController calendarController;
  final CalendarDataSource? dataSource;
  final DateTime? selectedDate;
  final bool use24hFormat;
  final bool showPrayerTimesInDayView;
  final bool showPrayerTimesInWeekView;
  final bool showPrayerTimesInMonthView;
  final String languageCode;
  final Function(CalendarView) onViewChanged;
  final Function(DateTime?) onSelectedDateChanged;
  final VoidCallback onAppointmentsChanged;

  const CalendarViewWidget({
    Key? key,
    required this.selectedView,
    required this.calendarController,
    required this.dataSource,
    required this.selectedDate,
    required this.use24hFormat,
    required this.showPrayerTimesInDayView,
    required this.showPrayerTimesInWeekView,
    this.showPrayerTimesInMonthView = false,
    required this.languageCode,
    required this.onViewChanged,
    required this.onSelectedDateChanged,
    required this.onAppointmentsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Localizations.override(
        context: context,
        locale: Locale(languageCode),
        child: SfCalendar(
          headerStyle: const CalendarHeaderStyle(
            backgroundColor: Colors.transparent,
            textAlign: TextAlign.center,
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          view: selectedView,
          controller: calendarController,
          dataSource: dataSource,
          allowAppointmentResize: true,
          showDatePickerButton: true,
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: true,
            agendaItemHeight: 50,
            monthCellStyle: MonthCellStyle(
              trailingDatesBackgroundColor: Color.fromARGB(0, 165, 165, 165),
            ),
          ),
          timeSlotViewSettings: TimeSlotViewSettings(
            timeIntervalHeight: 80,
            timeFormat: use24hFormat ? 'HH' : 'h a',
          ),
          appointmentBuilder:
              (BuildContext context, CalendarAppointmentDetails details) {
            if (details.appointments.isEmpty) {
              return const SizedBox.shrink();
            }
            final Appointment appointment = details.appointments.first;

            // Für Gebetszeiten spezielles Styling
            final bool isPrayerTime = appointment.notes == 'prayerTime';

            // In jedem Fall überprüfen wir die aktuelle Ansicht und die entsprechenden Einstellungen
            bool shouldShowPrayerTime = false;

            if (isPrayerTime) {
              if (selectedView == CalendarView.day) {
                shouldShowPrayerTime = showPrayerTimesInDayView;
              } else if (selectedView == CalendarView.week) {
                shouldShowPrayerTime = showPrayerTimesInWeekView;
              } else if (selectedView == CalendarView.month) {
                shouldShowPrayerTime = showPrayerTimesInMonthView;
              } else {
                // In anderen Ansichten keine Gebetszeiten anzeigen
                shouldShowPrayerTime = false;
              }

              // Wenn Gebetszeit nicht angezeigt werden soll, leeres Widget zurückgeben
              if (!shouldShowPrayerTime) {
                return const SizedBox.shrink();
              }
            }

            // Spezielles Styling für Gebetszeiten, wenn sie angezeigt werden sollen
            if (isPrayerTime) {
              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors
                      .grey[400], // Dunkleres Grau für bessere Sichtbarkeit
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        Colors.black26, // Dunklere Ränder für besseren Kontrast
                    width: 1,
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    appointment.subject,
                    style: const TextStyle(
                      color: Colors
                          .black87, // Sehr dunkles Grau für gute Lesbarkeit
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Für die Monatsansicht
            if (selectedView == CalendarView.month) {
              return Container(
                decoration: BoxDecoration(
                  color: appointment.color,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(4),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: appointment.isAllDay
                    ? Text(
                        appointment.subject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              );
            }

            // Für normale Termine in Tag- und Wochenansicht
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: appointment.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  appointment.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            );
          },
          onSelectionChanged: (details) {
            // Verzögere die State-Änderung, um sie außerhalb des Build-Prozesses auszuführen
            Future.microtask(() {
              onSelectedDateChanged(details.date);
            });
          },
          onViewChanged: (ViewChangedDetails details) {
            // Wenn sich die Ansicht ändert, aktualisieren wir die Variablen
            if (calendarController.view != null) {
              CalendarView newView = calendarController.view!;

              // Nur wenn sich die Ansicht tatsächlich geändert hat
              if (newView != selectedView) {
                // Verzögere den Callback, um setState während des Build-Prozesses zu vermeiden
                Future.microtask(() {
                  onViewChanged(newView);
                });
              }
            }
          },
          onTap: (calendarTapDetails) async {
            if (calendarTapDetails.targetElement ==
                CalendarElement.appointment) {
              final app = calendarTapDetails.appointments?.first;
              if (app == null) return;
              if (app.notes == 'prayerTime') return;
              if (app.id is int) {
                final appointmentId = app.id as int;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AppointmentDetailsPage(
                      appointmentId: appointmentId,
                    ),
                  ),
                );
                onAppointmentsChanged();
              }
            } else if (calendarTapDetails.targetElement ==
                CalendarElement.calendarCell) {
              // Datum ändern, wenn auf eine Kalenderzelle geklickt wird
              if (calendarTapDetails.date != selectedDate) {
                Future.microtask(() {
                  onSelectedDateChanged(calendarTapDetails.date);
                });
              }

              // In der Monatsansicht nie automatisch zur Tagesansicht wechseln
              if (selectedView == CalendarView.month) {
                return;
              }
            }
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final pattern = use24hFormat ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern, languageCode).format(dt);
  }
}
