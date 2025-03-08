// lib/localization/app_localizations.dart

import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

enum AppLanguage { english, german, turkish, arabic, bosnian, spanish, persian }

class AppLocalizations extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  String getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.german:
        return "Deutsch";
      case AppLanguage.turkish:
        return "Türkçe";
      case AppLanguage.arabic:
        return "العربية";
      case AppLanguage.bosnian:
        return "Bosanski";
      case AppLanguage.spanish:
        return "Español";
      case AppLanguage.persian:
        return "فارسی";
      case AppLanguage.english:
      default:
        return "English";
    }
  }

  String mapAppLanguageToCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.german:
        return 'de';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.bosnian:
        return 'bs';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.english:
      default:
        return 'en';
    }
  }

  // ------------------------------
  // Allgemeine Begriffe
  // ------------------------------
  String get settings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Einstellungen';
      case AppLanguage.turkish:
        return 'Ayarlar';
      case AppLanguage.arabic:
        return 'الإعدادات';
      case AppLanguage.bosnian:
        return 'Postavke';
      case AppLanguage.spanish:
        return 'Ajustes';
      case AppLanguage.persian:
        return 'تنظیمات';
      case AppLanguage.english:
      default:
        return 'Settings';
    }
  }

  String get initialLocationPageTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Standort-Einstellungen';
      case AppLanguage.turkish:
        return 'Konum Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات الموقع';
      case AppLanguage.bosnian:
        return 'Postavke lokacije';
      case AppLanguage.spanish:
        return 'Ajustes de ubicación';
      case AppLanguage.persian:
        return 'تنظیمات موقعیت';
      case AppLanguage.english:
      default:
        return 'Location Settings';
    }
  }

  String get next {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Weiter';
      case AppLanguage.turkish:
        return 'İleri';
      case AppLanguage.arabic:
        return 'التالي';
      case AppLanguage.bosnian:
        return 'Dalje';
      case AppLanguage.spanish:
        return 'Siguiente';
      case AppLanguage.persian:
        return 'بعدی';
      case AppLanguage.english:
      default:
        return 'Next';
    }
  }

  String get back {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zurück';
      case AppLanguage.turkish:
        return 'Geri';
      case AppLanguage.arabic:
        return 'رجوع';
      case AppLanguage.bosnian:
        return 'Nazad';
      case AppLanguage.spanish:
        return 'Atrás';
      case AppLanguage.persian:
        return 'بازگشت';
      case AppLanguage.english:
      default:
        return 'Back';
    }
  }

  String get myCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Mein Kalender';
      case AppLanguage.turkish:
        return 'Takvimim';
      case AppLanguage.arabic:
        return 'تقويمي';
      case AppLanguage.bosnian:
        return 'Moj kalendar';
      case AppLanguage.spanish:
        return 'Mi calendario';
      case AppLanguage.persian:
        return 'تقویم من';
      case AppLanguage.english:
      default:
        return 'My Calendar';
    }
  }

  String get month {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Monat';
      case AppLanguage.turkish:
        return 'Ay';
      case AppLanguage.arabic:
        return 'شهر';
      case AppLanguage.bosnian:
        return 'Mjesec';
      case AppLanguage.spanish:
        return 'Mes';
      case AppLanguage.persian:
        return 'ماه';
      case AppLanguage.english:
      default:
        return 'Month';
    }
  }

  String get week {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Woche';
      case AppLanguage.turkish:
        return 'Hafta';
      case AppLanguage.arabic:
        return 'أسبوع';
      case AppLanguage.bosnian:
        return 'Sedmica';
      case AppLanguage.spanish:
        return 'Semana';
      case AppLanguage.persian:
        return 'هفته';
      case AppLanguage.english:
      default:
        return 'Week';
    }
  }

  String get day {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Tag';
      case AppLanguage.turkish:
        return 'Gün';
      case AppLanguage.arabic:
        return 'يوم';
      case AppLanguage.bosnian:
        return 'Dan';
      case AppLanguage.spanish:
        return 'Día';
      case AppLanguage.persian:
        return 'روز';
      case AppLanguage.english:
      default:
        return 'Day';
    }
  }

  // ------------------------------
  // Termin-Erstellung
  // ------------------------------
  String get createAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termin erstellen';
      case AppLanguage.turkish:
        return 'Randevu Oluştur';
      case AppLanguage.arabic:
        return 'إنشاء موعد';
      case AppLanguage.bosnian:
        return 'Kreiraj termin';
      case AppLanguage.spanish:
        return 'Crear cita';
      case AppLanguage.persian:
        return 'ایجاد قرار';
      case AppLanguage.english:
      default:
        return 'Create Appointment';
    }
  }

  String get editAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termin bearbeiten';
      case AppLanguage.turkish:
        return 'Randevuyu Düzenle';
      case AppLanguage.arabic:
        return 'تعديل الموعد';
      case AppLanguage.bosnian:
        return 'Uredi termin';
      case AppLanguage.spanish:
        return 'Editar cita';
      case AppLanguage.persian:
        return 'ویرایش قرار';
      case AppLanguage.english:
      default:
        return 'Edit Appointment';
    }
  }

  String get titleLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Titel';
      case AppLanguage.turkish:
        return 'Başlık';
      case AppLanguage.arabic:
        return 'عنوان';
      case AppLanguage.bosnian:
        return 'Naslov';
      case AppLanguage.spanish:
        return 'Título';
      case AppLanguage.persian:
        return 'عنوان';
      case AppLanguage.english:
      default:
        return 'Title';
    }
  }

  String get description {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Beschreibung';
      case AppLanguage.turkish:
        return 'Açıklama';
      case AppLanguage.arabic:
        return 'وصف';
      case AppLanguage.bosnian:
        return 'Opis';
      case AppLanguage.spanish:
        return 'Descripción';
      case AppLanguage.persian:
        return 'توضیح';
      case AppLanguage.english:
      default:
        return 'Description';
    }
  }

  String get allDay {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ganztägig';
      case AppLanguage.turkish:
        return 'Tüm Gün';
      case AppLanguage.arabic:
        return 'طوال اليوم';
      case AppLanguage.bosnian:
        return 'Cijeli dan';
      case AppLanguage.spanish:
        return 'Todo el día';
      case AppLanguage.persian:
        return 'تمام روز';
      case AppLanguage.english:
      default:
        return 'All Day';
    }
  }

  String get allDaySubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ereignis dauert den ganzen Tag';
      case AppLanguage.turkish:
        return 'Etkinlik tüm gün sürer';
      case AppLanguage.arabic:
        return 'يستمر الحدث طوال اليوم';
      case AppLanguage.bosnian:
        return 'Događaj traje cijeli dan';
      case AppLanguage.spanish:
        return 'El evento dura todo el día';
      case AppLanguage.persian:
        return 'رویداد تمام روز طول می‌کشد';
      case AppLanguage.english:
      default:
        return 'Event lasts the whole day';
    }
  }

  String get relatedToPrayerTimes {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bezogen auf Gebetszeiten';
      case AppLanguage.turkish:
        return 'Namaz Vakitleri ile İlişkili';
      case AppLanguage.arabic:
        return 'مرتبط بأوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Povezano s vremenima namaza';
      case AppLanguage.spanish:
        return 'Relacionado con los tiempos de oración';
      case AppLanguage.persian:
        return 'مرتبط با اوقات نماز';
      case AppLanguage.english:
      default:
        return 'Related to Prayer Times';
    }
  }

  String get relatedToPrayerTimesSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ereigniszeit hängt von täglichen Gebetszeiten ab';
      case AppLanguage.turkish:
        return 'Etkinlik zamanı günlük namaz vakitlerine bağlıdır';
      case AppLanguage.arabic:
        return 'وقت الحدث يعتمد على أوقات الصلاة اليومية';
      case AppLanguage.bosnian:
        return 'Vrijeme događaja zavisi od dnevnih vremena namaza';
      case AppLanguage.spanish:
        return 'La hora del evento depende de los tiempos de oración diarios';
      case AppLanguage.persian:
        return 'زمان رویداد به اوقات نماز روزانه بستگی دارد';
      case AppLanguage.english:
      default:
        return 'Event time depends on daily prayer times';
    }
  }

  String get save {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Speichern';
      case AppLanguage.turkish:
        return 'Kaydet';
      case AppLanguage.arabic:
        return 'حفظ';
      case AppLanguage.bosnian:
        return 'Sačuvaj';
      case AppLanguage.spanish:
        return 'Guardar';
      case AppLanguage.persian:
        return 'ذخیره';
      case AppLanguage.english:
      default:
        return 'Save';
    }
  }

  String get delete {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Löschen';
      case AppLanguage.turkish:
        return 'Sil';
      case AppLanguage.arabic:
        return 'حذف';
      case AppLanguage.bosnian:
        return 'Izbriši';
      case AppLanguage.spanish:
        return 'Eliminar';
      case AppLanguage.persian:
        return 'حذف';
      case AppLanguage.english:
      default:
        return 'Delete';
    }
  }

  String get noRecurrence {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Keine Wiederholung';
      case AppLanguage.turkish:
        return 'Tekrar yok';
      case AppLanguage.arabic:
        return 'لا تكرار';
      case AppLanguage.bosnian:
        return 'Bez ponavljanja';
      case AppLanguage.spanish:
        return 'Sin repetición';
      case AppLanguage.persian:
        return 'بدون تکرار';
      case AppLanguage.english:
      default:
        return 'No Recurrence';
    }
  }

  String get customRecurrence {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Benutzerdefinierte Wiederholung';
      case AppLanguage.turkish:
        return 'Özel Tekrar';
      case AppLanguage.arabic:
        return 'تكرار مخصص';
      case AppLanguage.bosnian:
        return 'Prilagođeno ponavljanje';
      case AppLanguage.spanish:
        return 'Repetición personalizada';
      case AppLanguage.persian:
        return 'تکرار سفارشی';
      case AppLanguage.english:
      default:
        return 'Custom Recurrence';
    }
  }

  String get custom {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Benutzerdefiniert';
      case AppLanguage.turkish:
        return 'Özel';
      case AppLanguage.arabic:
        return 'مخصص';
      case AppLanguage.bosnian:
        return 'Prilagođeno';
      case AppLanguage.spanish:
        return 'Personalizado';
      case AppLanguage.persian:
        return 'سفارشی';
      case AppLanguage.english:
      default:
        return 'Custom';
    }
  }

  String get interval {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Intervall';
      case AppLanguage.turkish:
        return 'Aralık';
      case AppLanguage.arabic:
        return 'الفاصل';
      case AppLanguage.bosnian:
        return 'Interval';
      case AppLanguage.spanish:
        return 'Intervalo';
      case AppLanguage.persian:
        return 'بازه زمانی';
      case AppLanguage.english:
      default:
        return 'Interval';
    }
  }

  String get recurrenceTypeFieldLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Typ';
      case AppLanguage.turkish:
        return 'Tür';
      case AppLanguage.arabic:
        return 'النوع';
      case AppLanguage.bosnian:
        return 'Tip';
      case AppLanguage.spanish:
        return 'Tipo';
      case AppLanguage.persian:
        return 'نوع';
      case AppLanguage.english:
      default:
        return 'Type';
    }
  }

  String get count {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Anzahl';
      case AppLanguage.turkish:
        return 'Sayı';
      case AppLanguage.arabic:
        return 'العدد';
      case AppLanguage.bosnian:
        return 'Broj';
      case AppLanguage.spanish:
        return 'Número';
      case AppLanguage.persian:
        return 'تعداد';
      case AppLanguage.english:
      default:
        return 'Count';
    }
  }

  String get endDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Enddatum';
      case AppLanguage.turkish:
        return 'Bitiş Tarihi';
      case AppLanguage.arabic:
        return 'تاريخ الانتهاء';
      case AppLanguage.bosnian:
        return 'Datum završetka';
      case AppLanguage.spanish:
        return 'Fecha final';
      case AppLanguage.persian:
        return 'تاریخ پایان';
      case AppLanguage.english:
      default:
        return 'End Date';
    }
  }

  String get noEndDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kein Enddatum';
      case AppLanguage.turkish:
        return 'Bitiş Tarihi Yok';
      case AppLanguage.arabic:
        return 'لا تاريخ انتهاء';
      case AppLanguage.bosnian:
        return 'Nema datuma završetka';
      case AppLanguage.spanish:
        return 'Sin fecha final';
      case AppLanguage.persian:
        return 'بدون تاریخ پایان';
      case AppLanguage.english:
      default:
        return 'No End Date';
    }
  }

  String get general {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Allgemein';
      case AppLanguage.turkish:
        return 'Genel';
      case AppLanguage.arabic:
        return 'عام';
      case AppLanguage.bosnian:
        return 'Opće';
      case AppLanguage.spanish:
        return 'General';
      case AppLanguage.persian:
        return 'عمومی';
      case AppLanguage.english:
      default:
        return 'General';
    }
  }

  String get prayerTimeSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeit-Einstellungen';
      case AppLanguage.turkish:
        return 'Namaz Vakti Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات أوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Postavke vremena namaza';
      case AppLanguage.spanish:
        return 'Configuración de tiempos de oración';
      case AppLanguage.persian:
        return 'تنظیمات اوقات نماز';
      case AppLanguage.english:
      default:
        return 'Prayer Time Settings';
    }
  }

  String get prayerTimeDashboard {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten';
      case AppLanguage.turkish:
        return 'Namaz Vakitleri';
      case AppLanguage.arabic:
        return 'اوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Vremena namaza';
      case AppLanguage.spanish:
        return 'Tiempos de oración';
      case AppLanguage.persian:
        return 'اوقات نماز';
      case AppLanguage.english:
      default:
        return 'Prayer Times';
    }
  }

  String get selectDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Datum wählen';
      case AppLanguage.turkish:
        return 'Tarih Seç';
      case AppLanguage.arabic:
        return 'اختر التاريخ';
      case AppLanguage.bosnian:
        return 'Izaberi datum';
      case AppLanguage.spanish:
        return 'Seleccionar fecha';
      case AppLanguage.persian:
        return 'انتخاب تاریخ';
      case AppLanguage.english:
      default:
        return 'Select Date';
    }
  }

  String get selectPrayerTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeit auswählen';
      case AppLanguage.turkish:
        return 'Namaz Vakti Seç';
      case AppLanguage.arabic:
        return 'اختر وقت الصلاة';
      case AppLanguage.bosnian:
        return 'Izaberi vrijeme namaza';
      case AppLanguage.spanish:
        return 'Seleccionar tiempo de oración';
      case AppLanguage.persian:
        return 'انتخاب زمان نماز';
      case AppLanguage.english:
      default:
        return 'Select Prayer Time';
    }
  }

  String get prayerTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeit';
      case AppLanguage.turkish:
        return 'Namaz Vakti';
      case AppLanguage.arabic:
        return 'وقت الصلاة';
      case AppLanguage.bosnian:
        return 'Vrijeme namaza';
      case AppLanguage.spanish:
        return 'Tiempo de oración';
      case AppLanguage.persian:
        return 'زمان نماز';
      case AppLanguage.english:
      default:
        return 'Prayer Time';
    }
  }

  // >>> NEU: Übersetzungen für die Gebetszeiten
  String getPrayerTimeLabel(PrayerTime pt) {
    switch (pt) {
      case PrayerTime.fajr:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'Sabah';
          case AppLanguage.arabic:
            return 'فجر';
          case AppLanguage.bosnian:
            return 'Fajr';
          case AppLanguage.spanish:
            return 'Fajr';
          case AppLanguage.persian:
            return 'فجر';
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Fajr';
        }
      case PrayerTime.dhuhr:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'Öğlen';
          case AppLanguage.arabic:
            return 'ظهر';
          case AppLanguage.bosnian:
            return 'Dhuhr';
          case AppLanguage.spanish:
            return 'Dhuhr';
          case AppLanguage.persian:
            return 'ظهر';
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Dhuhr';
        }
      case PrayerTime.asr:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'İkindi';
          case AppLanguage.arabic:
            return 'عصر';
          case AppLanguage.bosnian:
            return 'Asr';
          case AppLanguage.spanish:
            return 'Asr';
          case AppLanguage.persian:
            return 'عصر';
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Asr';
        }
      case PrayerTime.maghrib:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'Akşam';
          case AppLanguage.arabic:
            return 'مغرب';
          case AppLanguage.bosnian:
            return 'Maghrib';
          case AppLanguage.spanish:
            return 'Maghrib';
          case AppLanguage.persian:
            return 'مغرب';
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Maghrib';
        }
      case PrayerTime.isha:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'Yatsı';
          case AppLanguage.arabic:
            return 'عشاء';
          case AppLanguage.bosnian:
            return 'Isha';
          case AppLanguage.spanish:
            return 'Isha';
          case AppLanguage.persian:
            return 'عشاء';
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Isha';
        }
    }
  }

  // >>> NEU: Übersetzungen für TimeRelation
  String getTimeRelationLabel(TimeRelation tr) {
    switch (tr) {
      case TimeRelation.before:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Vorher';
          case AppLanguage.turkish:
            return 'Önce';
          case AppLanguage.arabic:
            return 'قبل';
          case AppLanguage.bosnian:
            return 'Prije';
          case AppLanguage.spanish:
            return 'Antes';
          case AppLanguage.persian:
            return 'قبل';
          case AppLanguage.english:
          default:
            return 'Before';
        }
      case TimeRelation.after:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Nachher';
          case AppLanguage.turkish:
            return 'Sonra';
          case AppLanguage.arabic:
            return 'بعد';
          case AppLanguage.bosnian:
            return 'Poslije';
          case AppLanguage.spanish:
            return 'Después';
          case AppLanguage.persian:
            return 'بعد';
          case AppLanguage.english:
          default:
            return 'After';
        }
    }
  }

  String get timeRelation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zeitbezug';
      case AppLanguage.turkish:
        return 'Zaman İlişkisi';
      case AppLanguage.arabic:
        return 'العلاقة الزمنية';
      case AppLanguage.bosnian:
        return 'Vremenski odnos';
      case AppLanguage.spanish:
        return 'Relación temporal';
      case AppLanguage.persian:
        return 'ارتباط زمانی';
      case AppLanguage.english:
      default:
        return 'Time Relation';
    }
  }

  String get minutesBeforeAfter {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Minuten Vor/Nachher';
      case AppLanguage.turkish:
        return 'Önce/Sonra Dakika';
      case AppLanguage.arabic:
        return 'دقائق قبل/بعد';
      case AppLanguage.bosnian:
        return 'Minute prije/nakon';
      case AppLanguage.spanish:
        return 'Minutos antes/después';
      case AppLanguage.persian:
        return 'دقیقه قبل/بعد';
      case AppLanguage.english:
      default:
        return 'Minutes Before/After';
    }
  }

  String get durationMinutes {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Dauer (Minuten)';
      case AppLanguage.turkish:
        return 'Süre (dakika)';
      case AppLanguage.arabic:
        return 'المدة (دقائق)';
      case AppLanguage.bosnian:
        return 'Trajanje (minute)';
      case AppLanguage.spanish:
        return 'Duración (minutos)';
      case AppLanguage.persian:
        return 'مدت (دقیقه)';
      case AppLanguage.english:
      default:
        return 'Duration (minutes)';
    }
  }

  String get selectCountry {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Land auswählen';
      case AppLanguage.turkish:
        return 'Ülke Seç';
      case AppLanguage.arabic:
        return 'اختر البلد';
      case AppLanguage.bosnian:
        return 'Izaberi državu';
      case AppLanguage.spanish:
        return 'Seleccionar país';
      case AppLanguage.persian:
        return 'انتخاب کشور';
      case AppLanguage.english:
      default:
        return 'Select Country';
    }
  }

  String get country {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Land';
      case AppLanguage.turkish:
        return 'Ülke';
      case AppLanguage.arabic:
        return 'البلد';
      case AppLanguage.bosnian:
        return 'Država';
      case AppLanguage.spanish:
        return 'País';
      case AppLanguage.persian:
        return 'کشور';
      case AppLanguage.english:
      default:
        return 'Country';
    }
  }

  String get selectCity {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Stadt auswählen';
      case AppLanguage.turkish:
        return 'Şehir Seç';
      case AppLanguage.arabic:
        return 'اختر المدينة';
      case AppLanguage.bosnian:
        return 'Izaberi grad';
      case AppLanguage.spanish:
        return 'Seleccionar ciudad';
      case AppLanguage.persian:
        return 'انتخاب شهر';
      case AppLanguage.english:
      default:
        return 'Select City';
    }
  }

  String get city {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Stadt';
      case AppLanguage.turkish:
        return 'Şehir';
      case AppLanguage.arabic:
        return 'مدينة';
      case AppLanguage.bosnian:
        return 'Grad';
      case AppLanguage.spanish:
        return 'Ciudad';
      case AppLanguage.persian:
        return 'شهر';
      case AppLanguage.english:
      default:
        return 'City';
    }
  }

  String get timeSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zeiteinstellungen';
      case AppLanguage.turkish:
        return 'Zaman Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات الوقت';
      case AppLanguage.bosnian:
        return 'Postavke vremena';
      case AppLanguage.spanish:
        return 'Configuración de tiempo';
      case AppLanguage.persian:
        return 'تنظیمات زمان';
      case AppLanguage.english:
      default:
        return 'Time Settings';
    }
  }

  String get startTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Startzeit';
      case AppLanguage.turkish:
        return 'Başlangıç Zamanı';
      case AppLanguage.arabic:
        return 'وقت البداية';
      case AppLanguage.bosnian:
        return 'Vrijeme početka';
      case AppLanguage.spanish:
        return 'Hora de inicio';
      case AppLanguage.persian:
        return 'زمان شروع';
      case AppLanguage.english:
      default:
        return 'Start Time';
    }
  }

  String get selectStartTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Startzeit wählen';
      case AppLanguage.turkish:
        return 'Başlangıç Zamanı Seç';
      case AppLanguage.arabic:
        return 'اختر وقت البداية';
      case AppLanguage.bosnian:
        return 'Izaberi vrijeme početka';
      case AppLanguage.spanish:
        return 'Seleccionar hora de inicio';
      case AppLanguage.persian:
        return 'انتخاب زمان شروع';
      case AppLanguage.english:
      default:
        return 'Select Start Time';
    }
  }

  String get endTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Endzeit';
      case AppLanguage.turkish:
        return 'Bitiş Zamanı';
      case AppLanguage.arabic:
        return 'وقت النهاية';
      case AppLanguage.bosnian:
        return 'Vrijeme završetka';
      case AppLanguage.spanish:
        return 'Hora de finalización';
      case AppLanguage.persian:
        return 'زمان پایان';
      case AppLanguage.english:
      default:
        return 'End Time';
    }
  }

  String get selectEndTime {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Endzeit wählen';
      case AppLanguage.turkish:
        return 'Bitiş Zamanı Seç';
      case AppLanguage.arabic:
        return 'اختر وقت النهاية';
      case AppLanguage.bosnian:
        return 'Izaberi vrijeme završetka';
      case AppLanguage.spanish:
        return 'Seleccionar hora de finalización';
      case AppLanguage.persian:
        return 'انتخاب زمان پایان';
      case AppLanguage.english:
      default:
        return 'Select End Time';
    }
  }

  String get recurrence {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholung';
      case AppLanguage.turkish:
        return 'Tekrar';
      case AppLanguage.arabic:
        return 'التكرار';
      case AppLanguage.bosnian:
        return 'Ponavljanje';
      case AppLanguage.spanish:
        return 'Recurrencia';
      case AppLanguage.persian:
        return 'تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence';
    }
  }

  String get recurringEvent {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederkehrendes Ereignis';
      case AppLanguage.turkish:
        return 'Tekrarlayan Etkinlik';
      case AppLanguage.arabic:
        return 'حدث متكرر';
      case AppLanguage.bosnian:
        return 'Ponavljajući događaj';
      case AppLanguage.spanish:
        return 'Evento recurrente';
      case AppLanguage.persian:
        return 'رویداد تکراری';
      case AppLanguage.english:
      default:
        return 'Recurring Event';
    }
  }

  String get recurrenceInterval {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungsintervall';
      case AppLanguage.turkish:
        return 'Tekrar Aralığı';
      case AppLanguage.arabic:
        return 'فترة التكرار';
      case AppLanguage.bosnian:
        return 'Interval ponavljanja';
      case AppLanguage.spanish:
        return 'Intervalo de recurrencia';
      case AppLanguage.persian:
        return 'فاصله تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence Interval';
    }
  }

  String get recurrenceRange {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungsbereich';
      case AppLanguage.turkish:
        return 'Tekrar Aralığı';
      case AppLanguage.arabic:
        return 'نطاق التكرار';
      case AppLanguage.bosnian:
        return 'Raspon ponavljanja';
      case AppLanguage.spanish:
        return 'Rango de recurrencia';
      case AppLanguage.persian:
        return 'محدوده تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence Range';
    }
  }

  String get recurrenceCount {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungsanzahl';
      case AppLanguage.turkish:
        return 'Tekrar Sayısı';
      case AppLanguage.arabic:
        return 'عدد التكرارات';
      case AppLanguage.bosnian:
        return 'Broj ponavljanja';
      case AppLanguage.spanish:
        return 'Conteo de recurrencias';
      case AppLanguage.persian:
        return 'تعداد تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence Count';
    }
  }

  String get recurrenceEndDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungsenddatum';
      case AppLanguage.turkish:
        return 'Tekrar Bitiş Tarihi';
      case AppLanguage.arabic:
        return 'تاريخ انتهاء التكرار';
      case AppLanguage.bosnian:
        return 'Datum završetka ponavljanja';
      case AppLanguage.spanish:
        return 'Fecha de fin de recurrencia';
      case AppLanguage.persian:
        return 'تاریخ پایان تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence End Date';
    }
  }

  String get selectEndDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Enddatum wählen';
      case AppLanguage.turkish:
        return 'Bitiş Tarihi Seç';
      case AppLanguage.arabic:
        return 'اختر تاريخ الانتهاء';
      case AppLanguage.bosnian:
        return 'Izaberi datum završetka';
      case AppLanguage.spanish:
        return 'Seleccionar fecha de finalización';
      case AppLanguage.persian:
        return 'انتخاب تاریخ پایان';
      case AppLanguage.english:
      default:
        return 'Select End Date';
    }
  }

  String get recurrenceDays {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wochentage der Wiederholung';
      case AppLanguage.turkish:
        return 'Tekrar Günleri';
      case AppLanguage.arabic:
        return 'أيام التكرار';
      case AppLanguage.bosnian:
        return 'Dani ponavljanja';
      case AppLanguage.spanish:
        return 'Días de recurrencia';
      case AppLanguage.persian:
        return 'روزهای تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence Days';
    }
  }

  String get addExceptionDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ausnahmedatum hinzufügen';
      case AppLanguage.turkish:
        return 'İstisna Tarih Ekle';
      case AppLanguage.arabic:
        return 'إضافة تاريخ استثناء';
      case AppLanguage.bosnian:
        return 'Dodaj datum izuzetka';
      case AppLanguage.spanish:
        return 'Añadir fecha de excepción';
      case AppLanguage.persian:
        return 'اضافه کردن تاریخ استثناء';
      case AppLanguage.english:
      default:
        return 'Add Exception Date';
    }
  }

  String get appointmentColor {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Terminfarbe';
      case AppLanguage.turkish:
        return 'Randevu Rengi';
      case AppLanguage.arabic:
        return 'لون الموعد';
      case AppLanguage.bosnian:
        return 'Boja termina';
      case AppLanguage.spanish:
        return 'Color de la cita';
      case AppLanguage.persian:
        return 'رنگ قرار';
      case AppLanguage.english:
      default:
        return 'Appointment Color';
    }
  }

  String get deleteAppointmentTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termin löschen';
      case AppLanguage.turkish:
        return 'Randevuyu Sil';
      case AppLanguage.arabic:
        return 'حذف الموعد';
      case AppLanguage.bosnian:
        return 'Izbriši termin';
      case AppLanguage.spanish:
        return 'Eliminar cita';
      case AppLanguage.persian:
        return 'حذف قرار';
      case AppLanguage.english:
      default:
        return 'Delete Appointment';
    }
  }

  String get deleteAppointmentConfirmation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Sind Sie sicher, dass Sie diesen Termin löschen möchten?';
      case AppLanguage.turkish:
        return 'Bu randevuyu silmek istediğinize emin misiniz?';
      case AppLanguage.arabic:
        return 'هل أنت متأكد أنك تريد حذف هذا الموعد؟';
      case AppLanguage.bosnian:
        return 'Jeste li sigurni da želite izbrisati ovaj termin?';
      case AppLanguage.spanish:
        return '¿Está seguro de que desea eliminar esta cita?';
      case AppLanguage.persian:
        return 'آیا مطمئن هستید که می‌خواهید این قرار را حذف کنید؟';
      case AppLanguage.english:
      default:
        return 'Are you sure you want to delete this appointment?';
    }
  }

  String get cancel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Abbrechen';
      case AppLanguage.turkish:
        return 'İptal';
      case AppLanguage.arabic:
        return 'إلغاء';
      case AppLanguage.bosnian:
        return 'Otkaži';
      case AppLanguage.spanish:
        return 'Cancelar';
      case AppLanguage.persian:
        return 'لغو';
      case AppLanguage.english:
      default:
        return 'Cancel';
    }
  }

  String get select {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Auswählen';
      case AppLanguage.turkish:
        return 'Seç';
      case AppLanguage.arabic:
        return 'اختر';
      case AppLanguage.bosnian:
        return 'Izaberi';
      case AppLanguage.spanish:
        return 'Seleccionar';
      case AppLanguage.persian:
        return 'انتخاب';
      case AppLanguage.english:
      default:
        return 'Select';
    }
  }

