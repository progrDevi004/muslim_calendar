//lib/data/services/prayer_time_service.dart
import 'package:muslim_calendar/models/enums.dart';
import 'package:muslim_calendar/models/appointment_model.dart';
import '../repositories/prayer_time_repository.dart';

class PrayerTimeService {
  final PrayerTimeRepository prayerTimeRepo;

  PrayerTimeService(this.prayerTimeRepo);

  Future<DateTime?> getCalculatedStartTime(
      AppointmentModel appointment, DateTime date) async {
    if (!appointment.isRelatedToPrayerTimes || appointment.prayerTime == null) {
      return appointment.startTime;
    }
    final minutes = await prayerTimeRepo.getPrayerTimeMinutes(
        date, appointment.location!, appointment.prayerTime!);
    if (minutes == null) return null;
    DateTime baseTime = DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: minutes));
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
