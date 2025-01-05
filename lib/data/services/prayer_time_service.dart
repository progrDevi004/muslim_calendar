//lib/data/services/prayer_time_service.dart
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import '../repositories/prayer_time_repository.dart';

class PrayerTimeService {
  final PrayerTimeRepository prayerTimeRepo;

  PrayerTimeService(this.prayerTimeRepo);

  Future<DateTime?> getCalculatedStartTime(
    AppointmentModel appointment,
    DateTime fallbackDate, {
    bool useAppointmentDate = false,
  }) async {
    if (!appointment.isRelatedToPrayerTimes || appointment.prayerTime == null) {
      return appointment.startTime;
    }

    final minutes = await prayerTimeRepo.getPrayerTimeMinutes(
      useAppointmentDate ? appointment.startTime! : fallbackDate,
      appointment.location!,
      appointment.prayerTime!,
    );

    if (minutes == null) return null;

    // Basis-Datum: je nach Flag (Dashboard vs. Nicht-Dashboard)
    final baseSource =
        useAppointmentDate ? appointment.startTime! : fallbackDate;

    DateTime baseTime = DateTime(
      baseSource.year,
      baseSource.month,
      baseSource.day,
    ).add(Duration(minutes: minutes));

    // Vor/Nach (before/after)
    if (appointment.timeRelation == TimeRelation.before &&
        appointment.minutesBeforeAfter != null) {
      baseTime =
          baseTime.subtract(Duration(minutes: appointment.minutesBeforeAfter!));
    } else if (appointment.timeRelation == TimeRelation.after &&
        appointment.minutesBeforeAfter != null) {
      baseTime =
          baseTime.add(Duration(minutes: appointment.minutesBeforeAfter!));
    }
    return baseTime;
  }

  Future<DateTime?> getCalculatedEndTime(
      AppointmentModel appointment, DateTime date) async {
    final start = await getCalculatedStartTime(appointment, date);
    if (start == null) return null;
    if (appointment.isRelatedToPrayerTimes && appointment.duration != null) {
      return start.add(appointment.duration!);
    }
    return appointment.endTime;
  }
}