// >>> Getter für "filterCategories"
  String get filterCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kategorien filtern';
      case AppLanguage.turkish:
        return 'Kategorileri Filtrele';
      case AppLanguage.arabic:
        return 'تصفية الفئات';
      case AppLanguage.bosnian:
        return 'Filtriraj kategorije';
      case AppLanguage.spanish:
        return 'Filtrar categorías';
      case AppLanguage.persian:
        return 'فیلتر کردن دسته‌ها';
      case AppLanguage.english:
      default:
        return 'Filter Categories';
    }
  }

  // >>> Getter für "addNewCategory"
  String get addNewCategory {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '+ Neue Kategorie';
      case AppLanguage.turkish:
        return '+ Yeni Kategori';
      case AppLanguage.arabic:
        return '+ فئة جديدة';
      case AppLanguage.bosnian:
        return '+ Nova kategorija';
      case AppLanguage.spanish:
        return '+ Nueva categoría';
      case AppLanguage.persian:
        return '+ دسته جدید';
      case AppLanguage.english:
      default:
        return '+ New Category';
    }
  }

  // >>> Getter für "apply"
  String get apply {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Übernehmen';
      case AppLanguage.turkish:
        return 'Uygula';
      case AppLanguage.arabic:
        return 'تطبيق';
      case AppLanguage.bosnian:
        return 'Primijeni';
      case AppLanguage.spanish:
        return 'Aplicar';
      case AppLanguage.persian:
        return 'اعمال';
      case AppLanguage.english:
      default:
        return 'Apply';
    }
  }

  // >>> Getter für "dashboard"
  String get dashboard {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Übersicht';
      case AppLanguage.turkish:
        return 'Gösterge Paneli';
      case AppLanguage.arabic:
        return 'لوحة التحكم';
      case AppLanguage.bosnian:
        return 'Kontrolna ploča';
      case AppLanguage.spanish:
        return 'Tablero';
      case AppLanguage.persian:
        return 'داشبورد';
      case AppLanguage.english:
      default:
        return 'Dashboard';
    }
  }

  // >>> Getter für "addNewAppointment"
  String get addNewAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Neuen Termin hinzufügen';
      case AppLanguage.turkish:
        return 'Yeni Randevu Ekle';
      case AppLanguage.arabic:
        return 'أضف موعدًا جديدًا';
      case AppLanguage.bosnian:
        return 'Dodaj novi termin';
      case AppLanguage.spanish:
        return 'Añadir nueva cita';
      case AppLanguage.persian:
        return 'قرار جدید اضافه کن';
      case AppLanguage.english:
      default:
        return 'Add New Appointment';
    }
  }

  String get prayerTimeSlots {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten-Slots';
      case AppLanguage.turkish:
        return 'Namaz vakti aralıkları';
      case AppLanguage.arabic:
        return 'فترات أوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Termini vremena namaza';
      case AppLanguage.spanish:
        return 'Intervalos de tiempos de oración';
      case AppLanguage.persian:
        return 'بازه‌های اوقات نماز';
      case AppLanguage.english:
      default:
        return 'Prayer time slots';
    }
  }

  String get prayerTimeSlotsInDashboard {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten-Slots im Dashboard';
      case AppLanguage.turkish:
        return 'Dashboard\'da namaz vakti aralıkları';
      case AppLanguage.arabic:
        return 'فترات أوقات الصلاة في لوحة التحكم';
      case AppLanguage.bosnian:
        return 'Termini vremena namaza na kontrolnoj ploči';
      case AppLanguage.spanish:
        return 'Intervalos de tiempos de oración en el tablero';
      case AppLanguage.persian:
        return 'بازه‌های اوقات نماز در داشبورد';
      case AppLanguage.english:
      default:
        return 'Prayer time slots in the dashboard';
    }
  }

  String get useSystemTheme {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'System-Theme verwenden';
      case AppLanguage.turkish:
        return 'Sistem temasını kullan';
      case AppLanguage.arabic:
        return 'استخدام سمة النظام';
      case AppLanguage.bosnian:
        return 'Koristi sistemsku temu';
      case AppLanguage.spanish:
        return 'Usar tema del sistema';
      case AppLanguage.persian:
        return 'استفاده از تم سیستم';
      case AppLanguage.english:
      default:
        return 'Use system theme';
    }
  }

  String get autoSwitchDarkLightMode {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Automatisch auf Dunkel/Hell schalten, wenn das Gerät in den Nachtmodus wechselt';
      case AppLanguage.turkish:
        return 'Cihaz gece moduna geçtiğinde otomatik olarak karanlık/açık moda geç';
      case AppLanguage.arabic:
        return 'التبديل تلقائيًا إلى الوضع الداكن/الفاتح عند انتقال الجهاز إلى الوضع الليلي';
      case AppLanguage.bosnian:
        return 'Automatski prebacite na tamnu/svijetlu temu kada uređaj uđe u noćni mod';
      case AppLanguage.spanish:
        return 'Cambiar automáticamente a modo oscuro/claro cuando el dispositivo cambia al modo nocturno';
      case AppLanguage.persian:
        return 'به طور خودکار به حالت تاریک/روشن تغییر دهید وقتی دستگاه به حالت شب می‌رود';
      case AppLanguage.english:
      default:
        return 'Automatically switch to dark/light mode when the device switches to night mode';
    }
  }

  String get showTodayPrayerTimesAsSlots {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zeigt die heutigen Gebetszeiten zusätzlich als Slots im Dashboard an';
      case AppLanguage.turkish:
        return 'Bugünün namaz vakitlerini ek olarak Dashboard\'da aralıklar olarak gösterir';
      case AppLanguage.arabic:
        return 'يعرض أوقات الصلاة اليوم كفتحات إضافية في لوحة التحكم';
      case AppLanguage.bosnian:
        return 'Prikazuje današnja vremena namaza kao termine na kontrolnoj ploči';
      case AppLanguage.spanish:
        return 'Muestra los tiempos de oración de hoy adicionalmente como intervalos en el tablero';
      case AppLanguage.persian:
        return 'اوقات نماز امروز را به عنوان بازه‌ها در داشبورد نشان می‌دهد';
      case AppLanguage.english:
      default:
        return 'Displays today\'s prayer times additionally as slots in the dashboard';
    }
  }

  String get showPrayerTimesInDailyView {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten in Daily-View anzeigen';
      case AppLanguage.turkish:
        return 'Namaz vakitlerini günlük görünümde göster';
      case AppLanguage.arabic:
        return 'عرض أوقات الصلاة في العرض اليومي';
      case AppLanguage.bosnian:
        return 'Prikaz vremena namaza u dnevnom pogledu';
      case AppLanguage.spanish:
        return 'Mostrar tiempos de oración en vista diaria';
      case AppLanguage.persian:
        return 'اوقات نماز را در نمای روزانه نمایش بده';
      case AppLanguage.english:
      default:
        return 'Show prayer times in daily view';
    }
  }

  String get showPrayerTimesInWeeklyView {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten in der Wochenansicht anzeigen';
      case AppLanguage.turkish:
        return 'Namaz vakitlerini haftalık görünümde göster';
      case AppLanguage.arabic:
        return 'عرض أوقات الصلاة في العرض الأسبوعي';
      case AppLanguage.bosnian:
        return 'Prikaz vremena namaza u sedmičnom pogledu';
      case AppLanguage.spanish:
        return 'Mostrar tiempos de oración en vista semanal';
      case AppLanguage.persian:
        return 'اوقات نماز را در نمای هفتگی نمایش بده';
      case AppLanguage.english:
      default:
        return 'Show prayer times in weekly view';
    }
  }

  String get prayerTimesCalculation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten-Berechnung';
      case AppLanguage.turkish:
        return 'Namaz vakti hesaplama';
      case AppLanguage.arabic:
        return 'حساب أوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Izračun vremena namaza';
      case AppLanguage.spanish:
        return 'Cálculo de tiempos de oración';
      case AppLanguage.persian:
        return 'محاسبه اوقات نماز';
      case AppLanguage.english:
      default:
        return 'Prayer times calculation';
    }
  }

  String get calculationMethod {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kalkulationsmethode';
      case AppLanguage.turkish:
        return 'Hesaplama yöntemi';
      case AppLanguage.arabic:
        return 'طريقة الحساب';
      case AppLanguage.bosnian:
        return 'Metoda izračuna';
      case AppLanguage.spanish:
        return 'Método de cálculo';
      case AppLanguage.persian:
        return 'روش محاسبه';
      case AppLanguage.english:
      default:
        return 'Calculation method';
    }
  }

  String get errorLoadingCountryList {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Laden der Länderliste:';
      case AppLanguage.turkish:
        return 'Ülke listesi yüklenirken hata oluştu:';
      case AppLanguage.arabic:
        return 'حدث خطأ أثناء تحميل قائمة الدول:';
      case AppLanguage.bosnian:
        return 'Greška pri učitavanju liste zemalja:';
      case AppLanguage.spanish:
        return 'Error al cargar la lista de países:';
      case AppLanguage.persian:
        return 'خطا در بارگیری لیست کشورها:';
      case AppLanguage.english:
      default:
        return 'Error loading country list:';
    }
  }

  String get startDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Startdatum';
      case AppLanguage.turkish:
        return 'Başlangıç tarihi';
      case AppLanguage.arabic:
        return 'تاريخ البدء';
      case AppLanguage.bosnian:
        return 'Datum početka';
      case AppLanguage.spanish:
        return 'Fecha de inicio';
      case AppLanguage.persian:
        return 'تاریخ شروع';
      case AppLanguage.english:
      default:
        return 'Start date';
    }
  }

  String get date {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Datum';
      case AppLanguage.turkish:
        return 'Tarih';
      case AppLanguage.arabic:
        return 'التاريخ';
      case AppLanguage.bosnian:
        return 'Datum';
      case AppLanguage.spanish:
        return 'Fecha';
      case AppLanguage.persian:
        return 'تاریخ';
      case AppLanguage.english:
      default:
        return 'Date';
    }
  }

  String get time {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zeit';
      case AppLanguage.turkish:
        return 'Saat';
      case AppLanguage.arabic:
        return 'الوقت';
      case AppLanguage.bosnian:
        return 'Vrijeme';
      case AppLanguage.spanish:
        return 'Hora';
      case AppLanguage.persian:
        return 'زمان';
      case AppLanguage.english:
      default:
        return 'Time';
    }
  }

  String get qiblaCompassTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Qibla Kompass';
      case AppLanguage.turkish:
        return 'Kıble Pusulası';
      case AppLanguage.arabic:
        return 'بوصلة القبلة';
      case AppLanguage.bosnian:
        return 'Kibla kompas';
      case AppLanguage.spanish:
        return 'Brújula Qibla';
      case AppLanguage.persian:
        return 'قطب نما قبله';
      case AppLanguage.english:
      default:
        return 'Qibla Compass';
    }
  }

  String get permissionDeniedMessage {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Die Standortberechtigung wurde verweigert.\nBitte erteile die Berechtigung, um den Kompass nutzen zu können.';
      case AppLanguage.turkish:
        return 'Konum izni reddedildi.\nPusulayı kullanmak için izin vermelisiniz.';
      case AppLanguage.arabic:
        return 'تم رفض إذن الموقع.\nيرجى منح الإذن لاستخدام البوصلة.';
      case AppLanguage.bosnian:
        return 'Dozvola za pristup lokaciji je odbijena.\nMolimo odobrite dozvolu za korištenje kompasa.';
      case AppLanguage.spanish:
        return 'El permiso de ubicación fue denegado.\nPor favor, otorgue permiso para usar la brújula.';
      case AppLanguage.persian:
        return 'دسترسی به مکان رد شد.\nلطفاً اجازه استفاده از قطب نما را بدهید.';
      case AppLanguage.english:
      default:
        return 'Location permission was denied.\nPlease grant permission to use the compass.';
    }
  }

  String get deviceNotSupportedMessage {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ihr Gerät unterstützt den Kompass nicht.';
      case AppLanguage.turkish:
        return 'Cihazınız pusula desteklemiyor.';
      case AppLanguage.arabic:
        return 'جهازك لا يدعم البوصلة.';
      case AppLanguage.bosnian:
        return 'Vaš uređaj ne podržava kompas.';
      case AppLanguage.spanish:
        return 'Su dispositivo no soporta la brújula.';
      case AppLanguage.persian:
        return 'دستگاه شما از قطب نما پشتیبانی نمی‌کند.';
      case AppLanguage.english:
      default:
        return 'Your device does not support the compass.';
    }
  }

  String get fetchingQiblaErrorMessage {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Abrufen der Qibla-Richtung';
      case AppLanguage.turkish:
        return 'Kıble yönü alınırken hata oluştu';
      case AppLanguage.arabic:
        return 'حدث خطأ أثناء جلب اتجاه القبلة';
      case AppLanguage.bosnian:
        return 'Greška pri dohvaćanju smjera kible';
      case AppLanguage.spanish:
        return 'Error al obtener la dirección de la Qibla';
      case AppLanguage.persian:
        return 'خطا در دریافت جهت قبله';
      case AppLanguage.english:
      default:
        return 'Error fetching Qibla direction';
    }
  }

  String get qiblaDirectionText {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Qibla Richtung';
      case AppLanguage.turkish:
        return 'Kıble Yönü';
      case AppLanguage.arabic:
        return 'اتجاه القبلة';
      case AppLanguage.bosnian:
        return 'Smjer kible';
      case AppLanguage.spanish:
        return 'Dirección de la Qibla';
      case AppLanguage.persian:
        return 'جهت قبله';
      case AppLanguage.english:
      default:
        return 'Qibla Direction';
    }
  }

  String get welcome {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Willkommen!";
      case AppLanguage.turkish:
        return "Hoşgeldiniz!";
      case AppLanguage.arabic:
        return "مرحبًا!";
      case AppLanguage.bosnian:
        return "Dobrodošli!";
      case AppLanguage.spanish:
        return "¡Bienvenido!";
      case AppLanguage.persian:
        return "خوش آمدید!";
      case AppLanguage.english:
      default:
        return "Welcome!";
    }
  }

  String get initialInstructions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bitte wähle deine Einstellungen aus, damit die App optimal funktioniert.";
      case AppLanguage.turkish:
        return "Lütfen uygulamanın en iyi şekilde çalışması için ayarlarını seçin.";
      case AppLanguage.arabic:
        return "يرجى اختيار إعداداتك حتى تعمل التطبيق بشكل مثالي.";
      case AppLanguage.bosnian:
        return "Molimo odaberite svoje postavke kako bi aplikacija radila optimalno.";
      case AppLanguage.spanish:
        return "Por favor, elija sus configuraciones para que la aplicación funcione de manera óptima.";
      case AppLanguage.persian:
        return "لطفاً تنظیمات خود را انتخاب کنید تا برنامه به بهترین نحو کار کند.";
      case AppLanguage.english:
      default:
        return "Please choose your settings so that the app functions optimally.";
    }
  }

  String get locationInstructions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bitte wähle deinen Standort aus, damit die Gebetszeiten korrekt berechnet werden können.";
      case AppLanguage.turkish:
        return "Namaz vakitlerinin doğru hesaplanabilmesi için lütfen konumunuzu seçin.";
      case AppLanguage.arabic:
        return "يرجى اختيار موقعك حتى يتم حساب مواقيت الصلاة بشكل صحيح.";
      case AppLanguage.bosnian:
        return "Molimo odaberite svoju lokaciju kako bi vremena namaza bila tačno izračunata.";
      case AppLanguage.spanish:
        return "Por favor, seleccione su ubicación para que los tiempos de oración se calculen correctamente.";
      case AppLanguage.persian:
        return "لطفاً مکان خود را انتخاب کنید تا اوقات نماز به درستی محاسبه شود.";
      case AppLanguage.english:
      default:
        return "Please select your location so that the prayer times can be calculated correctly.";
    }
  }

  String get finish {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Fertig";
      case AppLanguage.turkish:
        return "Tamam";
      case AppLanguage.arabic:
        return "تم";
      case AppLanguage.bosnian:
        return "Gotovo";
      case AppLanguage.spanish:
        return "Finalizar";
      case AppLanguage.persian:
        return "پایان";
      case AppLanguage.english:
      default:
        return "Finish";
    }
  }

  String get reminderInMinutes {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erinnerung (Minuten vorher)';
      case AppLanguage.turkish:
        return 'Hatırlatma (Dakika önce)';
      case AppLanguage.arabic:
        return 'تذكير (دقائق قبل)';
      case AppLanguage.bosnian:
        return 'Podsjetnik (minuta prije)';
      case AppLanguage.spanish:
        return 'Recordatorio (minutos antes)';
      case AppLanguage.persian:
        return 'یادآوری (دقیقه قبل)';
      case AppLanguage.english:
      default:
        return 'Reminder (min. before)';
    }
  }

  String get noReminder {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Keine Erinnerung';
      case AppLanguage.turkish:
        return 'Hatırlatma Yok';
      case AppLanguage.arabic:
        return 'بدون تذكير';
      case AppLanguage.bosnian:
        return 'Nema podsjetnika';
      case AppLanguage.spanish:
        return 'Sin recordatorio';
      case AppLanguage.persian:
        return 'بدون یادآوری';
      case AppLanguage.english:
      default:
        return 'No Reminder';
    }
  }

  String minutesBefore(int val) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '$val Min. vorher';
      case AppLanguage.turkish:
        return '$val Dakika önce';
      case AppLanguage.arabic:
        return '$val دقيقة قبل';
      case AppLanguage.bosnian:
        return '$val min. prije';
      case AppLanguage.spanish:
        return '$val min. antes';
      case AppLanguage.persian:
        return '$val دقیقه قبل';
      case AppLanguage.english:
      default:
        return '$val min. before';
    }
  }

  String hoursBefore(int h) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '$h Std. vorher';
      case AppLanguage.turkish:
        return '$h Saat önce';
      case AppLanguage.arabic:
        return '$h ساعة قبل';
      case AppLanguage.bosnian:
        return '$h sat prije';
      case AppLanguage.spanish:
        return '$h hr before';
      case AppLanguage.persian:
        return '$h ساعت قبل';
      case AppLanguage.english:
      default:
        return '$h hr before';
    }
  }

  String daysBefore(int d) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '$d Tag(e) vorher';
      case AppLanguage.turkish:
        return '$d Gün önce';
      case AppLanguage.arabic:
        return '$d يوم قبل';
      case AppLanguage.bosnian:
        return '$d dan prije';
      case AppLanguage.spanish:
        return '$d d before';
      case AppLanguage.persian:
        return '$d روز قبل';
      case AppLanguage.english:
      default:
        return '$d day(s) before';
    }
  }

  String get selectCategoryLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kategorie wählen';
      case AppLanguage.turkish:
        return 'Kategori seçiniz';
      case AppLanguage.arabic:
        return 'اختر الفئة';
      case AppLanguage.bosnian:
        return 'Izaberi kategoriju';
      case AppLanguage.spanish:
        return 'Seleccionar categoría';
      case AppLanguage.persian:
        return 'انتخاب دسته';
      case AppLanguage.english:
      default:
        return 'Select Category';
    }
  }

  String get fewerOptions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Weniger Optionen';
      case AppLanguage.turkish:
        return 'Daha Az Seçenek';
      case AppLanguage.arabic:
        return 'خيارات أقل';
      case AppLanguage.bosnian:
        return 'Manje opcija';
      case AppLanguage.spanish:
        return 'Menos opciones';
      case AppLanguage.persian:
        return 'گزینه‌های کمتر';
      case AppLanguage.english:
      default:
        return 'Fewer Options';
    }
  }

  String get advancedOptions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erweiterte Optionen';
      case AppLanguage.turkish:
        return 'Gelişmiş Seçenekler';
      case AppLanguage.arabic:
        return 'خيارات متقدمة';
      case AppLanguage.bosnian:
        return 'Napredne opcije';
      case AppLanguage.spanish:
        return 'Opciones avanzadas';
      case AppLanguage.persian:
        return 'گزینه‌های پیشرفته';
      case AppLanguage.english:
      default:
        return 'Advanced Options';
    }
  }

  String getRecurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Täglich';
          case AppLanguage.turkish:
            return 'Günlük';
          case AppLanguage.arabic:
            return 'يومي';
          case AppLanguage.bosnian:
            return 'Dnevno';
          case AppLanguage.spanish:
            return 'Diario';
          case AppLanguage.persian:
            return 'روزانه';
          case AppLanguage.english:
          default:
            return 'Daily';
        }
      case RecurrenceType.weekly:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Wöchentlich';
          case AppLanguage.turkish:
            return 'Haftalık';
          case AppLanguage.arabic:
            return 'أسبوعي';
          case AppLanguage.bosnian:
            return 'Sedmično';
          case AppLanguage.spanish:
            return 'Semanal';
          case AppLanguage.persian:
            return 'هفتگی';
          case AppLanguage.english:
          default:
            return 'Weekly';
        }
      case RecurrenceType.monthly:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Monatlich';
          case AppLanguage.turkish:
            return 'Aylık';
          case AppLanguage.arabic:
            return 'شهري';
          case AppLanguage.bosnian:
            return 'Mjesečno';
          case AppLanguage.spanish:
            return 'Mensual';
          case AppLanguage.persian:
            return 'ماهانه';
          case AppLanguage.english:
          default:
            return 'Monthly';
        }
      case RecurrenceType.yearly:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Jährlich';
          case AppLanguage.turkish:
            return 'Yıllık';
          case AppLanguage.arabic:
            return 'سنوي';
          case AppLanguage.bosnian:
            return 'Godišnje';
          case AppLanguage.spanish:
            return 'Anual';
          case AppLanguage.persian:
            return 'سالانه';
          case AppLanguage.english:
          default:
            return 'Yearly';
        }
    }
  }

  String getRecurrenceRangeLabel(RecurrenceRange range) {
    switch (range) {
      case RecurrenceRange.noEndDate:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Ohne Enddatum';
          case AppLanguage.turkish:
            return 'Bitiş Tarihi Yok';
          case AppLanguage.arabic:
            return 'بدون تاريخ انتهاء';
          case AppLanguage.bosnian:
            return 'Bez završetka';
          case AppLanguage.spanish:
            return 'Sin fecha de fin';
          case AppLanguage.persian:
            return 'بدون تاریخ پایان';
          case AppLanguage.english:
          default:
            return 'No End Date';
        }
      case RecurrenceRange.endDate:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Endet an einem bestimmten Datum';
          case AppLanguage.turkish:
            return 'Belirli bir tarihte sona erer';
          case AppLanguage.arabic:
            return 'ينتهي بتاريخ معين';
          case AppLanguage.bosnian:
            return 'Završava na određeni datum';
          case AppLanguage.spanish:
            return 'Termina en una fecha específica';
          case AppLanguage.persian:
            return 'در تاریخ مشخصی پایان می‌یابد';
          case AppLanguage.english:
          default:
            return 'Ends on a Specific Date';
        }
      case RecurrenceRange.count:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Endet nach einer Anzahl';
          case AppLanguage.turkish:
            return 'Belirli sayıda sona erer';
          case AppLanguage.arabic:
            return 'ينتهي بعد عدد محدد';
          case AppLanguage.bosnian:
            return 'Završava nakon određenog broja ponavljanja';
          case AppLanguage.spanish:
            return 'Termina después de un número';
          case AppLanguage.persian:
            return 'پس از تعداد مشخصی پایان می‌یابد';
          case AppLanguage.english:
          default:
            return 'Ends After Count';
        }
    }
  }

  String get upcomingTasksLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termine heute';
      case AppLanguage.turkish:
        return 'Bugünkü randevular';
      case AppLanguage.arabic:
        return 'المواعيد القادمة';
      case AppLanguage.bosnian:
        return 'Današnji termini';
      case AppLanguage.spanish:
        return 'Citas de hoy';
      case AppLanguage.persian:
        return 'قرارهای امروز';
      case AppLanguage.english:
      default:
        return 'Appointments today';
    }
  }

  String get timeFormat24 {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '24-Stunden-Format';
      case AppLanguage.turkish:
        return '24 Saat Formatı';
      case AppLanguage.arabic:
        return 'تنسيق 24 ساعة';
      case AppLanguage.bosnian:
        return '24-satni format';
      case AppLanguage.spanish:
        return 'Formato de 24 horas';
      case AppLanguage.persian:
        return 'فرمت 24 ساعته';
      case AppLanguage.english:
      default:
        return '24-hour format';
    }
  }

  String get timeFormat24Active {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Aktuell ist das 24h-Format aktiv';
      case AppLanguage.turkish:
        return 'Şu anda 24 saat formatı etkin';
      case AppLanguage.arabic:
        return 'حاليًا يتم استخدام تنسيق 24 ساعة';
      case AppLanguage.bosnian:
        return 'Trenutno je aktivan 24-satni format';
      case AppLanguage.spanish:
        return 'Actualmente, el formato de 24 horas está activo';
      case AppLanguage.persian:
        return 'در حال حاضر، فرمت 24 ساعته فعال است';
      case AppLanguage.english:
      default:
        return 'Currently, 24-hour format is active';
    }
  }

  String get timeFormatAmPmActive {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Aktuell ist das AM/PM-Format aktiv';
      case AppLanguage.turkish:
        return 'Şu anda AM/PM formatı etkin';
      case AppLanguage.arabic:
        return 'حاليًا يتم استخدام تنسيق ص/م';
      case AppLanguage.bosnian:
        return 'Trenutno je aktivan AM/PM format';
      case AppLanguage.spanish:
        return 'Actualmente, el formato AM/PM está activo';
      case AppLanguage.persian:
        return 'در حال حاضر، فرمت AM/PM فعال است';
      case AppLanguage.english:
      default:
        return 'Currently, AM/PM format is active';
    }
  }

  String get language {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Sprache';
      case AppLanguage.turkish:
        return 'Dil';
      case AppLanguage.arabic:
        return 'اللغة';
      case AppLanguage.bosnian:
        return 'Jezik';
      case AppLanguage.spanish:
        return 'Idioma';
      case AppLanguage.persian:
        return 'زبان';
      case AppLanguage.english:
      default:
        return 'Language';
    }
  }

  String get weather {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wetter';
      case AppLanguage.turkish:
        return 'Hava';
      case AppLanguage.arabic:
        return 'الطقس';
      case AppLanguage.bosnian:
        return 'Vrijeme';
      case AppLanguage.spanish:
        return 'Tiempo';
      case AppLanguage.persian:
        return 'آب و هوا';
      case AppLanguage.english:
      default:
        return 'Weather';
    }
  }

  String get automaticLocationSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bestimmt Ihren Standort per GPS';
      case AppLanguage.turkish:
        return 'Konumu GPS üzerinden belirler';
      case AppLanguage.arabic:
        return 'يحدد موقعك عبر GPS';
      case AppLanguage.bosnian:
        return 'Određuje vašu lokaciju putem GPS-a';
      case AppLanguage.spanish:
        return 'Determina tu ubicación mediante GPS';
      case AppLanguage.persian:
        return 'مکان شما را از طریق GPS تعیین می‌کند';
      case AppLanguage.english:
      default:
        return 'Determines your location via GPS';
    }
  }

  String get automaticLocation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Automatischer Standort';
      case AppLanguage.turkish:
        return 'Otomatik Konum';
      case AppLanguage.arabic:
        return 'الموقع التلقائي';
      case AppLanguage.bosnian:
        return 'Automatska lokacija';
      case AppLanguage.spanish:
        return 'Ubicación automática';
      case AppLanguage.persian:
        return 'مکان خودکار';
      case AppLanguage.english:
      default:
        return 'Automatic Location';
    }
  }

  String get locationSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Standort-Einstellungen';
      case AppLanguage.turkish:
        return 'Konum Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات الموقع';
      case AppLanguage.bosnian:
        return 'Postavke lokacije';
      case AppLanguage.spanish:
        return 'Configuración de ubicación';
      case AppLanguage.persian:
        return 'تنظیمات مکان';
      case AppLanguage.english:
      default:
        return 'Location Settings';
    }
  }

  String get timeFormat {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Zeitformat';
      case AppLanguage.turkish:
        return 'Zaman Formatı';
      case AppLanguage.arabic:
        return 'تنسيق الوقت';
      case AppLanguage.bosnian:
        return 'Format vremena';
      case AppLanguage.spanish:
        return 'Formato de hora';
      case AppLanguage.persian:
        return 'فرمت زمان';
      case AppLanguage.english:
      default:
        return 'Time Format';
    }
  }

  String get enableNotifications {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Benachrichtigungen aktivieren';
      case AppLanguage.turkish:
        return 'Bildirimleri Etkinleştir';
      case AppLanguage.arabic:
        return 'تفعيل الإشعارات';
      case AppLanguage.bosnian:
        return 'Omogući obavještenja';
      case AppLanguage.spanish:
        return 'Activar notificaciones';
      case AppLanguage.persian:
        return 'اعلان‌ها را فعال کن';
      case AppLanguage.english:
      default:
        return 'Enable Notifications';
    }
  }

  String get enableNotificationsSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erhalten Sie Mitteilungen zu Terminen und Gebetszeiten';
      case AppLanguage.turkish:
        return 'Randevular ve namaz vakitleriyle ilgili bildirimler alın';
      case AppLanguage.arabic:
        return 'تلقي إشعارات بالمواعيد وأوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Primajte obavještenja o terminima i vremenima namaza';
      case AppLanguage.spanish:
        return 'Recibe notificaciones sobre citas y tiempos de oración';
      case AppLanguage.persian:
        return 'اطلاعیه‌های مربوط به قرارها و اوقات نماز را دریافت کنید';
      case AppLanguage.english:
      default:
        return 'Receive alerts for appointments and prayer times';
    }
  }

  String get darkMode {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Dunkler Modus';
      case AppLanguage.turkish:
        return 'Karanlık Mod';
      case AppLanguage.arabic:
        return 'الوضع الداكن';
      case AppLanguage.bosnian:
        return 'Tamni način';
      case AppLanguage.spanish:
        return 'Modo oscuro';
      case AppLanguage.persian:
        return 'حالت تاریک';
      case AppLanguage.english:
      default:
        return 'Dark Mode';
    }
  }

  String get darkModeSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Aktivieren Sie das dunkle Design';
      case AppLanguage.turkish:
        return 'Koyu temayı etkinleştirin';
      case AppLanguage.arabic:
        return 'تفعيل المظهر الداكن';
      case AppLanguage.bosnian:
        return 'Uključite tamni način rada';
      case AppLanguage.spanish:
        return 'Habilitar el modo oscuro';
      case AppLanguage.persian:
        return 'حالت تاریک را فعال کنید';
      case AppLanguage.english:
      default:
        return 'Enable dark theme';
    }
  }

  String get errorLoadingAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Laden des Termins';
      case AppLanguage.turkish:
        return 'Randevu yüklenirken hata oluştu';
      case AppLanguage.arabic:
        return 'حدث خطأ أثناء تحميل الموعد';
      case AppLanguage.bosnian:
        return 'Greška pri učitavanju termina';
      case AppLanguage.spanish:
        return 'Error al cargar la cita';
      case AppLanguage.persian:
        return 'خطا در بارگیری قرار';
      case AppLanguage.english:
      default:
        return 'Error loading appointment';
    }
  }

  String get noAppointmentToDelete {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kein Termin zum Löschen vorhanden.';
      case AppLanguage.turkish:
        return 'Silinecek randevu bulunamadı.';
      case AppLanguage.arabic:
        return 'لا يوجد موعد للحذف.';
      case AppLanguage.bosnian:
        return 'Nema termina za brisanje.';
      case AppLanguage.spanish:
        return 'No hay cita para eliminar.';
      case AppLanguage.persian:
        return 'هیچ قراردادی برای حذف وجود ندارد.';
      case AppLanguage.english:
      default:
        return 'No appointment to delete.';
    }
  }

  String get appointmentDeletedSuccessfully {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termin erfolgreich gelöscht.';
      case AppLanguage.turkish:
        return 'Randevu başarıyla silindi.';
      case AppLanguage.arabic:
        return 'تم حذف الموعد بنجاح.';
      case AppLanguage.bosnian:
        return 'Termin uspješno izbrisan.';
      case AppLanguage.spanish:
        return 'Cita eliminada con éxito.';
      case AppLanguage.persian:
        return 'قرار با موفقیت حذف شد.';
      case AppLanguage.english:
      default:
        return 'Appointment deleted successfully.';
    }
  }

  String get errorDeletingAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Löschen des Termins.';
      case AppLanguage.turkish:
        return 'Randevu silinirken hata oluştu.';
      case AppLanguage.arabic:
        return 'حدث خطأ أثناء حذف الموعد.';
      case AppLanguage.bosnian:
        return 'Greška prilikom brisanja termina.';
      case AppLanguage.spanish:
        return 'Error al eliminar la cita.';
      case AppLanguage.persian:
        return 'خطا در حذف قرار.';
      case AppLanguage.english:
      default:
        return 'Error deleting appointment.';
    }
  }

  String get pleaseSelectStartTimeError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bitte wählen Sie eine Startzeit aus.';
      case AppLanguage.turkish:
        return 'Lütfen bir başlangıç zamanı seçin.';
      case AppLanguage.arabic:
        return 'من فضلك اختر وقت البدء.';
      case AppLanguage.bosnian:
        return 'Molimo odaberite vrijeme početka.';
      case AppLanguage.spanish:
        return 'Por favor, seleccione una hora de inicio.';
      case AppLanguage.persian:
        return 'لطفاً زمان شروع را انتخاب کنید.';
      case AppLanguage.english:
      default:
        return 'Please select a start time.';
    }
  }

  String get reminderTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erinnerung';
      case AppLanguage.turkish:
        return 'Hatırlatma';
      case AppLanguage.arabic:
        return 'تذكير';
      case AppLanguage.bosnian:
        return 'Podsjetnik';
      case AppLanguage.spanish:
        return 'Recordatorio';
      case AppLanguage.persian:
        return 'یادآوری';
      case AppLanguage.english:
      default:
        return 'Reminder';
    }
  }

  String get reminderBody {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Vergessen Sie Ihren Termin nicht!';
      case AppLanguage.turkish:
        return 'Randevunuzu unutmayın!';
      case AppLanguage.arabic:
        return 'لا تنس موعدك!';
      case AppLanguage.bosnian:
        return 'Ne zaboravite svoj termin!';
      case AppLanguage.spanish:
        return '¡No olvides tu cita!';
      case AppLanguage.persian:
        return 'قرار خود را فراموش نکنید!';
      case AppLanguage.english:
      default:
        return 'Don\'t forget your appointment!';
    }
  }

  String get errorSavingAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termin konnte nicht gespeichert werden.';
      case AppLanguage.turkish:
        return 'Randevu kaydedilemedi.';
      case AppLanguage.arabic:
        return 'تعذر حفظ الموعد.';
      case AppLanguage.bosnian:
        return 'Termin nije mogao biti sačuvan.';
      case AppLanguage.spanish:
        return 'No se pudo guardar la cita.';
      case AppLanguage.persian:
        return 'خطا در ذخیره قرار.';
      case AppLanguage.english:
      default:
        return 'Failed to save the appointment.';
    }
  }

  String get location {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ort';
      case AppLanguage.turkish:
        return 'Bölge';
      case AppLanguage.arabic:
        return 'الموقع';
      case AppLanguage.bosnian:
        return 'Lokacija';
      case AppLanguage.spanish:
        return 'Ubicación';
      case AppLanguage.persian:
        return 'مکان';
      case AppLanguage.english:
      default:
        return 'Location';
    }
  }
}
