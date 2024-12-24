//lib/data/services/recurrence_service.dart
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

class RecurrenceService {
  List<DateTime> getRecurrenceDates(
      AppointmentModel appointment, DateTime startRange, DateTime endRange) {
    if (appointment.recurrenceRule == null) return [];

    final dates = SfCalendar.getRecurrenceDateTimeCollection(
      appointment.recurrenceRule!,
      appointment.startTime ?? DateTime.now(),
      specificStartDate: startRange,
      specificEndDate: endRange,
    );

    if (appointment.recurrenceExceptionDates != null) {
      return dates
          .where((d) => !appointment.recurrenceExceptionDates!.any((ex) =>
              ex.year == d.year && ex.month == d.month && ex.day == d.day))
          .toList();
    }
    return dates;
  }
}
