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
  String modifyRecurrenceRule(String recurrenceRule, DateTime eventStartDate) {
    // Eğer recurrence rule içinde 'WKST=TU' varsa, bunu kaldır.
    if (recurrenceRule.contains('WKST')) {
      recurrenceRule = recurrenceRule.replaceAll(RegExp(r"WKST=[A-Za-z]{2}"), "");
    }

    // 'FREQ=WEEKLY' olduğu ve 'WKST' kısmı silindiği durumda, BYDAY ve INTERVAL eklememiz gerekiyor.
    if (recurrenceRule.contains('FREQ=WEEKLY')) {
      // Tarih bilgisini 'BYDAY' olarak ekleyebiliriz. Örnek: 'BYDAY=MO,TU'
      String byDay = _getByDayFromDate(eventStartDate);

      // Interval değeri 1 olarak eklenebilir, her hafta bir kez.
      recurrenceRule = '$recurrenceRule;BYDAY=$byDay;INTERVAL=1';
    }

    return recurrenceRule;
  }

  // Tarihe göre BYDAY bilgisini çıkaran yardımcı fonksiyon
  String _getByDayFromDate(DateTime date) {
    List<String> weekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return weekdays[date.weekday - 1];  // Date.weekday 1-7 arasıdır, haftanın gününe göre döner.
  }

  String adjustRecurrenceRuleForMondayStart(String recurrenceRule) {
    // Eğer recurrenceRule varsa
    if (!recurrenceRule.contains("BYDAY")) {
        // 'WKST' değerini alıp 'BYDAY' parametresini ekliyoruz
        if (recurrenceRule.contains("WKST")) {
            String wkstValue = recurrenceRule.split("WKST=")[1].split(";")[0];
            recurrenceRule = recurrenceRule + ";BYDAY=" + wkstValue;
        }
    }
    
    // Eğer 'WKST' parametresi varsa, bunu 'MO' olarak güncelleyelim
    if (recurrenceRule.contains("WKST")) {
        recurrenceRule = recurrenceRule.replaceAll(RegExp(r"WKST=[A-Za-z]{2}"), "");
    }

    // Eğer 'INTERVAL' parametresi yoksa, bunu 'INTERVAL=1' olarak ekleyelim
    if (!recurrenceRule.contains("INTERVAL")) {
        recurrenceRule = recurrenceRule + ";INTERVAL=1";
    }
    return recurrenceRule;
  }
}
