// lib/localization/app_localizations.dart

import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:intl/intl.dart';

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
        return 'Minuten';
      case AppLanguage.turkish:
        return 'Dakika';
      case AppLanguage.arabic:
        return 'دقائق';
      case AppLanguage.bosnian:
        return 'Minute';
      case AppLanguage.spanish:
        return 'Minutos';
      case AppLanguage.persian:
        return 'دقیقه';
      case AppLanguage.english:
      default:
        return 'Minutes';
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
        return 'Select city';
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
        return "Zeiteinstellungen";
      case AppLanguage.turkish:
        return "Zaman Ayarları";
      case AppLanguage.arabic:
        return "إعدادات الوقت";
      case AppLanguage.bosnian:
        return "Postavke vremena";
      case AppLanguage.spanish:
        return "Configuración de tiempo";
      case AppLanguage.persian:
        return "تنظیمات زمان";
      case AppLanguage.english:
      default:
        return "Time Settings";
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

  String get selectRecurrenceType {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungstyp auswählen';
      case AppLanguage.turkish:
        return 'Tekrarlama Tipini Seç';
      case AppLanguage.arabic:
        return 'اختر نوع التكرار';
      case AppLanguage.bosnian:
        return 'Odaberite vrstu ponavljanja';
      case AppLanguage.spanish:
        return 'Seleccionar tipo de recurrencia';
      case AppLanguage.persian:
        return 'انتخاب نوع تکرار';
      case AppLanguage.english:
      default:
        return 'Select Recurrence Type';
    }
  }

  String get recurrenceEndDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Enddatum der Wiederholung';
      case AppLanguage.turkish:
        return 'Tekrarlama Bitiş Tarihi';
      case AppLanguage.arabic:
        return 'تاريخ انتهاء التكرار';
      case AppLanguage.bosnian:
        return 'Datum završetka ponavljanja';
      case AppLanguage.spanish:
        return 'Fecha de finalización de repetición';
      case AppLanguage.persian:
        return 'تاریخ پایان تکرار';
      case AppLanguage.english:
      default:
        return 'Recurrence End Date';
    }
  }

  String get recurrenceEndDateHint {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wählen Sie ein Enddatum für die Wiederholung';
      case AppLanguage.turkish:
        return 'Tekrarın sona ereceği tarihi seçin';
      case AppLanguage.arabic:
        return 'اختر تاريخ انتهاء التكرار';
      case AppLanguage.bosnian:
        return 'Odaberite datum završetka ponavljanja';
      case AppLanguage.spanish:
        return 'Seleccione una fecha de finalización para la repetición';
      case AppLanguage.persian:
        return 'تاریخ پایان تکرار را انتخاب کنید';
      case AppLanguage.english:
      default:
        return 'Select an end date for recurrence';
    }
  }

  String get recurrenceExceptionDates {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ausnahmedaten';
      case AppLanguage.turkish:
        return 'İstisna Tarihleri';
      case AppLanguage.arabic:
        return 'تواريخ الاستثناء';
      case AppLanguage.bosnian:
        return 'Dati izuzeća';
      case AppLanguage.spanish:
        return 'Fechas de excepción';
      case AppLanguage.persian:
        return 'تاریخ‌های استثنا';
      case AppLanguage.english:
      default:
        return 'Exception Dates';
    }
  }

  String get recurrenceExceptionDatesHint {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Tage wählen, an denen der Termin nicht stattfindet';
      case AppLanguage.turkish:
        return 'Etkinliğin gerçekleşmeyeceği günleri seçin';
      case AppLanguage.arabic:
        return 'اختر الأيام التي لن يتم فيها الحدث';
      case AppLanguage.bosnian:
        return 'Odaberite dane kada se događaj neće dogoditi';
      case AppLanguage.spanish:
        return 'Seleccione días en los que el evento no tendrá lugar';
      case AppLanguage.persian:
        return 'روزهایی را که رویداد اتفاق نمی‌افتد انتخاب کنید';
      case AppLanguage.english:
      default:
        return 'Select days when the event will not occur';
    }
  }

  String get addExceptionDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ausnahmedatum hinzufügen';
      case AppLanguage.turkish:
        return 'İstisna Tarihi Ekle';
      case AppLanguage.arabic:
        return 'إضافة تاريخ استثناء';
      case AppLanguage.bosnian:
        return 'Dodaj datum izuzeća';
      case AppLanguage.spanish:
        return 'Añadir fecha de excepción';
      case AppLanguage.persian:
        return 'افزودن تاریخ استثنا';
      case AppLanguage.english:
      default:
        return 'Add Exception Date';
    }
  }

  String get removeExceptionDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ausnahmedatum entfernen';
      case AppLanguage.turkish:
        return 'İstisna Tarihini Kaldır';
      case AppLanguage.arabic:
        return 'إزالة تاريخ الاستثناء';
      case AppLanguage.bosnian:
        return 'Ukloni datum izuzeća';
      case AppLanguage.spanish:
        return 'Eliminar fecha de excepción';
      case AppLanguage.persian:
        return 'حذف تاریخ استثنا';
      case AppLanguage.english:
      default:
        return 'Remove Exception Date';
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
        return "Abbrechen";
      case AppLanguage.turkish:
        return "İptal";
      case AppLanguage.arabic:
        return "إلغاء";
      case AppLanguage.bosnian:
        return "Otkaži";
      case AppLanguage.spanish:
        return "Cancelar";
      case AppLanguage.persian:
        return "لغو";
      case AppLanguage.english:
      default:
        return "Cancel";
    }
  }

  String get select {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Auswählen";
      case AppLanguage.turkish:
        return "Seç";
      case AppLanguage.arabic:
        return "اختر";
      case AppLanguage.bosnian:
        return "Izaberi";
      case AppLanguage.spanish:
        return "Seleccionar";
      case AppLanguage.persian:
        return "انتخاب";
      case AppLanguage.english:
      default:
        return "Select";
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

  String get qiblaCompass {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Qibla Kompass';
      case AppLanguage.turkish:
        return 'Kıble Pusulası';
      case AppLanguage.arabic:
        return 'بوصلة القبلة';
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
        return '$val دقيقة قبل الموعد';
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
        return '$h ساعة قبل الموعد';
      case AppLanguage.english:
      default:
        return '$h hour(s) before';
    }
  }

  String daysBefore(int d) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return '$d Tag(e) vorher';
      case AppLanguage.turkish:
        return '$d Gün önce';
      case AppLanguage.arabic:
        return '$d يوم قبل الموعد';
      case AppLanguage.english:
      default:
        return '$d day(s) before';
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
      case AppLanguage.english:
      default:
        return 'Error loading appointment';
    }
  }

  String get noAppointmentToDelete {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kein Termin zu löschen.';
      case AppLanguage.turkish:
        return 'Silinecek bir randevu yok.';
      case AppLanguage.arabic:
        return 'لا يوجد موعد للحذف.';
      case AppLanguage.english:
      default:
        return 'No appointment to delete.';
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
      case AppLanguage.english:
      default:
        return 'Error deleting appointment.';
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
      case AppLanguage.english:
      default:
        return 'Appointment deleted successfully.';
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

  String get locationPermissionDeniedMessage {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Die Standortberechtigung wurde verweigert.\nBitte erteile die Berechtigung, um den Kompass nutzen zu können.';
      case AppLanguage.turkish:
        return 'Konum izni reddedildi.\nLütfen pusulayı kullanabilmek için izni verin.';
      case AppLanguage.arabic:
        return 'تم رفض إذن الموقع.\nيرجى منح الإذن لاستخدام البوصلة.';
      case AppLanguage.english:
      default:
        return 'Location permission was denied.\nPlease grant permission to use the compass.';
    }
  }

  String get qiblaFetchError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Abrufen der Qibla-Richtung';
      case AppLanguage.turkish:
        return 'Kıble yönü alınırken hata oluştu';
      case AppLanguage.arabic:
        return 'حدث خطأ أثناء استرجاع اتجاه القبلة';
      case AppLanguage.bosnian:
        return 'Greška pri dohvaćanju smjera kible';
      case AppLanguage.spanish:
        return 'Error al obtener la dirección de la Qibla';
      case AppLanguage.persian:
        return 'خطا در دریافت جهت قبله';
      case AppLanguage.english:
      default:
        return 'Error retrieving the Qibla direction';
    }
  }

  String get deviceNotSupported {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ihr Gerät unterstützt den Kompass nicht.';
      case AppLanguage.turkish:
        return 'Cihazınız pusulayı desteklemiyor.';
      case AppLanguage.arabic:
        return 'جهازك لا يدعم البوصلة.';
      case AppLanguage.english:
      default:
        return 'Your device does not support the compass.';
    }
  }

  String get qiblaLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Qibla';
      case AppLanguage.turkish:
        return 'Kıble';
      case AppLanguage.arabic:
        return 'القبلة';
      case AppLanguage.english:
      default:
        return 'Qibla';
    }
  }

  // Neue Getter für InitialLocationPage
  String get initialLocationInstructions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bitte wählen Sie Ihre Sprache";
      case AppLanguage.turkish:
        return "Lütfen dil seçin";
      case AppLanguage.arabic:
        return "الرجاء اختيار لغتك";
      case AppLanguage.bosnian:
        return "Molimo odaberite svoj jezik";
      case AppLanguage.spanish:
        return "Por favor seleccione su idioma";
      case AppLanguage.persian:
        return "لطفا زبان خود را انتخاب کنید";
      case AppLanguage.english:
      default:
        return "Please select your language";
    }
  }

  String get selectLocationInstructions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bitte wählen Sie Ihr Land und Ihre Stadt";
      case AppLanguage.turkish:
        return "Lütfen ülkenizi ve şehrinizi seçin";
      case AppLanguage.arabic:
        return "الرجاء اختيار بلدك ومدينتك";
      case AppLanguage.bosnian:
        return "Molimo odaberite svoju zemlju i grad";
      case AppLanguage.spanish:
        return "Por favor seleccione su país y ciudad";
      case AppLanguage.persian:
        return "لطفا کشور و شهر خود را انتخاب کنید";
      case AppLanguage.english:
      default:
        return "Please select your country and city";
    }
  }

  // Grundlegende UI-Elemente
  String get language {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Sprache";
      case AppLanguage.turkish:
        return "Dil";
      case AppLanguage.arabic:
        return "اللغة";
      case AppLanguage.bosnian:
        return "Jezik";
      case AppLanguage.spanish:
        return "Idioma";
      case AppLanguage.persian:
        return "زبان";
      case AppLanguage.english:
      default:
        return "Language";
    }
  }

  String get timeFormat24 {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "24-Stunden-Format";
      case AppLanguage.turkish:
        return "24 saat formatı";
      case AppLanguage.arabic:
        return "تنسيق 24 ساعة";
      case AppLanguage.bosnian:
        return "24-satni format";
      case AppLanguage.spanish:
        return "Formato 24 horas";
      case AppLanguage.persian:
        return "فرمت 24 ساعته";
      case AppLanguage.english:
      default:
        return "24-hour format";
    }
  }

  String get timeFormat24Active {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "24-Stunden-Format aktiv";
      case AppLanguage.turkish:
        return "24 saat formatı etkin";
      case AppLanguage.arabic:
        return "تنسيق 24 ساعة نشط";
      case AppLanguage.bosnian:
        return "24-satni format aktivan";
      case AppLanguage.spanish:
        return "Formato 24 horas activo";
      case AppLanguage.persian:
        return "فرمت 24 ساعته فعال است";
      case AppLanguage.english:
      default:
        return "24-hour format active";
    }
  }

  String get timeFormatAmPmActive {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "AM/PM-Format aktiv";
      case AppLanguage.turkish:
        return "AM/PM formatı etkin";
      case AppLanguage.arabic:
        return "تنسيق صباحا/مساء نشط";
      case AppLanguage.bosnian:
        return "AM/PM format aktivan";
      case AppLanguage.spanish:
        return "Formato AM/PM activo";
      case AppLanguage.persian:
        return "فرمت AM/PM فعال است";
      case AppLanguage.english:
      default:
        return "AM/PM format active";
    }
  }

  String get locationSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort-Einstellungen";
      case AppLanguage.turkish:
        return "Konum Ayarları";
      case AppLanguage.arabic:
        return "إعدادات الموقع";
      case AppLanguage.bosnian:
        return "Postavke lokacije";
      case AppLanguage.spanish:
        return "Configuración de ubicación";
      case AppLanguage.persian:
        return "تنظیمات مکان";
      case AppLanguage.english:
      default:
        return "Location Settings";
    }
  }

  // Appointment Creation Page Lokalisierungen
  String get reminderTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Erinnerung";
      case AppLanguage.turkish:
        return "Hatırlatma";
      case AppLanguage.arabic:
        return "تذكير";
      case AppLanguage.bosnian:
        return "Podsjetnik";
      case AppLanguage.spanish:
        return "Recordatorio";
      case AppLanguage.persian:
        return "یادآوری";
      case AppLanguage.english:
      default:
        return "Reminder";
    }
  }

  String get reminderBody {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Sie haben einen bevorstehenden Termin";
      case AppLanguage.turkish:
        return "Yaklaşan bir randevunuz var";
      case AppLanguage.arabic:
        return "لديك موعد قادم";
      case AppLanguage.bosnian:
        return "Imate predstojeći sastanak";
      case AppLanguage.spanish:
        return "Tiene una cita próxima";
      case AppLanguage.persian:
        return "شما یک قرار ملاقات پیش رو دارید";
      case AppLanguage.english:
      default:
        return "You have an upcoming appointment";
    }
  }

  String get selectCategoryLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kategorie auswählen";
      case AppLanguage.turkish:
        return "Kategori seçin";
      case AppLanguage.arabic:
        return "اختر الفئة";
      case AppLanguage.bosnian:
        return "Izaberite kategoriju";
      case AppLanguage.spanish:
        return "Seleccionar categoría";
      case AppLanguage.persian:
        return "انتخاب دسته‌بندی";
      case AppLanguage.english:
      default:
        return "Select Category";
    }
  }

  String get fewerOptions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Weniger Optionen";
      case AppLanguage.turkish:
        return "Daha az seçenek";
      case AppLanguage.arabic:
        return "خيارات أقل";
      case AppLanguage.bosnian:
        return "Manje opcija";
      case AppLanguage.spanish:
        return "Menos opciones";
      case AppLanguage.persian:
        return "گزینه‌های کمتر";
      case AppLanguage.english:
      default:
        return "Fewer Options";
    }
  }

  String get advancedOptions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Erweiterte Optionen";
      case AppLanguage.turkish:
        return "Gelişmiş seçenekler";
      case AppLanguage.arabic:
        return "خيارات متقدمة";
      case AppLanguage.bosnian:
        return "Napredne opcije";
      case AppLanguage.spanish:
        return "Opciones avanzadas";
      case AppLanguage.persian:
        return "گزینه‌های پیشرفته";
      case AppLanguage.english:
      default:
        return "Advanced Options";
    }
  }

  String getRecurrenceTypeLabel(String type) {
    switch (type) {
      case 'daily':
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Täglich";
          case AppLanguage.turkish:
            return "Günlük";
          case AppLanguage.arabic:
            return "يومي";
          case AppLanguage.bosnian:
            return "Dnevno";
          case AppLanguage.spanish:
            return "Diario";
          case AppLanguage.persian:
            return "روزانه";
          case AppLanguage.english:
          default:
            return "Daily";
        }
      case 'weekly':
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Wöchentlich";
          case AppLanguage.turkish:
            return "Haftalık";
          case AppLanguage.arabic:
            return "أسبوعي";
          case AppLanguage.bosnian:
            return "Sedmično";
          case AppLanguage.spanish:
            return "Semanal";
          case AppLanguage.persian:
            return "هفتگی";
          case AppLanguage.english:
          default:
            return "Weekly";
        }
      case 'monthly':
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Monatlich";
          case AppLanguage.turkish:
            return "Aylık";
          case AppLanguage.arabic:
            return "شهري";
          case AppLanguage.bosnian:
            return "Mjesečno";
          case AppLanguage.spanish:
            return "Mensual";
          case AppLanguage.persian:
            return "ماهانه";
          case AppLanguage.english:
          default:
            return "Monthly";
        }
      case 'yearly':
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Jährlich";
          case AppLanguage.turkish:
            return "Yıllık";
          case AppLanguage.arabic:
            return "سنوي";
          case AppLanguage.bosnian:
            return "Godišnje";
          case AppLanguage.spanish:
            return "Anual";
          case AppLanguage.persian:
            return "سالانه";
          case AppLanguage.english:
          default:
            return "Yearly";
        }
      case 'custom':
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Benutzerdefiniert";
          case AppLanguage.turkish:
            return "Özel";
          case AppLanguage.arabic:
            return "مخصص";
          case AppLanguage.bosnian:
            return "Prilagođeno";
          case AppLanguage.spanish:
            return "Personalizado";
          case AppLanguage.persian:
            return "سفارشی";
          case AppLanguage.english:
          default:
            return "Custom";
        }
      case 'none':
      default:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return "Keine Wiederholung";
          case AppLanguage.turkish:
            return "Tekrar yok";
          case AppLanguage.arabic:
            return "بدون تكرار";
          case AppLanguage.bosnian:
            return "Bez ponavljanja";
          case AppLanguage.spanish:
            return "Sin repetición";
          case AppLanguage.persian:
            return "بدون تکرار";
          case AppLanguage.english:
          default:
            return "No Recurrence";
        }
    }
  }

  String get pleaseSelectStartTimeError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bitte wähle eine Startzeit aus";
      case AppLanguage.turkish:
        return "Lütfen bir başlangıç saati seçin";
      case AppLanguage.arabic:
        return "الرجاء تحديد وقت البدء";
      case AppLanguage.bosnian:
        return "Molimo odaberite vrijeme početka";
      case AppLanguage.spanish:
        return "Por favor seleccione una hora de inicio";
      case AppLanguage.persian:
        return "لطفا زمان شروع را انتخاب کنید";
      case AppLanguage.english:
      default:
        return "Please select a start time";
    }
  }

  String get upcomingTasksLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Anstehende Termine";
      case AppLanguage.turkish:
        return "Yaklaşan Randevular";
      case AppLanguage.arabic:
        return "المواعيد القادمة";
      case AppLanguage.bosnian:
        return "Nadolazeći termini";
      case AppLanguage.spanish:
        return "Próximas citas";
      case AppLanguage.persian:
        return "قرارهای پیش رو";
      case AppLanguage.english:
      default:
        return "Upcoming Appointments";
    }
  }

  String get addNotifications {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Benachrichtigungen hinzufügen";
      case AppLanguage.turkish:
        return "Bildirimleri Ekle";
      case AppLanguage.arabic:
        return "إضافة الإشعارات";
      case AppLanguage.bosnian:
        return "Dodaj obavještenja";
      case AppLanguage.spanish:
        return "Añadir notificaciones";
      case AppLanguage.persian:
        return "اضافه کردن اعلان‌ها";
      case AppLanguage.english:
      default:
        return "Add notifications";
    }
  }

  String get weather {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Wetter";
      case AppLanguage.turkish:
        return "Hava Durumu";
      case AppLanguage.arabic:
        return "الطقس";
      case AppLanguage.bosnian:
        return "Vrijeme";
      case AppLanguage.spanish:
        return "Clima";
      case AppLanguage.persian:
        return "آب و هوا";
      case AppLanguage.english:
      default:
        return "Weather";
    }
  }

  String get qiblaDirection {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Qibla-Richtung";
      case AppLanguage.turkish:
        return "Kıble Yönü";
      case AppLanguage.arabic:
        return "اتجاه القبلة";
      case AppLanguage.bosnian:
        return "Smjer Kible";
      case AppLanguage.spanish:
        return "Dirección de la Qibla";
      case AppLanguage.persian:
        return "جهت قبله";
      case AppLanguage.english:
      default:
        return "Qibla Direction";
    }
  }

  String get qiblaTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Qibla";
      case AppLanguage.turkish:
        return "Kıble";
      case AppLanguage.arabic:
        return "القبلة";
      case AppLanguage.bosnian:
        return "Kibla";
      case AppLanguage.spanish:
        return "Qibla";
      case AppLanguage.persian:
        return "قبله";
      case AppLanguage.english:
      default:
        return "Qibla";
    }
  }

  // Einstellungsseite Lokalisierungen
  String get darkMode {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Dunkler Modus";
      case AppLanguage.turkish:
        return "Karanlık Mod";
      case AppLanguage.arabic:
        return "الوضع المظلم";
      case AppLanguage.bosnian:
        return "Tamni način";
      case AppLanguage.spanish:
        return "Modo oscuro";
      case AppLanguage.persian:
        return "حالت تاریک";
      case AppLanguage.english:
      default:
        return "Dark Mode";
    }
  }

  String get darkModeSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Aktiviere den dunklen Modus für die App";
      case AppLanguage.turkish:
        return "Uygulama için karanlık modu etkinleştir";
      case AppLanguage.arabic:
        return "تفعيل الوضع المظلم للتطبيق";
      case AppLanguage.bosnian:
        return "Aktivirajte tamni način za aplikaciju";
      case AppLanguage.spanish:
        return "Activar el modo oscuro para la aplicación";
      case AppLanguage.persian:
        return "حالت تاریک را برای برنامه فعال کنید";
      case AppLanguage.english:
      default:
        return "Enable dark mode for the app";
    }
  }

  String get enableNotifications {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Benachrichtigungen aktivieren";
      case AppLanguage.turkish:
        return "Bildirimleri Etkinleştir";
      case AppLanguage.arabic:
        return "تفعيل الإشعارات";
      case AppLanguage.bosnian:
        return "Omogući obavještenja";
      case AppLanguage.spanish:
        return "Habilitar notificaciones";
      case AppLanguage.persian:
        return "فعال کردن اعلان‌ها";
      case AppLanguage.english:
      default:
        return "Enable Notifications";
    }
  }

  String get enableNotificationsSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Erhalte Benachrichtigungen für Termine und Gebetszeiten";
      case AppLanguage.turkish:
        return "Randevular ve namaz vakitleri için bildirim alın";
      case AppLanguage.arabic:
        return "تلقي إشعارات للمواعيد وأوقات الصلاة";
      case AppLanguage.bosnian:
        return "Primajte obavještenja za sastanke i vremena namaza";
      case AppLanguage.spanish:
        return "Recibir notificaciones para citas y horarios de oración";
      case AppLanguage.persian:
        return "دریافت اعلان‌ها برای قرارها و اوقات نماز";
      case AppLanguage.english:
      default:
        return "Receive notifications for appointments and prayer times";
    }
  }

  String get timeFormat {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zeitformat";
      case AppLanguage.turkish:
        return "Zaman Formatı";
      case AppLanguage.arabic:
        return "تنسيق الوقت";
      case AppLanguage.bosnian:
        return "Format vremena";
      case AppLanguage.spanish:
        return "Formato de hora";
      case AppLanguage.persian:
        return "قالب زمان";
      case AppLanguage.english:
      default:
        return "Time Format";
    }
  }

  String get prayerTimeDisplay {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Gebetszeiten-Anzeige";
      case AppLanguage.turkish:
        return "Namaz Vakitleri Görüntüleme";
      case AppLanguage.arabic:
        return "عرض أوقات الصلاة";
      case AppLanguage.bosnian:
        return "Prikaz vremena molitve";
      case AppLanguage.spanish:
        return "Visualización de los tiempos de oración";
      case AppLanguage.persian:
        return "نمایش اوقات نماز";
      case AppLanguage.english:
      default:
        return "Prayer Time Display";
    }
  }

  String get showPrayerTimesInDayView {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Gebetszeiten in der Tagesansicht anzeigen";
      case AppLanguage.turkish:
        return "Gün Görünümünde Namaz Vakitlerini Göster";
      case AppLanguage.arabic:
        return "عرض أوقات الصلاة في عرض اليوم";
      case AppLanguage.bosnian:
        return "Prikaži vremena molitve u dnevnom prikazu";
      case AppLanguage.spanish:
        return "Mostrar tiempos de oración en vista diaria";
      case AppLanguage.persian:
        return "نمایش اوقات نماز در نمای روزانه";
      case AppLanguage.english:
      default:
        return "Show Prayer Times in Day View";
    }
  }

  String get showPrayerTimesInDayViewSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zeigt Gebetszeiten in der Kalender-Tagesansicht an";
      case AppLanguage.turkish:
        return "Takvim Gün Görünümünde Namaz Vakitlerini Gösterir";
      case AppLanguage.arabic:
        return "يعرض أوقات الصلاة في عرض اليوم للتقويم";
      case AppLanguage.bosnian:
        return "Prikazuje vremena molitve u dnevnom prikazu kalendara";
      case AppLanguage.spanish:
        return "Muestra los tiempos de oración en la vista diaria del calendario";
      case AppLanguage.persian:
        return "نمایش اوقات نماز در نمای روزانه تقویم";
      case AppLanguage.english:
      default:
        return "Shows prayer times in the calendar day view";
    }
  }

  String get showPrayerTimesInWeekView {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Gebetszeiten in der Wochenansicht anzeigen";
      case AppLanguage.turkish:
        return "Hafta Görünümünde Namaz Vakitlerini Göster";
      case AppLanguage.arabic:
        return "عرض أوقات الصلاة في عرض الأسبوع";
      case AppLanguage.bosnian:
        return "Prikaži vremena molitve u sedmičnom prikazu";
      case AppLanguage.spanish:
        return "Mostrar tiempos de oración en vista semanal";
      case AppLanguage.persian:
        return "نمایش اوقات نماز در نمای هفتگی";
      case AppLanguage.english:
      default:
        return "Show Prayer Times in Week View";
    }
  }

  String get showPrayerTimesInWeekViewSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zeigt Gebetszeiten in der Kalender-Wochenansicht an";
      case AppLanguage.turkish:
        return "Takvim Hafta Görünümünde Namaz Vakitlerini Gösterir";
      case AppLanguage.arabic:
        return "يعرض أوقات الصلاة في عرض الأسبوع للتقويم";
      case AppLanguage.bosnian:
        return "Prikazuje vremena molitve u sedmičnom prikazu kalendara";
      case AppLanguage.spanish:
        return "Muestra los tiempos de oración en la vista semanal del calendario";
      case AppLanguage.persian:
        return "نمایش اوقات نماز در نمای هفتگی تقویم";
      case AppLanguage.english:
      default:
        return "Shows prayer times in the calendar week view";
    }
  }

  String get showPrayerSlotsInDashboard {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Gebetszeiten im Dashboard anzeigen";
      case AppLanguage.turkish:
        return "Gösterge Panelinde Namaz Vakitlerini Göster";
      case AppLanguage.arabic:
        return "عرض فترات الصلاة في لوحة المعلومات";
      case AppLanguage.bosnian:
        return "Prikaži vremena molitve na nadzornoj ploči";
      case AppLanguage.spanish:
        return "Mostrar tiempos de oración en el tablero";
      case AppLanguage.persian:
        return "نمایش اسلات‌های نماز در داشبورد";
      case AppLanguage.english:
      default:
        return "Show Prayer Slots in Dashboard";
    }
  }

  String get showPrayerSlotsInDashboardSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zeigt Gebetszeit-Karten im Dashboard an";
      case AppLanguage.turkish:
        return "Gösterge Panelinde Namaz Vakti Kartlarını Gösterir";
      case AppLanguage.arabic:
        return "يعرض بطاقات وقت الصلاة في لوحة المعلومات";
      case AppLanguage.bosnian:
        return "Prikazuje kartice vremena molitve na nadzornoj ploči";
      case AppLanguage.spanish:
        return "Muestra tarjetas de tiempo de oración en el tablero";
      case AppLanguage.persian:
        return "نمایش کارت‌های زمان نماز در داشبورد";
      case AppLanguage.english:
      default:
        return "Shows prayer time cards in the dashboard";
    }
  }

  String get automaticLocation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Automatischer Standort";
      case AppLanguage.turkish:
        return "Otomatik Konum";
      case AppLanguage.arabic:
        return "الموقع التلقائي";
      case AppLanguage.bosnian:
        return "Automatska lokacija";
      case AppLanguage.spanish:
        return "Ubicación automática";
      case AppLanguage.persian:
        return "مکان خودکار";
      case AppLanguage.english:
      default:
        return "Automatic Location";
    }
  }

  String get automaticLocationSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verwende den aktuellen Standort für Gebetszeiten";
      case AppLanguage.turkish:
        return "Namaz vakitleri için mevcut konumu kullanın";
      case AppLanguage.arabic:
        return "استخدام الموقع الحالي لأوقات الصلاة";
      case AppLanguage.bosnian:
        return "Koristite trenutnu lokaciju za vremena namaza";
      case AppLanguage.spanish:
        return "Usar ubicación actual para horarios de oración";
      case AppLanguage.persian:
        return "از مکان فعلی برای اوقات نماز استفاده کنید";
      case AppLanguage.english:
      default:
        return "Use current location for prayer times";
    }
  }

  // Kalender-Synchronisierung
  String get calendarSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kalendersynchronisierung";
      case AppLanguage.turkish:
        return "Takvim Senkronizasyonu";
      case AppLanguage.arabic:
        return "مزامنة التقويم";
      case AppLanguage.bosnian:
        return "Sinhronizacija kalendara";
      case AppLanguage.spanish:
        return "Sincronización de calendario";
      case AppLanguage.persian:
        return "همگام‌سازی تقویم";
      case AppLanguage.english:
      default:
        return "Calendar Synchronization";
    }
  }

  String get googleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender';
      case AppLanguage.turkish:
        return 'Google Takvim';
      case AppLanguage.arabic:
        return 'تقويم Google';
      case AppLanguage.bosnian:
        return 'Google Kalendar';
      case AppLanguage.spanish:
        return 'Calendario de Google';
      case AppLanguage.persian:
        return 'تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Google Calendar';
    }
  }

  String get outlookCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Outlook';
      case AppLanguage.turkish:
        return 'Outlook';
      case AppLanguage.arabic:
        return 'Outlook';
      case AppLanguage.bosnian:
        return 'Outlook';
      case AppLanguage.spanish:
        return 'Outlook';
      case AppLanguage.persian:
        return 'Outlook';
      case AppLanguage.english:
      default:
        return 'Outlook';
    }
  }

  String get connectGoogle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Mit Google verbinden";
      case AppLanguage.turkish:
        return "Google'a bağlan";
      case AppLanguage.arabic:
        return "الاتصال بجوجل";
      case AppLanguage.bosnian:
        return "Povežite se s Googleom";
      case AppLanguage.spanish:
        return "Conectar con Google";
      case AppLanguage.persian:
        return "اتصال به گوگل";
      case AppLanguage.english:
      default:
        return "Connect to Google";
    }
  }

  String get connectGoogleDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verbinde dein Google-Konto, um Termine zu synchronisieren";
      case AppLanguage.turkish:
        return "Randevuları senkronize etmek için Google hesabınızı bağlayın";
      case AppLanguage.arabic:
        return "ربط حساب جوجل الخاص بك لمزامنة المواعيد";
      case AppLanguage.bosnian:
        return "Povežite svoj Google račun za sinhronizaciju sastanaka";
      case AppLanguage.spanish:
        return "Conecte su cuenta de Google para sincronizar citas";
      case AppLanguage.persian:
        return "حساب گوگل خود را برای همگام‌سازی قرارها متصل کنید";
      case AppLanguage.english:
      default:
        return "Connect your Google account to synchronize appointments";
    }
  }

  String get connect {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verbinden";
      case AppLanguage.turkish:
        return "Bağlan";
      case AppLanguage.arabic:
        return "اتصال";
      case AppLanguage.bosnian:
        return "Poveži";
      case AppLanguage.spanish:
        return "Conectar";
      case AppLanguage.persian:
        return "اتصال";
      case AppLanguage.english:
      default:
        return "Connect";
    }
  }

  String get manageConnection {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verbindung verwalten";
      case AppLanguage.turkish:
        return "Bağlantıyı yönet";
      case AppLanguage.arabic:
        return "إدارة الاتصال";
      case AppLanguage.bosnian:
        return "Upravljanje vezom";
      case AppLanguage.spanish:
        return "Administrar conexión";
      case AppLanguage.persian:
        return "مدیریت اتصال";
      case AppLanguage.english:
      default:
        return "Manage Connection";
    }
  }

  String get manageConnectionPrompt {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Möchtest du die Verbindung trennen?";
      case AppLanguage.turkish:
        return "Bağlantıyı kesmek istiyor musunuz?";
      case AppLanguage.arabic:
        return "هل ترغب في قطع الاتصال؟";
      case AppLanguage.bosnian:
        return "Želite li prekinuti vezu?";
      case AppLanguage.spanish:
        return "¿Desea desconectar?";
      case AppLanguage.persian:
        return "آیا می‌خواهید اتصال را قطع کنید؟";
      case AppLanguage.english:
      default:
        return "Do you want to disconnect?";
    }
  }

  String get disconnect {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Trennen";
      case AppLanguage.turkish:
        return "Bağlantıyı kes";
      case AppLanguage.arabic:
        return "قطع الاتصال";
      case AppLanguage.bosnian:
        return "Prekini vezu";
      case AppLanguage.spanish:
        return "Desconectar";
      case AppLanguage.persian:
        return "قطع اتصال";
      case AppLanguage.english:
      default:
        return "Disconnect";
    }
  }

  String get importFromCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Aus Kalender importieren";
      case AppLanguage.turkish:
        return "Takvimden içe aktar";
      case AppLanguage.arabic:
        return "استيراد من التقويم";
      case AppLanguage.bosnian:
        return "Uvezi iz kalendara";
      case AppLanguage.spanish:
        return "Importar desde calendario";
      case AppLanguage.persian:
        return "وارد کردن از تقویم";
      case AppLanguage.english:
      default:
        return "Import from Calendar";
    }
  }

  String get exportToCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "In Kalender exportieren";
      case AppLanguage.turkish:
        return "Takvime dışa aktar";
      case AppLanguage.arabic:
        return "تصدير إلى التقويم";
      case AppLanguage.bosnian:
        return "Izvezi u kalendar";
      case AppLanguage.spanish:
        return "Exportar al calendario";
      case AppLanguage.persian:
        return "صادر کردن به تقویم";
      case AppLanguage.english:
      default:
        return "Export to Calendar";
    }
  }

  String get success {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Erfolg";
      case AppLanguage.turkish:
        return "Başarılı";
      case AppLanguage.arabic:
        return "نجاح";
      case AppLanguage.bosnian:
        return "Uspjeh";
      case AppLanguage.spanish:
        return "Éxito";
      case AppLanguage.persian:
        return "موفقیت";
      case AppLanguage.english:
      default:
        return "Success";
    }
  }

  String get error {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Fehler";
      case AppLanguage.turkish:
        return "Hata";
      case AppLanguage.arabic:
        return "خطأ";
      case AppLanguage.bosnian:
        return "Greška";
      case AppLanguage.spanish:
        return "Error";
      case AppLanguage.persian:
        return "خطا";
      case AppLanguage.english:
      default:
        return "Error";
    }
  }

  String get ok {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "OK";
      case AppLanguage.turkish:
        return "Tamam";
      case AppLanguage.arabic:
        return "موافق";
      case AppLanguage.bosnian:
        return "U redu";
      case AppLanguage.spanish:
        return "Aceptar";
      case AppLanguage.persian:
        return "تایید";
      case AppLanguage.english:
      default:
        return "OK";
    }
  }

  String get noSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Keine Synchronisierung";
      case AppLanguage.turkish:
        return "Senkronizasyon yok";
      case AppLanguage.arabic:
        return "لا مزامنة";
      case AppLanguage.bosnian:
        return "Bez sinhronizacije";
      case AppLanguage.spanish:
        return "Sin sincronización";
      case AppLanguage.persian:
        return "بدون همگام‌سازی";
      case AppLanguage.english:
      default:
        return "No Sync";
    }
  }

  String get dailySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Täglich";
      case AppLanguage.turkish:
        return "Günlük";
      case AppLanguage.arabic:
        return "يومي";
      case AppLanguage.bosnian:
        return "Dnevno";
      case AppLanguage.spanish:
        return "Diario";
      case AppLanguage.persian:
        return "روزانه";
      case AppLanguage.english:
      default:
        return "Daily";
    }
  }

  String get weeklySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Wöchentlich";
      case AppLanguage.turkish:
        return "Haftalık";
      case AppLanguage.arabic:
        return "أسبوعي";
      case AppLanguage.bosnian:
        return "Sedmično";
      case AppLanguage.spanish:
        return "Semanal";
      case AppLanguage.persian:
        return "هفتگی";
      case AppLanguage.english:
      default:
        return "Weekly";
    }
  }

  String get monthlySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Monatlich";
      case AppLanguage.turkish:
        return "Aylık";
      case AppLanguage.arabic:
        return "شهري";
      case AppLanguage.bosnian:
        return "Mjesečno";
      case AppLanguage.spanish:
        return "Mensual";
      case AppLanguage.persian:
        return "ماهانه";
      case AppLanguage.english:
      default:
        return "Monthly";
    }
  }

  String importSuccess(String serviceName) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine erfolgreich aus $serviceName importiert";
      case AppLanguage.turkish:
        return "Randevular $serviceName'den başarıyla içe aktarıldı";
      case AppLanguage.arabic:
        return "تم استيراد المواعيد بنجاح من $serviceName";
      case AppLanguage.bosnian:
        return "Sastanci uspješno uvezeni iz $serviceName";
      case AppLanguage.spanish:
        return "Citas importadas con éxito desde $serviceName";
      case AppLanguage.persian:
        return "قرارها با موفقیت از $serviceName وارد شدند";
      case AppLanguage.english:
      default:
        return "Appointments successfully imported from $serviceName";
    }
  }

  String exportSuccess(String serviceName) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine erfolgreich nach $serviceName exportiert";
      case AppLanguage.turkish:
        return "Randevular $serviceName'e başarıyla dışa aktarıldı";
      case AppLanguage.arabic:
        return "تم تصدير المواعيد بنجاح إلى $serviceName";
      case AppLanguage.bosnian:
        return "Sastanci uspješno izvezeni u $serviceName";
      case AppLanguage.spanish:
        return "Citas exportadas con éxito a $serviceName";
      case AppLanguage.persian:
        return "قرارها با موفقیت به $serviceName صادر شدند";
      case AppLanguage.english:
      default:
        return "Appointments successfully exported to $serviceName";
    }
  }

  String syncError(String errorMessage) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Synchronisierungsfehler: $errorMessage";
      case AppLanguage.turkish:
        return "Senkronizasyon hatası: $errorMessage";
      case AppLanguage.arabic:
        return "خطأ في المزامنة: $errorMessage";
      case AppLanguage.bosnian:
        return "Greška sinhronizacije: $errorMessage";
      case AppLanguage.spanish:
        return "Error de sincronización: $errorMessage";
      case AppLanguage.persian:
        return "خطای همگام‌سازی: $errorMessage";
      case AppLanguage.english:
      default:
        return "Synchronization error: $errorMessage";
    }
  }

  String get googleSignInError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Google Anmelde-Fehler";
      case AppLanguage.turkish:
        return "Google Giriş Hatası";
      case AppLanguage.arabic:
        return "خطأ في تسجيل الدخول إلى Google";
      case AppLanguage.bosnian:
        return "Greška prilikom prijave na Google";
      case AppLanguage.spanish:
        return "Error de inicio de sesión de Google";
      case AppLanguage.persian:
        return "خطای ورود به گوگل";
      case AppLanguage.english:
      default:
        return "Google Sign-In Error";
    }
  }

  String get signInRequired {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Anmeldung erforderlich";
      case AppLanguage.turkish:
        return "Giriş gerekli";
      case AppLanguage.arabic:
        return "تسجيل الدخول مطلوب";
      case AppLanguage.bosnian:
        return "Potrebna je prijava";
      case AppLanguage.spanish:
        return "Se requiere iniciar sesión";
      case AppLanguage.persian:
        return "ورود به سیستم لازم است";
      case AppLanguage.english:
      default:
        return "Sign-in required";
    }
  }

  String get settingsSaved {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Einstellungen gespeichert";
      case AppLanguage.turkish:
        return "Ayarlar kaydedildi";
      case AppLanguage.arabic:
        return "تم حفظ الإعدادات";
      case AppLanguage.bosnian:
        return "Postavke sačuvane";
      case AppLanguage.spanish:
        return "Configuración guardada";
      case AppLanguage.persian:
        return "تنظیمات ذخیره شد";
      case AppLanguage.english:
      default:
        return "Settings saved";
    }
  }

  String get saveSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Einstellungen speichern";
      case AppLanguage.turkish:
        return "Ayarları Kaydet";
      case AppLanguage.arabic:
        return "حفظ الإعدادات";
      case AppLanguage.bosnian:
        return "Sačuvaj postavke";
      case AppLanguage.spanish:
        return "Guardar configuración";
      case AppLanguage.persian:
        return "ذخیره تنظیمات";
      case AppLanguage.english:
      default:
        return "Save Settings";
    }
  }

  String get connected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verbunden";
      case AppLanguage.turkish:
        return "Bağlı";
      case AppLanguage.arabic:
        return "متصل";
      case AppLanguage.bosnian:
        return "Povezan";
      case AppLanguage.spanish:
        return "Conectado";
      case AppLanguage.persian:
        return "متصل";
      case AppLanguage.english:
      default:
        return "Connected";
    }
  }

  String get notConnected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Nicht verbunden";
      case AppLanguage.turkish:
        return "Bağlı değil";
      case AppLanguage.arabic:
        return "غير متصل";
      case AppLanguage.bosnian:
        return "Nije povezan";
      case AppLanguage.spanish:
        return "No conectado";
      case AppLanguage.persian:
        return "متصل نیست";
      case AppLanguage.english:
      default:
        return "Not connected";
    }
  }

  String get import {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Importieren";
      case AppLanguage.turkish:
        return "İçe Aktar";
      case AppLanguage.arabic:
        return "استيراد";
      case AppLanguage.bosnian:
        return "Uvoz";
      case AppLanguage.spanish:
        return "Importar";
      case AppLanguage.persian:
        return "وارد کردن";
      case AppLanguage.english:
      default:
        return "Import";
    }
  }

  String get export {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Exportieren";
      case AppLanguage.turkish:
        return "Dışa Aktar";
      case AppLanguage.arabic:
        return "تصدير";
      case AppLanguage.bosnian:
        return "Izvoz";
      case AppLanguage.spanish:
        return "Exportar";
      case AppLanguage.persian:
        return "صادر کردن";
      case AppLanguage.english:
      default:
        return "Export";
    }
  }

  String get syncFrequency {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Synchronisierungsfrequenz";
      case AppLanguage.turkish:
        return "Senkronizasyon Sıklığı";
      case AppLanguage.arabic:
        return "تواتر المزامنة";
      case AppLanguage.bosnian:
        return "Učestalost sinhronizacije";
      case AppLanguage.spanish:
        return "Frecuencia de sincronización";
      case AppLanguage.persian:
        return "تناوب همگام‌سازی";
      case AppLanguage.english:
      default:
        return "Sync Frequency";
    }
  }

  String get importingAppointments {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine werden importiert...";
      case AppLanguage.turkish:
        return "Randevular içe aktarılıyor...";
      case AppLanguage.arabic:
        return "جاري استيراد المواعيد...";
      case AppLanguage.bosnian:
        return "Uvoz termina u toku...";
      case AppLanguage.spanish:
        return "Importando citas...";
      case AppLanguage.persian:
        return "در حال وارد کردن قرارها...";
      case AppLanguage.english:
      default:
        return "Importing appointments...";
    }
  }

  String get appointmentsUpdated {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine wurden aktualisiert";
      case AppLanguage.turkish:
        return "Randevular güncellendi";
      case AppLanguage.arabic:
        return "تم تحديث المواعيد";
      case AppLanguage.bosnian:
        return "Sastanci su ažurirani";
      case AppLanguage.spanish:
        return "Citas actualizadas";
      case AppLanguage.persian:
        return "قرارها به‌روز شدند";
      case AppLanguage.english:
      default:
        return "Appointments updated";
    }
  }

  String get viewAppointments {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine anzeigen";
      case AppLanguage.turkish:
        return "Randevuları görüntüle";
      case AppLanguage.arabic:
        return "عرض المواعيد";
      case AppLanguage.bosnian:
        return "Pogledaj termine";
      case AppLanguage.spanish:
        return "Ver citas";
      case AppLanguage.persian:
        return "مشاهده قرارها";
      case AppLanguage.english:
      default:
        return "View Appointments";
    }
  }

  String get debugAppointments {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Debug: Termine";
      case AppLanguage.turkish:
        return "Hata ayıklama: Randevular";
      case AppLanguage.arabic:
        return "تصحيح الأخطاء: المواعيد";
      case AppLanguage.bosnian:
        return "Otklanjanje grešaka: Sastanci";
      case AppLanguage.spanish:
        return "Depuración: Citas";
      case AppLanguage.persian:
        return "اشکال‌زدایی: قرارها";
      case AppLanguage.english:
      default:
        return "Debug: Appointments";
    }
  }

  String get totalAppointments {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Anzahl der Termine";
      case AppLanguage.turkish:
        return "Toplam Randevu";
      case AppLanguage.arabic:
        return "إجمالي المواعيد";
      case AppLanguage.bosnian:
        return "Ukupno termina";
      case AppLanguage.spanish:
        return "Total de citas";
      case AppLanguage.persian:
        return "تعداد کل قرارها";
      case AppLanguage.english:
      default:
        return "Total Appointments";
    }
  }

  // Texte für Kategorie-Import-Dialog
  String get importCategoriesTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kategorien beim Import";
      case AppLanguage.turkish:
        return "İçe Aktarma için Kategoriler";
      case AppLanguage.arabic:
        return "الفئات عند الاستيراد";
      case AppLanguage.bosnian:
        return "Kategorije pri uvozu";
      case AppLanguage.spanish:
        return "Categorías en la importación";
      case AppLanguage.persian:
        return "دسته‌بندی‌ها هنگام ورود";
      case AppLanguage.english:
      default:
        return "Import Categories";
    }
  }

  String get importCategoriesDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Wie sollen die Kategorien für importierte Termine behandelt werden?";
      case AppLanguage.turkish:
        return "İçe aktarılan randevular için kategoriler nasıl ele alınmalı?";
      case AppLanguage.arabic:
        return "كيف يجب التعامل مع فئات المواعيد المستوردة؟";
      case AppLanguage.bosnian:
        return "Kako treba tretirati kategorije za uvezene sastanke?";
      case AppLanguage.spanish:
        return "¿Cómo deben tratarse las categorías de las citas importadas?";
      case AppLanguage.persian:
        return "چگونه باید با دسته‌های قرارهای وارد شده برخورد شود؟";
      case AppLanguage.english:
      default:
        return "How should categories for imported appointments be handled?";
    }
  }

  String get useDefaultCategory {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standard-Kategorie verwenden";
      case AppLanguage.turkish:
        return "Varsayılan Kategoriyi Kullan";
      case AppLanguage.arabic:
        return "استخدام الفئة الافتراضية";
      case AppLanguage.bosnian:
        return "Koristi zadanu kategoriju";
      case AppLanguage.spanish:
        return "Usar categoría predeterminada";
      case AppLanguage.persian:
        return "استفاده از دسته پیش‌فرض";
      case AppLanguage.english:
      default:
        return "Use Default Category";
    }
  }

  String get useDefaultCategoryDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Alle importierten Termine werden der Standard-Kategorie zugewiesen.";
      case AppLanguage.turkish:
        return "Tüm içe aktarılan randevular varsayılan kategoriye atanacak.";
      case AppLanguage.arabic:
        return "سيتم تعيين جميع المواعيد المستوردة إلى الفئة الافتراضية.";
      case AppLanguage.bosnian:
        return "Svi uvezeni sastanci bit će dodijeljeni zadanoj kategoriji.";
      case AppLanguage.spanish:
        return "Todas las citas importadas se asignarán a la categoría predeterminada.";
      case AppLanguage.persian:
        return "تمام قرارهای وارد شده به دسته پیش‌فرض اختصاص داده می‌شوند.";
      case AppLanguage.english:
      default:
        return "All imported appointments will be assigned to the default category.";
    }
  }

  String get useGoogleColors {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Google-Farben verwenden";
      case AppLanguage.turkish:
        return "Google Renklerini Kullan";
      case AppLanguage.arabic:
        return "استخدام ألوان Google";
      case AppLanguage.bosnian:
        return "Koristi Google boje";
      case AppLanguage.spanish:
        return "Usar colores de Google";
      case AppLanguage.persian:
        return "استفاده از رنگ‌های گوگل";
      case AppLanguage.english:
      default:
        return "Use Google Colors";
    }
  }

  String get useGoogleColorsDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Die Farbkategorien aus dem Google-Kalender werden auf die App-Kategorien abgebildet.";
      case AppLanguage.turkish:
        return "Google Takvim'deki renk kategorileri uygulama kategorileriyle eşleştirilecek.";
      case AppLanguage.arabic:
        return "سيتم ترجمة فئات الألوان من تقويم Google إلى فئات التطبيق.";
      case AppLanguage.bosnian:
        return "Kategorije boja iz Google kalendara bit će povezane s kategorijama aplikacije.";
      case AppLanguage.spanish:
        return "Las categorías de colores del calendario de Google se asignarán a las categorías de la aplicación.";
      case AppLanguage.persian:
        return "دسته‌های رنگی از تقویم گوگل به دسته‌های برنامه نگاشت می‌شوند.";
      case AppLanguage.english:
      default:
        return "Color categories from Google Calendar will be mapped to app categories.";
    }
  }

  String get autoMatchCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kategorien automatisch abgleichen";
      case AppLanguage.turkish:
        return "Kategorileri Otomatik Eşleştir";
      case AppLanguage.arabic:
        return "مطابقة الفئات تلقائيًا";
      case AppLanguage.bosnian:
        return "Automatski podudaraj kategorije";
      case AppLanguage.spanish:
        return "Emparejar categorías automáticamente";
      case AppLanguage.persian:
        return "تطبیق خودکار دسته‌ها";
      case AppLanguage.english:
      default:
        return "Auto-Match Categories";
    }
  }

  String get autoMatchCategoriesDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Versucht, Termine auf Basis des Titels den passenden Kategorien zuzuordnen.";
      case AppLanguage.turkish:
        return "Başlığa göre randevuları eşleşen kategorilere atamaya çalışır.";
      case AppLanguage.arabic:
        return "يحاول تعيين المواعيد إلى الفئات المطابقة بناءً على العنوان.";
      case AppLanguage.bosnian:
        return "Pokušava dodijeliti sastanke odgovarajućim kategorijama na osnovu naslova.";
      case AppLanguage.spanish:
        return "Intenta asignar citas a las categorías coincidentes según el título.";
      case AppLanguage.persian:
        return "تلاش می‌کند قرارها را بر اساس عنوان به دسته‌های مطابق اختصاص دهد.";
      case AppLanguage.english:
      default:
        return "Attempts to assign appointments to matching categories based on title.";
    }
  }

  String get availableCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verfügbare Kategorien:";
      case AppLanguage.turkish:
        return "Mevcut Kategoriler:";
      case AppLanguage.arabic:
        return "الفئات المتاحة:";
      case AppLanguage.bosnian:
        return "Dostupne kategorije:";
      case AppLanguage.spanish:
        return "Categorías disponibles:";
      case AppLanguage.persian:
        return "دسته‌های موجود:";
      case AppLanguage.english:
      default:
        return "Available Categories:";
    }
  }

  // ------------------------------
  // Google Calendar Integration
  // ------------------------------
  String get selectCalendars {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kalender auswählen';
      case AppLanguage.turkish:
        return 'Takvimleri Seç';
      case AppLanguage.arabic:
        return 'اختر التقويمات';
      case AppLanguage.bosnian:
        return 'Izaberi kalendare';
      case AppLanguage.spanish:
        return 'Seleccionar calendarios';
      case AppLanguage.persian:
        return 'تقویم‌ها را انتخاب کنید';
      case AppLanguage.english:
      default:
        return 'Select Calendars';
    }
  }

  String get noCalendarsFound {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Keine Kalender gefunden';
      case AppLanguage.turkish:
        return 'Takvim Bulunamadı';
      case AppLanguage.arabic:
        return 'لم يتم العثور على تقويمات';
      case AppLanguage.bosnian:
        return 'Nije pronađen nijedan kalendar';
      case AppLanguage.spanish:
        return 'No se encontraron calendarios';
      case AppLanguage.persian:
        return 'هیچ تقویمی پیدا نشد';
      case AppLanguage.english:
      default:
        return 'No calendars found';
    }
  }

  String get selectAtLeastOneCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bitte wähle mindestens einen Kalender aus';
      case AppLanguage.turkish:
        return 'Lütfen en az bir takvim seçin';
      case AppLanguage.arabic:
        return 'الرجاء تحديد تقويم واحد على الأقل';
      case AppLanguage.bosnian:
        return 'Molimo odaberite barem jedan kalendar';
      case AppLanguage.spanish:
        return 'Por favor, seleccione al menos un calendario';
      case AppLanguage.persian:
        return 'لطفا حداقل یک تقویم را انتخاب کنید';
      case AppLanguage.english:
      default:
        return 'Please select at least one calendar';
    }
  }

  String get manageCalendars {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kalender verwalten';
      case AppLanguage.turkish:
        return 'Takvimleri Yönet';
      case AppLanguage.arabic:
        return 'إدارة التقويمات';
      case AppLanguage.bosnian:
        return 'Upravljanje kalendarima';
      case AppLanguage.spanish:
        return 'Administrar calendarios';
      case AppLanguage.persian:
        return 'مدیریت تقویم‌ها';
      case AppLanguage.english:
      default:
        return 'Manage Calendars';
    }
  }

  String get loading {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wird geladen...';
      case AppLanguage.turkish:
        return 'Yükleniyor...';
      case AppLanguage.arabic:
        return 'جاري التحميل...';
      case AppLanguage.bosnian:
        return 'Učitavanje...';
      case AppLanguage.spanish:
        return 'Cargando...';
      case AppLanguage.persian:
        return 'در حال بارگذاری...';
      case AppLanguage.english:
      default:
        return 'Loading...';
    }
  }

  String errorLoadingCalendars(String error) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Fehler beim Laden der Kalender: $error';
      case AppLanguage.turkish:
        return 'Takvimler yüklenirken hata oluştu: $error';
      case AppLanguage.arabic:
        return 'خطأ في تحميل التقويمات: $error';
      case AppLanguage.bosnian:
        return 'Greška pri učitavanju kalendara: $error';
      case AppLanguage.spanish:
        return 'Error al cargar calendarios: $error';
      case AppLanguage.persian:
        return 'خطا در بارگیری تقویم‌ها: $error';
      case AppLanguage.english:
      default:
        return 'Error loading calendars: $error';
    }
  }

  String get connectWithGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Mit Google Kalender verbinden';
      case AppLanguage.turkish:
        return 'Google Takvim ile bağlan';
      case AppLanguage.arabic:
        return 'الاتصال بتقويم Google';
      case AppLanguage.bosnian:
        return 'Povežite se s Google kalendarom';
      case AppLanguage.spanish:
        return 'Conectar con Google Calendar';
      case AppLanguage.persian:
        return 'اتصال به تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Connect with Google Calendar';
    }
  }

  String get googleCalendarConnected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Mit Google Kalender verbunden';
      case AppLanguage.turkish:
        return 'Google Takvim bağlı';
      case AppLanguage.arabic:
        return 'متصل بتقويم Google';
      case AppLanguage.bosnian:
        return 'Povezan s Google kalendarom';
      case AppLanguage.spanish:
        return 'Conectado a Google Calendar';
      case AppLanguage.persian:
        return 'به تقویم گوگل متصل شده است';
      case AppLanguage.english:
      default:
        return 'Connected to Google Calendar';
    }
  }

  String get googleCalendarDisconnected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Nicht mit Google Kalender verbunden';
      case AppLanguage.turkish:
        return 'Google Takvim bağlı değil';
      case AppLanguage.arabic:
        return 'غير متصل بتقويم Google';
      case AppLanguage.bosnian:
        return 'Nije povezan s Google kalendarom';
      case AppLanguage.spanish:
        return 'No conectado a Google Calendar';
      case AppLanguage.persian:
        return 'به تقویم گوگل متصل نیست';
      case AppLanguage.english:
      default:
        return 'Not connected to Google Calendar';
    }
  }

  String get selectWhichCalendarsToSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wählen Sie, welche Kalender synchronisiert werden sollen';
      case AppLanguage.turkish:
        return 'Hangi takvimlerin senkronize edileceğini seçin';
      case AppLanguage.arabic:
        return 'حدد التقويمات التي تريد مزامنتها';
      case AppLanguage.bosnian:
        return 'Odaberite koje kalendare želite sinkronizirati';
      case AppLanguage.spanish:
        return 'Seleccione qué calendarios sincronizar';
      case AppLanguage.persian:
        return 'انتخاب کنید کدام تقویم‌ها همگام‌سازی شوند';
      case AppLanguage.english:
      default:
        return 'Select which calendars to sync';
    }
  }

  String get syncNow {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Jetzt synchronisieren';
      case AppLanguage.turkish:
        return 'Şimdi senkronize et';
      case AppLanguage.arabic:
        return 'مزامنة الآن';
      case AppLanguage.bosnian:
        return 'Sinkroniziraj sada';
      case AppLanguage.spanish:
        return 'Sincronizar ahora';
      case AppLanguage.persian:
        return 'همگام‌سازی اکنون';
      case AppLanguage.english:
      default:
        return 'Sync now';
    }
  }

  String get syncGoogleCalendarNow {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender jetzt synchronisieren';
      case AppLanguage.turkish:
        return 'Google Takvim\'i şimdi senkronize et';
      case AppLanguage.arabic:
        return 'مزامنة تقويم Google الآن';
      case AppLanguage.bosnian:
        return 'Sinkroniziraj Google kalendar sada';
      case AppLanguage.spanish:
        return 'Sincronizar Google Calendar ahora';
      case AppLanguage.persian:
        return 'همگام‌سازی تقویم گوگل اکنون';
      case AppLanguage.english:
      default:
        return 'Sync Google Calendar now';
    }
  }

  String get manageGoogleCalendarConnection {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender-Verbindung verwalten';
      case AppLanguage.turkish:
        return 'Google Takvim bağlantısını yönet';
      case AppLanguage.arabic:
        return 'إدارة اتصال تقويم Google';
      case AppLanguage.bosnian:
        return 'Upravljanje vezom s Google kalendarom';
      case AppLanguage.spanish:
        return 'Gestionar conexión de Google Calendar';
      case AppLanguage.persian:
        return 'مدیریت اتصال تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Manage Google Calendar connection';
    }
  }

  String get connectWithOutlookCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Mit Outlook Kalender verbinden';
      case AppLanguage.turkish:
        return 'Outlook Takvim ile bağlan';
      case AppLanguage.arabic:
        return 'الاتصال بتقويم Outlook';
      case AppLanguage.bosnian:
        return 'Povežite se s Outlook kalendarom';
      case AppLanguage.spanish:
        return 'Conectar con Outlook Calendar';
      case AppLanguage.persian:
        return 'اتصال به تقویم اوت‌لوک';
      case AppLanguage.english:
      default:
        return 'Connect with Outlook Calendar';
    }
  }

  String get outlookCalendarDisconnected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Nicht mit Outlook Kalender verbunden';
      case AppLanguage.turkish:
        return 'Outlook Takvim bağlı değil';
      case AppLanguage.arabic:
        return 'غير متصل بتقويم Outlook';
      case AppLanguage.bosnian:
        return 'Nije povezan s Outlook kalendarom';
      case AppLanguage.spanish:
        return 'No conectado a Outlook Calendar';
      case AppLanguage.persian:
        return 'به تقویم اوت‌لوک متصل نیست';
      case AppLanguage.english:
      default:
        return 'Not connected to Outlook Calendar';
    }
  }

  String get manageOutlookCalendarConnection {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Outlook Kalender-Verbindung verwalten';
      case AppLanguage.turkish:
        return 'Outlook Takvim bağlantısını yönet';
      case AppLanguage.arabic:
        return 'إدارة اتصال تقويم Outlook';
      case AppLanguage.bosnian:
        return 'Upravljanje vezom s Outlook kalendarom';
      case AppLanguage.spanish:
        return 'Gestionar conexión de Outlook Calendar';
      case AppLanguage.persian:
        return 'مدیریت اتصال تقویم اوت‌لوک';
      case AppLanguage.english:
      default:
        return 'Manage Outlook Calendar connection';
    }
  }

  String get syncFrequencyDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wie oft soll die Synchronisierung automatisch durchgeführt werden?';
      case AppLanguage.turkish:
        return 'Senkronizasyon ne sıklıkla otomatik olarak yapılmalıdır?';
      case AppLanguage.arabic:
        return 'كم مرة يجب أن تتم المزامنة تلقائيًا؟';
      case AppLanguage.bosnian:
        return 'Koliko često treba automatski provesti sinkronizaciju?';
      case AppLanguage.spanish:
        return '¿Con qué frecuencia debe realizarse la sincronización automáticamente?';
      case AppLanguage.persian:
        return 'همگام‌سازی چند وقت یکبار باید به صورت خودکار انجام شود؟';
      case AppLanguage.english:
      default:
        return 'How often should synchronization be performed automatically?';
    }
  }

  // Import Optionen
  String get importCalendarTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Importoptionen";
      case AppLanguage.turkish:
        return "İçe aktarma seçenekleri";
      case AppLanguage.arabic:
        return "خيارات الاستيراد";
      case AppLanguage.bosnian:
        return "Opcije uvoza";
      case AppLanguage.spanish:
        return "Opciones de importación";
      case AppLanguage.persian:
        return "گزینه های وارد کردن";
      case AppLanguage.english:
      default:
        return "Import Options";
    }
  }

  String get importCalendarDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Wählen Sie, wie Termine aus Google Kalender importiert werden sollen:";
      case AppLanguage.turkish:
        return "Google Takvim'den etkinliklerin nasıl içe aktarılacağını seçin:";
      case AppLanguage.arabic:
        return "اختر كيفية استيراد الأحداث من تقويم Google:";
      case AppLanguage.bosnian:
        return "Odaberite kako uvoziti događaje iz Google kalendara:";
      case AppLanguage.spanish:
        return "Elija cómo importar eventos desde Google Calendar:";
      case AppLanguage.persian:
        return "نحوه وارد کردن رویدادها از تقویم Google را انتخاب کنید:";
      case AppLanguage.english:
      default:
        return "Choose how to import events from Google Calendar:";
    }
  }

  String get importOptionDefault {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standard-Kategorie";
      case AppLanguage.turkish:
        return "Varsayılan kategori";
      case AppLanguage.arabic:
        return "الفئة الافتراضية";
      case AppLanguage.bosnian:
        return "Zadana kategorija";
      case AppLanguage.spanish:
        return "Categoría predeterminada";
      case AppLanguage.persian:
        return "دسته پیش فرض";
      case AppLanguage.english:
      default:
        return "Default Category";
    }
  }

  String get importOptionDefaultSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Alle Termine werden einer Standard-Kategorie zugeordnet";
      case AppLanguage.turkish:
        return "Tüm etkinlikler varsayılan bir kategoriye atanacaktır";
      case AppLanguage.arabic:
        return "سيتم تعيين جميع الأحداث إلى فئة افتراضية";
      case AppLanguage.bosnian:
        return "Svi događaji bit će dodijeljeni zadanoj kategoriji";
      case AppLanguage.spanish:
        return "Todos los eventos se asignarán a una categoría predeterminada";
      case AppLanguage.persian:
        return "همه رویدادها به یک دسته پیش‌فرض اختصاص داده می‌شوند";
      case AppLanguage.english:
      default:
        return "All events will be assigned to a default category";
    }
  }

  String get importOptionColorCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Google Farben als Kategorien";
      case AppLanguage.turkish:
        return "Google Renklerini kategori olarak kullan";
      case AppLanguage.arabic:
        return "استخدام ألوان Google كفئات";
      case AppLanguage.bosnian:
        return "Koristite Google boje kao kategorije";
      case AppLanguage.spanish:
        return "Usar colores de Google como categorías";
      case AppLanguage.persian:
        return "از رنگ‌های Google به عنوان دسته‌بندی استفاده کنید";
      case AppLanguage.english:
      default:
        return "Use Google Colors as Categories";
    }
  }

  String get importOptionColorCategoriesSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine werden basierend auf ihrer Google Kalender-Farbe kategorisiert";
      case AppLanguage.turkish:
        return "Etkinlikler, Google Takvim renklerine göre kategorilere ayrılacaktır";
      case AppLanguage.arabic:
        return "سيتم تصنيف الأحداث بناءً على لون تقويم Google الخاص بها";
      case AppLanguage.bosnian:
        return "Događaji će biti kategorizirani na osnovu boje Google kalendara";
      case AppLanguage.spanish:
        return "Los eventos se categorizarán según el color de su Google Calendar";
      case AppLanguage.persian:
        return "رویدادها بر اساس رنگ تقویم Google خود دسته‌بندی می‌شوند";
      case AppLanguage.english:
      default:
        return "Events will be categorized based on their Google Calendar color";
    }
  }

  String get importOptionNamedCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kategorien nach Kalender";
      case AppLanguage.turkish:
        return "Takvime göre kategoriler";
      case AppLanguage.arabic:
        return "فئات حسب التقويم";
      case AppLanguage.bosnian:
        return "Kategorije po kalendaru";
      case AppLanguage.spanish:
        return "Categorías por calendario";
      case AppLanguage.persian:
        return "دسته‌بندی بر اساس تقویم";
      case AppLanguage.english:
      default:
        return "Categories by Calendar";
    }
  }

  String get importOptionNamedCategoriesSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Verwendet den Google-Kalendernamen als Kategorie für zugehörige Termine";
      case AppLanguage.turkish:
        return "Google Takvim adını ilgili etkinlikler için kategori olarak kullanır";
      case AppLanguage.arabic:
        return "يستخدم اسم تقويم Google كفئة للأحداث المرتبطة";
      case AppLanguage.bosnian:
        return "Koristi ime Google kalendara kao kategoriju za povezane događaje";
      case AppLanguage.spanish:
        return "Utiliza el nombre del calendario de Google como categoría para eventos relacionados";
      case AppLanguage.persian:
        return "از نام تقویم Google به عنوان دسته‌بندی برای رویدادهای مربوطه استفاده می‌کند";
      case AppLanguage.english:
      default:
        return "Uses the Google Calendar name as category for associated events";
    }
  }

  String get importButtonLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Importieren";
      case AppLanguage.turkish:
        return "İçe Aktar";
      case AppLanguage.arabic:
        return "استيراد";
      case AppLanguage.bosnian:
        return "Uvoz";
      case AppLanguage.spanish:
        return "Importar";
      case AppLanguage.persian:
        return "وارد کردن";
      case AppLanguage.english:
      default:
        return "Import";
    }
  }

  String get importCalendarConfirmation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Diese Funktion importiert nur Termine von Google Calendar, ohne die lokalen Termine zu Google zu exportieren. Möchten Sie fortfahren?";
      case AppLanguage.turkish:
        return "Bu işlev, yalnızca yerel etkinlikleri Google'a dışa aktarmadan Google Takvim'den etkinlikleri içe aktarır. Devam etmek istiyor musunuz?";
      case AppLanguage.arabic:
        return "تقوم هذه الوظيفة باستيراد الأحداث من Google Calendar فقط، دون تصدير الأحداث المحلية إلى Google. هل تريد المتابعة؟";
      case AppLanguage.bosnian:
        return "Ova funkcija uvozi samo događaje iz Google kalendara, bez izvoza lokalnih događaja u Google. Želite li nastaviti?";
      case AppLanguage.spanish:
        return "Esta función solo importa eventos desde Google Calendar, sin exportar eventos locales a Google. ¿Desea continuar?";
      case AppLanguage.persian:
        return "این عملکرد فقط رویدادها را از تقویم Google وارد می‌کند، بدون اینکه رویدادهای محلی را به Google صادر کند. آیا می‌خواهید ادامه دهید؟";
      case AppLanguage.english:
      default:
        return "This function only imports events from Google Calendar, without exporting local events to Google. Do you want to continue?";
    }
  }

  String get importInProgress {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Import wird durchgeführt...";
      case AppLanguage.turkish:
        return "İçe aktarma devam ediyor...";
      case AppLanguage.arabic:
        return "جاري الاستيراد...";
      case AppLanguage.bosnian:
        return "Uvoz u toku...";
      case AppLanguage.spanish:
        return "Importación en progreso...";
      case AppLanguage.persian:
        return "وارد کردن در حال انجام...";
      case AppLanguage.english:
      default:
        return "Import in progress...";
    }
  }

  String get exportingAppointments {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine werden exportiert...";
      case AppLanguage.turkish:
        return "Randevular dışa aktarılıyor...";
      case AppLanguage.arabic:
        return "جاري تصدير المواعيد...";
      case AppLanguage.bosnian:
        return "Izvoz termina u toku...";
      case AppLanguage.spanish:
        return "Exportando citas...";
      case AppLanguage.persian:
        return "در حال صادر کردن قرارها...";
      case AppLanguage.english:
      default:
        return "Exporting appointments...";
    }
  }

  String get importCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Import abgeschlossen";
      case AppLanguage.turkish:
        return "İçe aktarma tamamlandı";
      case AppLanguage.arabic:
        return "اكتمل الاستيراد";
      case AppLanguage.bosnian:
        return "Uvoz završen";
      case AppLanguage.spanish:
        return "Importación completada";
      case AppLanguage.persian:
        return "وارد کردن کامل شد";
      case AppLanguage.english:
      default:
        return "Import completed";
    }
  }

  String get resetInProgress {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zurücksetzen wird durchgeführt...";
      case AppLanguage.turkish:
        return "Sıfırlama devam ediyor...";
      case AppLanguage.arabic:
        return "جاري إعادة التعيين...";
      case AppLanguage.bosnian:
        return "Resetovanje u toku...";
      case AppLanguage.spanish:
        return "Restablecimiento en progreso...";
      case AppLanguage.persian:
        return "بازنشانی در حال انجام...";
      case AppLanguage.english:
      default:
        return "Reset in progress...";
    }
  }

  String get resetCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Zurücksetzen abgeschlossen";
      case AppLanguage.turkish:
        return "Sıfırlama tamamlandı";
      case AppLanguage.arabic:
        return "اكتملت إعادة التعيين";
      case AppLanguage.bosnian:
        return "Resetovanje završeno";
      case AppLanguage.spanish:
        return "Restablecimiento completado";
      case AppLanguage.persian:
        return "بازنشانی کامل شد";
      case AppLanguage.english:
      default:
        return "Reset completed";
    }
  }

  String get exportCalendarTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Termine exportieren";
      case AppLanguage.turkish:
        return "Etkinlikleri dışa aktar";
      case AppLanguage.arabic:
        return "تصدير الأحداث";
      case AppLanguage.bosnian:
        return "Izvoz događaja";
      case AppLanguage.spanish:
        return "Exportar eventos";
      case AppLanguage.persian:
        return "صدور رویدادها";
      case AppLanguage.english:
      default:
        return "Export Events";
    }
  }

  String get exportCalendarConfirmation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Diese Funktion exportiert nur Termine zu Google Calendar, ohne neue Termine von Google zu importieren. Möchten Sie fortfahren?";
      case AppLanguage.turkish:
        return "Bu işlev, Google'dan yeni etkinlikler içe aktarmadan yalnızca etkinlikleri Google Takvim'e aktarır. Devam etmek istiyor musunuz?";
      case AppLanguage.arabic:
        return "تقوم هذه الوظيفة بتصدير الأحداث إلى تقويم Google فقط، دون استيراد أحداث جديدة من Google. هل تريد المتابعة؟";
      case AppLanguage.bosnian:
        return "Ova funkcija samo izvozi događaje u Google kalendar, bez uvoza novih događaja iz Google-a. Želite li nastaviti?";
      case AppLanguage.spanish:
        return "Esta función solo exporta eventos a Google Calendar, sin importar nuevos eventos de Google. ¿Desea continuar?";
      case AppLanguage.persian:
        return "این عملکرد فقط رویدادها را به تقویم Google صادر می‌کند، بدون وارد کردن رویدادهای جدید از Google. آیا می‌خواهید ادامه دهید؟";
      case AppLanguage.english:
      default:
        return "This function only exports events to Google Calendar, without importing new events from Google. Do you want to continue?";
    }
  }

  String get exportButtonLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Exportieren";
      case AppLanguage.turkish:
        return "Dışa Aktar";
      case AppLanguage.arabic:
        return "تصدير";
      case AppLanguage.bosnian:
        return "Izvoz";
      case AppLanguage.spanish:
        return "Exportar";
      case AppLanguage.persian:
        return "صادر کردن";
      case AppLanguage.english:
      default:
        return "Export";
    }
  }

  String get exportInProgress {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Export wird durchgeführt...";
      case AppLanguage.turkish:
        return "Dışa aktarma devam ediyor...";
      case AppLanguage.arabic:
        return "جاري التصدير...";
      case AppLanguage.bosnian:
        return "Izvoz u toku...";
      case AppLanguage.spanish:
        return "Exportación en progreso...";
      case AppLanguage.persian:
        return "صادر کردن در حال انجام...";
      case AppLanguage.english:
      default:
        return "Export in progress...";
    }
  }

  String get exportCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Export abgeschlossen";
      case AppLanguage.turkish:
        return "Dışa aktarma tamamlandı";
      case AppLanguage.arabic:
        return "اكتمل التصدير";
      case AppLanguage.bosnian:
        return "Izvoz završen";
      case AppLanguage.spanish:
        return "Exportación completada";
      case AppLanguage.persian:
        return "صادر کردن کامل شد";
      case AppLanguage.english:
      default:
        return "Export completed";
    }
  }

  String get notSignedIn {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Nicht angemeldet";
      case AppLanguage.turkish:
        return "Giriş yapılmadı";
      case AppLanguage.arabic:
        return "لم يتم تسجيل الدخول";
      case AppLanguage.bosnian:
        return "Niste prijavljeni";
      case AppLanguage.spanish:
        return "No ha iniciado sesión";
      case AppLanguage.persian:
        return "وارد نشده‌اید";
      case AppLanguage.english:
      default:
        return "Not signed in";
    }
  }

  String get fixInvalidRecurrencesTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Fehlerhafte Termine bereinigen";
      case AppLanguage.turkish:
        return "Hatalı etkinlikleri düzelt";
      case AppLanguage.arabic:
        return "إصلاح الأحداث غير الصالحة";
      case AppLanguage.bosnian:
        return "Popravite nevažeće događaje";
      case AppLanguage.spanish:
        return "Corregir eventos inválidos";
      case AppLanguage.persian:
        return "رویدادهای نامعتبر را اصلاح کنید";
      case AppLanguage.english:
      default:
        return "Fix invalid events";
    }
  }

  String get fixInvalidRecurrencesConfirmation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Diese Funktion korrigiert ungültige Wiederholungsregeln in Ihren Terminen. Dies kann helfen, wenn Termine nicht korrekt angezeigt werden. Möchten Sie fortfahren?";
      case AppLanguage.turkish:
        return "Bu işlev, etkinliklerinizdeki geçersiz yineleme kurallarını düzeltir. Etkinlikler doğru görüntülenmiyorsa yardımcı olabilir. Devam etmek istiyor musunuz?";
      case AppLanguage.arabic:
        return "تقوم هذه الوظيفة بتصحيح قواعد التكرار غير الصالحة في أحداثك. يمكن أن يساعد ذلك إذا لم يتم عرض الأحداث بشكل صحيح. هل تريد المتابعة؟";
      case AppLanguage.bosnian:
        return "Ova funkcija ispravlja nevažeća pravila ponavljanja u vašim događajima. To može pomoći ako se događaji ne prikazuju ispravno. Želite li nastaviti?";
      case AppLanguage.spanish:
        return "Esta función corrige las reglas de repetición no válidas en sus eventos. Esto puede ayudar si los eventos no se muestran correctamente. ¿Desea continuar?";
      case AppLanguage.persian:
        return "این عملکرد قوانین تکرار نامعتبر در رویدادهای شما را اصلاح می‌کند. اگر رویدادها به درستی نمایش داده نمی‌شوند، این می‌تواند کمک کند. آیا می‌خواهید ادامه دهید؟";
      case AppLanguage.english:
      default:
        return "This function corrects invalid recurrence rules in your events. This can help if events are not displaying correctly. Do you want to continue?";
    }
  }

  String get fixButtonLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bereinigen";
      case AppLanguage.turkish:
        return "Düzelt";
      case AppLanguage.arabic:
        return "إصلاح";
      case AppLanguage.bosnian:
        return "Popravi";
      case AppLanguage.spanish:
        return "Corregir";
      case AppLanguage.persian:
        return "اصلاح";
      case AppLanguage.english:
      default:
        return "Fix";
    }
  }

  String get fixInProgress {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bereinigung wird durchgeführt...";
      case AppLanguage.turkish:
        return "Düzeltme devam ediyor...";
      case AppLanguage.arabic:
        return "جاري الإصلاح...";
      case AppLanguage.bosnian:
        return "Popravak u toku...";
      case AppLanguage.spanish:
        return "Corrección en progreso...";
      case AppLanguage.persian:
        return "اصلاح در حال انجام...";
      case AppLanguage.english:
      default:
        return "Fixing in progress...";
    }
  }

  String get fixCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Bereinigung abgeschlossen";
      case AppLanguage.turkish:
        return "Düzeltme tamamlandı";
      case AppLanguage.arabic:
        return "اكتمل الإصلاح";
      case AppLanguage.bosnian:
        return "Popravak završen";
      case AppLanguage.spanish:
        return "Corrección completada";
      case AppLanguage.persian:
        return "اصلاح کامل شد";
      case AppLanguage.english:
      default:
        return "Fixing completed";
    }
  }

  String get exceptionDatesSelected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ausnahmedaten ausgewählt';
      case AppLanguage.turkish:
        return 'İstisna tarihleri seçildi';
      case AppLanguage.arabic:
        return 'تواريخ الاستثناء المحددة';
      case AppLanguage.bosnian:
        return 'Odabrani dati izuzeća';
      case AppLanguage.spanish:
        return 'Fechas de excepción seleccionadas';
      case AppLanguage.persian:
        return 'تاریخ‌های استثنا انتخاب شده';
      case AppLanguage.english:
      default:
        return 'Exception dates selected';
    }
  }

  // Neue Übersetzungen für die Standortanzeige
  String get currentLocationAuto {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Aktueller Standort (automatisch erkannt):";
      case AppLanguage.turkish:
        return "Mevcut konum (otomatik algılanan):";
      case AppLanguage.arabic:
        return "الموقع الحالي (تم الكشف تلقائيًا):";
      case AppLanguage.bosnian:
        return "Trenutna lokacija (automatski otkrivena):";
      case AppLanguage.spanish:
        return "Ubicación actual (detectada automáticamente):";
      case AppLanguage.persian:
        return "مکان فعلی (به طور خودکار شناسایی شده):";
      case AppLanguage.english:
      default:
        return "Current location (automatically detected):";
    }
  }

  String get currentLocationManual {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Aktueller Standort (manuell ausgewählt):";
      case AppLanguage.turkish:
        return "Mevcut konum (manuel olarak seçildi):";
      case AppLanguage.arabic:
        return "الموقع الحالي (محدد يدويًا):";
      case AppLanguage.bosnian:
        return "Trenutna lokacija (ručno odabrana):";
      case AppLanguage.spanish:
        return "Ubicación actual (seleccionada manualmente):";
      case AppLanguage.persian:
        return "مکان فعلی (به صورت دستی انتخاب شده):";
      case AppLanguage.english:
      default:
        return "Current location (manually selected):";
    }
  }

  String get automaticLocationActive {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Aktueller Standort wird automatisch erkannt";
      case AppLanguage.turkish:
        return "Mevcut konum otomatik olarak algılanıyor";
      case AppLanguage.arabic:
        return "يتم اكتشاف الموقع الحالي تلقائيًا";
      case AppLanguage.bosnian:
        return "Trenutna lokacija se automatski otkriva";
      case AppLanguage.spanish:
        return "La ubicación actual se detecta automáticamente";
      case AppLanguage.persian:
        return "مکان فعلی به طور خودکار شناسایی می‌شود";
      case AppLanguage.english:
      default:
        return "Current location is automatically detected";
    }
  }

  String get manualLocationActive {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort wird manuell ausgewählt";
      case AppLanguage.turkish:
        return "Konum manuel olarak seçiliyor";
      case AppLanguage.arabic:
        return "يتم تحديد الموقع يدويًا";
      case AppLanguage.bosnian:
        return "Lokacija se bira ručno";
      case AppLanguage.spanish:
        return "La ubicación se selecciona manualmente";
      case AppLanguage.persian:
        return "مکان به صورت دستی انتخاب می‌شود";
      case AppLanguage.english:
      default:
        return "Location is selected manually";
    }
  }

  String get chooseLocationManually {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort manuell auswählen:";
      case AppLanguage.turkish:
        return "Konumu manuel olarak seçin:";
      case AppLanguage.arabic:
        return "اختيار الموقع يدويًا:";
      case AppLanguage.bosnian:
        return "Ručno odaberite lokaciju:";
      case AppLanguage.spanish:
        return "Seleccionar ubicación manualmente:";
      case AppLanguage.persian:
        return "انتخاب دستی مکان:";
      case AppLanguage.english:
      default:
        return "Choose location manually:";
    }
  }

  String get applyLocation {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort übernehmen";
      case AppLanguage.turkish:
        return "Konumu uygula";
      case AppLanguage.arabic:
        return "تطبيق الموقع";
      case AppLanguage.bosnian:
        return "Primijeni lokaciju";
      case AppLanguage.spanish:
        return "Aplicar ubicación";
      case AppLanguage.persian:
        return "اعمال مکان";
      case AppLanguage.english:
      default:
        return "Apply location";
    }
  }

  String get locationUpdated {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort wurde aktualisiert";
      case AppLanguage.turkish:
        return "Konum güncellendi";
      case AppLanguage.arabic:
        return "تم تحديث الموقع";
      case AppLanguage.bosnian:
        return "Lokacija je ažurirana";
      case AppLanguage.spanish:
        return "Ubicación actualizada";
      case AppLanguage.persian:
        return "مکان به‌روزرسانی شد";
      case AppLanguage.english:
      default:
        return "Location has been updated";
    }
  }

  String get noLocationSet {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Kein Standort festgelegt";
      case AppLanguage.turkish:
        return "Konum ayarlanmadı";
      case AppLanguage.arabic:
        return "لم يتم تحديد موقع";
      case AppLanguage.bosnian:
        return "Lokacija nije postavljena";
      case AppLanguage.spanish:
        return "Ubicación no establecida";
      case AppLanguage.persian:
        return "مکانی تنظیم نشده است";
      case AppLanguage.english:
      default:
        return "No location set";
    }
  }

  String get locationDetecting {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standort wird ermittelt...";
      case AppLanguage.turkish:
        return "Konum belirleniyor...";
      case AppLanguage.arabic:
        return "جاري تحديد الموقع...";
      case AppLanguage.bosnian:
        return "Lokacija se određuje...";
      case AppLanguage.spanish:
        return "Detectando ubicación...";
      case AppLanguage.persian:
        return "در حال تشخیص مکان...";
      case AppLanguage.english:
      default:
        return "Detecting location...";
    }
  }

  String get locationDetectionFailed {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return "Standorterkennung fehlgeschlagen";
      case AppLanguage.turkish:
        return "Konum algılama başarısız oldu";
      case AppLanguage.arabic:
        return "فشل اكتشاف الموقع";
      case AppLanguage.bosnian:
        return "Otkrivanje lokacije nije uspjelo";
      case AppLanguage.spanish:
        return "Falló la detección de ubicación";
      case AppLanguage.persian:
        return "تشخیص مکان ناموفق بود";
      case AppLanguage.english:
      default:
        return "Location detection failed";
    }
  }

  // Dashboard-Widget Texte
  String get networkError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Netzwerkfehler';
      case AppLanguage.turkish:
        return 'Ağ hatası';
      case AppLanguage.arabic:
        return 'خطأ في الشبكة';
      case AppLanguage.bosnian:
        return 'Greška mreže';
      case AppLanguage.spanish:
        return 'Error de red';
      case AppLanguage.persian:
        return 'خطای شبکه';
      case AppLanguage.english:
      default:
        return 'Network Error';
    }
  }

  String get weatherFetchError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wetter konnte nicht abgerufen werden';
      case AppLanguage.turkish:
        return 'Hava durumu alınamadı';
      case AppLanguage.arabic:
        return 'تعذر جلب بيانات الطقس';
      case AppLanguage.bosnian:
        return 'Nije moguće preuzeti vremenske podatke';
      case AppLanguage.spanish:
        return 'No se pudieron recuperar los datos meteorológicos';
      case AppLanguage.persian:
        return 'اطلاعات آب و هوا قابل بازیابی نیست';
      case AppLanguage.english:
      default:
        return 'Weather data could not be retrieved';
    }
  }

  String get prayerTimesFetchError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Gebetszeiten konnten nicht abgerufen werden';
      case AppLanguage.turkish:
        return 'Namaz vakitleri alınamadı';
      case AppLanguage.arabic:
        return 'تعذر جلب أوقات الصلاة';
      case AppLanguage.bosnian:
        return 'Nije moguće preuzeti vremena namaza';
      case AppLanguage.spanish:
        return 'No se pudieron recuperar los tiempos de oración';
      case AppLanguage.persian:
        return 'اوقات نماز قابل بازیابی نیست';
      case AppLanguage.english:
      default:
        return 'Prayer times could not be retrieved';
    }
  }

  String get noAppointmentsToday {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Keine Termine für heute';
      case AppLanguage.turkish:
        return 'Bugün için randevu yok';
      case AppLanguage.arabic:
        return 'لا مواعيد لهذا اليوم';
      case AppLanguage.bosnian:
        return 'Nema termina za danas';
      case AppLanguage.spanish:
        return 'No hay citas para hoy';
      case AppLanguage.persian:
        return 'امروز قراری وجود ندارد';
      case AppLanguage.english:
      default:
        return 'No appointments for today';
    }
  }

  // ------------------------------
  // Synchronisation
  // ------------------------------

  String get synchronization {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Synchronisation';
      case AppLanguage.turkish:
        return 'Senkronizasyon';
      case AppLanguage.arabic:
        return 'المزامنة';
      case AppLanguage.bosnian:
        return 'Sinhronizacija';
      case AppLanguage.spanish:
        return 'Sincronización';
      case AppLanguage.persian:
        return 'همگام سازی';
      case AppLanguage.english:
      default:
        return 'Synchronization';
    }
  }

  String get syncImportExport {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Sync, Import, Export';
      case AppLanguage.turkish:
        return 'Senkronize, İçe Aktar, Dışa Aktar';
      case AppLanguage.arabic:
        return 'مزامنة, استيراد, تصدير';
      case AppLanguage.bosnian:
        return 'Sinhronizacija, Uvoz, Izvoz';
      case AppLanguage.spanish:
        return 'Sincronizar, Importar, Exportar';
      case AppLanguage.persian:
        return 'همگام سازی، واردات، صادرات';
      case AppLanguage.english:
      default:
        return 'Sync, Import, Export';
    }
  }

  String get comingSoon {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kommt bald';
      case AppLanguage.turkish:
        return 'Yakında';
      case AppLanguage.arabic:
        return 'قريبًا';
      case AppLanguage.bosnian:
        return 'Uskoro';
      case AppLanguage.spanish:
        return 'Próximamente';
      case AppLanguage.persian:
        return 'به زودی';
      case AppLanguage.english:
      default:
        return 'Coming soon';
    }
  }

  String get fullSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Vollständig synchronisieren';
      case AppLanguage.turkish:
        return 'Tam senkronizasyon';
      case AppLanguage.arabic:
        return 'مزامنة كاملة';
      case AppLanguage.bosnian:
        return 'Potpuna sinhronizacija';
      case AppLanguage.spanish:
        return 'Sincronización completa';
      case AppLanguage.persian:
        return 'همگام سازی کامل';
      case AppLanguage.english:
      default:
        return 'Full synchronization';
    }
  }

  String get importAndExport {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Import und Export';
      case AppLanguage.turkish:
        return 'İçe ve Dışa Aktarma';
      case AppLanguage.arabic:
        return 'استيراد وتصدير';
      case AppLanguage.bosnian:
        return 'Uvoz i izvoz';
      case AppLanguage.spanish:
        return 'Importación y exportación';
      case AppLanguage.persian:
        return 'واردات و صادرات';
      case AppLanguage.english:
      default:
        return 'Import and Export';
    }
  }

  String get importOnly {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Nur importieren';
      case AppLanguage.turkish:
        return 'Sadece içe aktar';
      case AppLanguage.arabic:
        return 'استيراد فقط';
      case AppLanguage.bosnian:
        return 'Samo uvoz';
      case AppLanguage.spanish:
        return 'Solo importar';
      case AppLanguage.persian:
        return 'فقط وارد کنید';
      case AppLanguage.english:
      default:
        return 'Import only';
    }
  }

  String get importFromGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termine von Google Kalender importieren';
      case AppLanguage.turkish:
        return 'Google Takvim\'den etkinlikleri içe aktar';
      case AppLanguage.arabic:
        return 'استيراد المواعيد من تقويم Google';
      case AppLanguage.bosnian:
        return 'Uvezi događaje iz Google Kalendara';
      case AppLanguage.spanish:
        return 'Importar eventos del Calendario de Google';
      case AppLanguage.persian:
        return 'وارد کردن رویدادها از تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Import appointments from Google Calendar';
    }
  }

  String get exportOnly {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Nur exportieren';
      case AppLanguage.turkish:
        return 'Sadece dışa aktar';
      case AppLanguage.arabic:
        return 'تصدير فقط';
      case AppLanguage.bosnian:
        return 'Samo izvoz';
      case AppLanguage.spanish:
        return 'Solo exportar';
      case AppLanguage.persian:
        return 'فقط صادر کنید';
      case AppLanguage.english:
      default:
        return 'Export only';
    }
  }

  String get exportToGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termine nach Google Kalender exportieren';
      case AppLanguage.turkish:
        return 'Etkinlikleri Google Takvim\'e dışa aktar';
      case AppLanguage.arabic:
        return 'تصدير المواعيد إلى تقويم Google';
      case AppLanguage.bosnian:
        return 'Izvezi događaje u Google Kalendar';
      case AppLanguage.spanish:
        return 'Exportar eventos al Calendario de Google';
      case AppLanguage.persian:
        return 'صادر کردن رویدادها به تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Export appointments to Google Calendar';
    }
  }

  String get importOptions {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Import-Optionen';
      case AppLanguage.turkish:
        return 'İçe Aktarma Seçenekleri';
      case AppLanguage.arabic:
        return 'خيارات الاستيراد';
      case AppLanguage.bosnian:
        return 'Opcije uvoza';
      case AppLanguage.spanish:
        return 'Opciones de importación';
      case AppLanguage.persian:
        return 'گزینه های واردات';
      case AppLanguage.english:
      default:
        return 'Import Options';
    }
  }

  String get howToHandleCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wie sollen Kategorien behandelt werden?';
      case AppLanguage.turkish:
        return 'Kategoriler nasıl ele alınmalı?';
      case AppLanguage.arabic:
        return 'كيف يجب التعامل مع الفئات؟';
      case AppLanguage.bosnian:
        return 'Kako tretirati kategorije?';
      case AppLanguage.spanish:
        return '¿Cómo se deben manejar las categorías?';
      case AppLanguage.persian:
        return 'دسته ها چگونه باید مدیریت شوند؟';
      case AppLanguage.english:
      default:
        return 'How should categories be handled?';
    }
  }

  String get useExistingCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bestehende Kategorien verwenden';
      case AppLanguage.turkish:
        return 'Mevcut kategorileri kullan';
      case AppLanguage.arabic:
        return 'استخدام الفئات الحالية';
      case AppLanguage.bosnian:
        return 'Koristi postojeće kategorije';
      case AppLanguage.spanish:
        return 'Usar categorías existentes';
      case AppLanguage.persian:
        return 'استفاده از دسته های موجود';
      case AppLanguage.english:
      default:
        return 'Use existing categories';
    }
  }

  String get searchForMatchingCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Suche nach passenden Kategorien';
      case AppLanguage.turkish:
        return 'Eşleşen kategorileri ara';
      case AppLanguage.arabic:
        return 'البحث عن الفئات المطابقة';
      case AppLanguage.bosnian:
        return 'Traži odgovarajuće kategorije';
      case AppLanguage.spanish:
        return 'Buscar categorías coincidentes';
      case AppLanguage.persian:
        return 'جستجوی دسته های مطابق';
      case AppLanguage.english:
      default:
        return 'Search for matching categories';
    }
  }

  String get createNewCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Neue Kategorien erstellen';
      case AppLanguage.turkish:
        return 'Yeni kategoriler oluştur';
      case AppLanguage.arabic:
        return 'إنشاء فئات جديدة';
      case AppLanguage.bosnian:
        return 'Kreiraj nove kategorije';
      case AppLanguage.spanish:
        return 'Crear nuevas categorías';
      case AppLanguage.persian:
        return 'ایجاد دسته های جدید';
      case AppLanguage.english:
      default:
        return 'Create new categories';
    }
  }

  String get forEachNewAppointment {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Für jeden neuen Termin mit unbekannter Kategorie';
      case AppLanguage.turkish:
        return 'Bilinmeyen kategoriye sahip her yeni etkinlik için';
      case AppLanguage.arabic:
        return 'لكل موعد جديد بفئة غير معروفة';
      case AppLanguage.bosnian:
        return 'Za svaki novi događaj s nepoznatom kategorijom';
      case AppLanguage.spanish:
        return 'Para cada nueva cita con categoría desconocida';
      case AppLanguage.persian:
        return 'برای هر قرار ملاقات جدید با دسته ناشناخته';
      case AppLanguage.english:
      default:
        return 'For each new appointment with unknown category';
    }
  }

  // Status messages
  String get syncingWithGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Synchronisiere mit Google Kalender...';
      case AppLanguage.turkish:
        return 'Google Takvim ile senkronize ediliyor...';
      case AppLanguage.arabic:
        return 'جارٍ المزامنة مع تقويم Google...';
      case AppLanguage.bosnian:
        return 'Sinhronizacija s Google Kalendarom...';
      case AppLanguage.spanish:
        return 'Sincronizando con Calendario de Google...';
      case AppLanguage.persian:
        return 'همگام سازی با تقویم گوگل...';
      case AppLanguage.english:
      default:
        return 'Syncing with Google Calendar...';
    }
  }

  String get syncCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Synchronisation erfolgreich abgeschlossen';
      case AppLanguage.turkish:
        return 'Senkronizasyon başarıyla tamamlandı';
      case AppLanguage.arabic:
        return 'اكتملت المزامنة بنجاح';
      case AppLanguage.bosnian:
        return 'Sinhronizacija uspješno završena';
      case AppLanguage.spanish:
        return 'Sincronización completada con éxito';
      case AppLanguage.persian:
        return 'همگام سازی با موفقیت انجام شد';
      case AppLanguage.english:
      default:
        return 'Synchronization completed successfully';
    }
  }

  String get importingFromGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Importiere von Google Kalender...';
      case AppLanguage.turkish:
        return 'Google Takvim\'den içe aktarılıyor...';
      case AppLanguage.arabic:
        return 'جارٍ الاستيراد من تقويم Google...';
      case AppLanguage.bosnian:
        return 'Uvoz iz Google Kalendara...';
      case AppLanguage.spanish:
        return 'Importando desde Calendario de Google...';
      case AppLanguage.persian:
        return 'در حال واردات از تقویم گوگل...';
      case AppLanguage.english:
      default:
        return 'Importing from Google Calendar...';
    }
  }

  String get exportingToGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Exportiere nach Google Kalender...';
      case AppLanguage.turkish:
        return 'Google Takvim\'e dışa aktarılıyor...';
      case AppLanguage.arabic:
        return 'جارٍ التصدير إلى تقويم Google...';
      case AppLanguage.bosnian:
        return 'Izvoz u Google Kalendar...';
      case AppLanguage.spanish:
        return 'Exportando a Calendario de Google...';
      case AppLanguage.persian:
        return 'در حال صادرات به تقویم گوگل...';
      case AppLanguage.english:
      default:
        return 'Exporting to Google Calendar...';
    }
  }

  String syncSyncError(String error) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Synchronisationsfehler: $error';
      case AppLanguage.turkish:
        return 'Senkronizasyon hatası: $error';
      case AppLanguage.arabic:
        return 'خطأ في المزامنة: $error';
      case AppLanguage.bosnian:
        return 'Greška sinhronizacije: $error';
      case AppLanguage.spanish:
        return 'Error de sincronización: $error';
      case AppLanguage.persian:
        return 'خطای همگام سازی: $error';
      case AppLanguage.english:
      default:
        return 'Synchronization error: $error';
    }
  }

  String importError(String error) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Import-Fehler: $error';
      case AppLanguage.turkish:
        return 'İçe aktarma hatası: $error';
      case AppLanguage.arabic:
        return 'خطأ في الاستيراد: $error';
      case AppLanguage.bosnian:
        return 'Greška uvoza: $error';
      case AppLanguage.spanish:
        return 'Error de importación: $error';
      case AppLanguage.persian:
        return 'خطای واردات: $error';
      case AppLanguage.english:
      default:
        return 'Import error: $error';
    }
  }

  String exportError(String error) {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Export-Fehler: $error';
      case AppLanguage.turkish:
        return 'Dışa aktarma hatası: $error';
      case AppLanguage.arabic:
        return 'خطأ في التصدير: $error';
      case AppLanguage.bosnian:
        return 'Greška izvoza: $error';
      case AppLanguage.spanish:
        return 'Error de exportación: $error';
      case AppLanguage.persian:
        return 'خطای صادرات: $error';
      case AppLanguage.english:
      default:
        return 'Export error: $error';
    }
  }

  String get syncGoogleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender';
      case AppLanguage.turkish:
        return 'Google Takvim';
      case AppLanguage.arabic:
        return 'تقويم Google';
      case AppLanguage.bosnian:
        return 'Google Kalendar';
      case AppLanguage.spanish:
        return 'Calendario de Google';
      case AppLanguage.persian:
        return 'تقویم گوگل';
      case AppLanguage.english:
      default:
        return 'Google Calendar';
    }
  }

  String get syncOutlookCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Outlook';
      case AppLanguage.turkish:
        return 'Outlook';
      case AppLanguage.arabic:
        return 'Outlook';
      case AppLanguage.bosnian:
        return 'Outlook';
      case AppLanguage.spanish:
        return 'Outlook';
      case AppLanguage.persian:
        return 'Outlook';
      case AppLanguage.english:
      default:
        return 'Outlook';
    }
  }

  // ... existing code ...

  String get syncImportCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Import erfolgreich abgeschlossen';
      case AppLanguage.turkish:
        return 'İçe aktarma başarıyla tamamlandı';
      case AppLanguage.arabic:
        return 'اكتمل الاستيراد بنجاح';
      case AppLanguage.bosnian:
        return 'Uvoz uspješno završen';
      case AppLanguage.spanish:
        return 'Importación completada con éxito';
      case AppLanguage.persian:
        return 'واردات با موفقیت انجام شد';
      case AppLanguage.english:
      default:
        return 'Import completed successfully';
    }
  }

  String get syncExportCompleted {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Export erfolgreich abgeschlossen';
      case AppLanguage.turkish:
        return 'Dışa aktarma başarıyla tamamlandı';
      case AppLanguage.arabic:
        return 'اكتمل التصدير بنجاح';
      case AppLanguage.bosnian:
        return 'Izvoz uspješno završen';
      case AppLanguage.spanish:
        return 'Exportación completada con éxito';
      case AppLanguage.persian:
        return 'صادرات با موفقیت انجام شد';
      case AppLanguage.english:
      default:
        return 'Export completed successfully';
    }
  }

  String get categoryLabel => Intl.message('Kategorie', name: 'categoryLabel');
  String get privateCategory => Intl.message('Privat', name: 'privateCategory');

  // ------------------------------
  // Form-Validierung
  // ------------------------------
  String get titleRequired {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Titel ist erforderlich';
      case AppLanguage.turkish:
        return 'Başlık gereklidir';
      case AppLanguage.arabic:
        return 'العنوان مطلوب';
      case AppLanguage.bosnian:
        return 'Naslov je obavezan';
      case AppLanguage.spanish:
        return 'El título es obligatorio';
      case AppLanguage.persian:
        return 'عنوان الزامی است';
      case AppLanguage.english:
      default:
        return 'Title is required';
    }
  }

  String get appointmentTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Titel des Termins';
      case AppLanguage.turkish:
        return 'Randevu başlığı';
      case AppLanguage.arabic:
        return 'عنوان الموعد';
      case AppLanguage.bosnian:
        return 'Naslov termina';
      case AppLanguage.spanish:
        return 'Título de la cita';
      case AppLanguage.persian:
        return 'عنوان قرار ملاقات';
      case AppLanguage.english:
      default:
        return 'Appointment title';
    }
  }
}
