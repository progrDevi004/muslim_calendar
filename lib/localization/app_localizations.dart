// lib/localization/app_localizations.dart

import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/enums.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

enum AppLanguage { english, german, turkish, arabic }

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
      case AppLanguage.english:
      default:
        return "English";
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
      case AppLanguage.english:
      default:
        return 'Settings';
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
      case AppLanguage.english:
      default:
        return 'Delete';
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
      case AppLanguage.english:
      default:
        return 'Prayer Time';
    }
  }

  // >>> NEU: Übersetzungen für die Gebetszeiten
  String getPrayerTimeLabel(PrayerTime pt) {
    // Hinweis: Für Deutsch und Englisch bleibt es "Fajr, Dhuhr, Asr, Maghrib, Isha"
    // Für Türkisch => "Sabah, Öğlen, İkindi, Akşam, Yatsı"
    // Für Arabisch => 'فجر', 'ظهر', 'عصر', 'مغرب', 'عشاء'
    switch (pt) {
      case PrayerTime.fajr:
        switch (_currentLanguage) {
          case AppLanguage.turkish:
            return 'Sabah';
          case AppLanguage.arabic:
            return 'فجر';
          case AppLanguage.german: // => "Fajr"
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
          case AppLanguage.german:
          case AppLanguage.english:
          default:
            return 'Isha';
        }
    }
  }

  // >>> NEU: Übersetzungen für TimeRelation (before, after)
  String getTimeRelationLabel(TimeRelation tr) {
    // "before" => z. B. Deutsch = "Vorher", Türkisch = "Önce"
    // "after"  => z. B. Deutsch = "Nachher", Türkisch = "Sonra"
    switch (tr) {
      case TimeRelation.before:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Vorher';
          case AppLanguage.turkish:
            return 'Önce';
          case AppLanguage.arabic:
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
      case AppLanguage.english:
      default:
        return 'Recurring Event';
    }
  }

  String get recurrenceType {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wiederholungstyp';
      case AppLanguage.turkish:
        return 'Tekrar Türü';
      case AppLanguage.arabic:
        return 'نوع التكرار';
      case AppLanguage.english:
      default:
        return 'Recurrence Type';
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
      case AppLanguage.english:
      default:
        return 'Select';
    }
  }

  // ------------------------------
  // Wiederholungs-Logik (für Dropdown)
  // ------------------------------
  // Schon vorhanden: daily, weekly, monthly, yearly
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
          case AppLanguage.english:
          default:
            return 'Yearly';
        }
    }
  }

  // Schon vorhanden: noEndDate, endDate, count
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
          case AppLanguage.english:
          default:
            return 'No End Date';
        }
      case RecurrenceRange.endDate:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Endet an bestimmtem Tag';
          case AppLanguage.turkish:
            return 'Belirli bir tarihte sona erer';
          case AppLanguage.arabic:
            return 'ينتهي بتاريخ معين';
          case AppLanguage.english:
          default:
            return 'End On Specific Day';
        }
      case RecurrenceRange.count:
        switch (_currentLanguage) {
          case AppLanguage.german:
            return 'Endet nach Anzahl';
          case AppLanguage.turkish:
            return 'Belirli bir sayıda sona erer';
          case AppLanguage.arabic:
            return 'ينتهي بعد عدد محدد';
          case AppLanguage.english:
          default:
            return 'End After Count';
        }
    }
  }

  // ------------------------------
  // Einstellungen / Settings
  // ------------------------------
  String get locationSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Standort-Einstellungen';
      case AppLanguage.turkish:
        return 'Konum Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات الموقع';
      case AppLanguage.english:
      default:
        return 'Location Settings';
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
      case AppLanguage.english:
      default:
        return 'Automatic Location';
    }
  }

  String get automaticLocationSubtitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bestimmt Ihren Standort per GPS';
      case AppLanguage.turkish:
        return 'Konumu GPS üzerinden belirler';
      case AppLanguage.arabic:
        return 'يحدد موقعك عبر نظام تحديد المواقع العالمي (GPS)';
      case AppLanguage.english:
      default:
        return 'Determines your location via GPS';
    }
  }

  String get notificationSettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Benachrichtigungs-Einstellungen';
      case AppLanguage.turkish:
        return 'Bildirim Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات الإشعارات';
      case AppLanguage.english:
      default:
        return 'Notification Settings';
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
      case AppLanguage.english:
      default:
        return 'Receive alerts for appointments and prayer times';
    }
  }

  String get displaySettings {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Anzeige-Einstellungen';
      case AppLanguage.turkish:
        return 'Görüntü Ayarları';
      case AppLanguage.arabic:
        return 'إعدادات العرض';
      case AppLanguage.english:
      default:
        return 'Display Settings';
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
      case AppLanguage.english:
      default:
        return 'Enable dark theme';
    }
  }

  // ------------------------------
  // >>> NEU: Dashboard-Strings
  // ------------------------------
  String get welcomeBack {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Willkommen zurück';
      case AppLanguage.turkish:
        return 'Tekrar hoş geldiniz';
      case AppLanguage.arabic:
        return 'مرحبًا بعودتك';
      case AppLanguage.english:
      default:
        return 'Welcome back';
    }
  }

  String get today {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Heute';
      case AppLanguage.turkish:
        return 'Bugün';
      case AppLanguage.arabic:
        return 'اليوم';
      case AppLanguage.english:
      default:
        return 'Today';
    }
  }

  String get calendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kalender';
      case AppLanguage.turkish:
        return 'Takvim';
      case AppLanguage.arabic:
        return 'التقويم';
      case AppLanguage.english:
      default:
        return 'Calendar';
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
      case AppLanguage.english:
      default:
        return 'Weather';
    }
  }

  String get upcomingTasksLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Termine heute';
      case AppLanguage.turkish:
        return 'Bugünkü Randevular';
      case AppLanguage.arabic:
        return 'المهمة القادمة';
      case AppLanguage.english:
      default:
        return 'Appointments today';
    }
  }

  String get minutes {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'm';
      case AppLanguage.turkish:
        return 'Dakika';
      case AppLanguage.arabic:
        return 'دقيقة';
      case AppLanguage.english:
      default:
        return 'm';
    }
  }

  String get location {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Ort';
      case AppLanguage.turkish:
        return 'Bölge';
      case AppLanguage.arabic:
        return 'الشهر';
      case AppLanguage.english:
      default:
        return 'Location';
    }
  }

  // ========================================
  // Reminder-Strings
  // ========================================
  String get reminderTitle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erinnerung';
      case AppLanguage.turkish:
        return 'Hatırlatma';
      case AppLanguage.arabic:
        return 'تذكير';
      case AppLanguage.english:
      default:
        return 'Reminder';
    }
  }

  String get reminderBody {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Vergiss deinen Termin nicht!';
      case AppLanguage.turkish:
        return 'Randevunuzu unutmayın!';
      case AppLanguage.arabic:
        return 'لا تنس موعدك!';
      case AppLanguage.english:
      default:
        return 'Don\'t forget your appointment!';
    }
  }

  // ------------------------------
  // >>> Neue Strings für SettingsPage
  // ------------------------------
  String get language {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Sprache';
      case AppLanguage.turkish:
        return 'Dil';
      case AppLanguage.arabic:
        return 'اللغة';
      case AppLanguage.english:
      default:
        return 'Language';
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
      case AppLanguage.english:
      default:
        return 'Time Format';
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
        return 'حاليًا يتم استخدام تنسيق ص / م';
      case AppLanguage.english:
      default:
        return 'Currently, AM/PM format is active';
    }
  }

  // ------------------------------
  // >>> Neue Strings für SettingsPage SYNC KALENDAR
  // ------------------------------
  String get calendarSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kalendersynchronisation';
      case AppLanguage.turkish:
        return 'Takvim Senkronizasyonu';
      case AppLanguage.arabic:
        return 'مزامنة التقويم';
      case AppLanguage.english:
      default:
        return 'Calendar Sync';
    }
  }

  String get googleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender';
      case AppLanguage.turkish:
        return 'Google Takvimi';
      case AppLanguage.arabic:
        return 'تقويم جوجل';
      case AppLanguage.english:
      default:
        return 'Google Calendar';
    }
  }

  String get appleCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Apple Kalender';
      case AppLanguage.turkish:
        return 'Apple Takvimi';
      case AppLanguage.arabic:
        return 'تقويم آبل';
      case AppLanguage.english:
      default:
        return 'Apple Calendar';
    }
  }

  String get outlookCalendar {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Outlook Kalender';
      case AppLanguage.turkish:
        return 'Outlook Takvimi';
      case AppLanguage.arabic:
        return 'تقويم أوتلوك';
      case AppLanguage.english:
      default:
        return 'Outlook Calendar';
    }
  }

  String get connectToService {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Mit Dienst verbinden';
      case AppLanguage.turkish:
        return 'Hizmete Bağlan';
      case AppLanguage.arabic:
        return 'الاتصال بالخدمة';
      case AppLanguage.english:
      default:
        return 'Connect to service';
    }
  }

  String get connected {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Verbunden';
      case AppLanguage.turkish:
        return 'Bağlandı';
      case AppLanguage.arabic:
        return 'متصل';
      case AppLanguage.english:
      default:
        return 'Connected';
    }
  }

  String get dailySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Tägliche Synchronisation';
      case AppLanguage.turkish:
        return 'Günlük Senkronizasyon';
      case AppLanguage.arabic:
        return 'مزامنة يومية';
      case AppLanguage.english:
      default:
        return 'Daily Sync';
    }
  }

  String get weeklySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Wöchentliche Synchronisation';
      case AppLanguage.turkish:
        return 'Haftalık Senkronizasyon';
      case AppLanguage.arabic:
        return 'مزامنة أسبوعية';
      case AppLanguage.english:
      default:
        return 'Weekly Sync';
    }
  }

  String get monthlySync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Monatliche Synchronisation';
      case AppLanguage.turkish:
        return 'Aylık Senkronizasyon';
      case AppLanguage.arabic:
        return 'مزامنة شهرية';
      case AppLanguage.english:
      default:
        return 'Monthly Sync';
    }
  }

  String get noSync {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kein Synchronisation';
      case AppLanguage.turkish:
        return 'Senkronizasyon yok';
      case AppLanguage.arabic:
        return 'لا يوجد مزامنة';
      case AppLanguage.english:
      default:
        return 'No Sync';
    }
  }

  String get connectGoogle {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Google Kalender verbinden';
      case AppLanguage.turkish:
        return 'Google Takvimine Bağlan';
      case AppLanguage.arabic:
        return 'الاتصال بتقويم جوجل';
      case AppLanguage.english:
      default:
        return 'Connect Google Calendar';
    }
  }

  String get connectGoogleDescription {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Dies öffnet die Google Anmeldung, um deinen Kalender zu verbinden';
      case AppLanguage.turkish:
        return 'Bu, takviminizi bağlamak için Google Girişini açacaktır';
      case AppLanguage.arabic:
        return 'سيفتح هذا تسجيل الدخول إلى جوجل لربط تقويمك';
      case AppLanguage.english:
      default:
        return 'This will open Google Sign-In to connect your calendar';
    }
  }

  String get connect {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Verbinden';
      case AppLanguage.turkish:
        return 'Bağlan';
      case AppLanguage.arabic:
        return 'اتصال';
      case AppLanguage.english:
      default:
        return 'Connect';
    }
  }
  // Bağlantı yönetimi ile ilgili terimler
String get manageConnection {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Verbindung verwalten';
    case AppLanguage.turkish:
      return 'Bağlantıyı Yönet';
    case AppLanguage.arabic:
      return 'إدارة الاتصال';
    case AppLanguage.english:
    default:
      return 'Manage Connection';
  }
}

String get importFromCalendar {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Vom Kalender importieren';
    case AppLanguage.turkish:
      return 'Takvimden İçe Aktar';
    case AppLanguage.arabic:
      return 'استيراد من التقويم';
    case AppLanguage.english:
    default:
      return 'Import from Calendar';
  }
}

String get exportToCalendar {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'In Kalender exportieren';
    case AppLanguage.turkish:
      return 'Takvime Dışa Aktar';
    case AppLanguage.arabic:
      return 'تصدير إلى التقويم';
    case AppLanguage.english:
    default:
      return 'Export to Calendar';
  }
}

// Hata ve bildirim mesajları
String syncError(String error) {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Synchronisierungsfehler: $error';
    case AppLanguage.turkish:
      return 'Senkronizasyon hatası: $error';
    case AppLanguage.arabic:
      return 'خطأ في المزامنة: $error';
    case AppLanguage.english:
    default:
      return 'Sync Error: $error';
  }
}

String get success {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Erfolg';
    case AppLanguage.turkish:
      return 'Başarılı';
    case AppLanguage.arabic:
      return 'نجاح';
    case AppLanguage.english:
    default:
      return 'Success';
  }
}

String get error {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Fehler';
    case AppLanguage.turkish:
      return 'Hata';
    case AppLanguage.arabic:
      return 'خطأ';
    case AppLanguage.english:
    default:
      return 'Error';
  }
}

String get ok {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'OK';
    case AppLanguage.turkish:
      return 'Tamam';
    case AppLanguage.arabic:
      return 'موافق';
    case AppLanguage.english:
    default:
      return 'OK';
  }
}

// Bağlantı yönetimi diyalog metinleri
String connectionError(String error) {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Verbindungsfehler: $error';
    case AppLanguage.turkish:
      return 'Bağlantı hatası: $error';
    case AppLanguage.arabic:
      return 'خطأ في الاتصال: $error';
    case AppLanguage.english:
    default:
      return 'Connection Error: $error';
  }
}

String get disconnect {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Trennen';
    case AppLanguage.turkish:
      return 'Bağlantıyı Kes';
    case AppLanguage.arabic:
      return 'قطع الاتصال';
    case AppLanguage.english:
    default:
      return 'Disconnect';
  }
}

String get manageConnectionPrompt {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Was möchten Sie mit dieser Verbindung tun?';
    case AppLanguage.turkish:
      return 'Bu bağlantıyla ne yapmak istiyorsunuz?';
    case AppLanguage.arabic:
      return 'ماذا تريد أن تفعل بهذا الاتصال؟';
    case AppLanguage.english:
    default:
      return 'What would you like to do with this connection?';
  }
}

// Senkronizasyon başarı mesajları
String importSuccess(String serviceName) {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Erfolgreich importiert aus $serviceName';
    case AppLanguage.turkish:
      return '$serviceName bağlantısından başarıyla içe aktarıldı';
    case AppLanguage.arabic:
      return 'تم الاستيراد بنجاح من $serviceName';
    case AppLanguage.english:
    default:
      return 'Successfully imported from $serviceName';
  }
}

String exportSuccess(String serviceName) {
  switch (_currentLanguage) {
    case AppLanguage.german:
      return 'Erfolgreich exportiert nach $serviceName';
    case AppLanguage.turkish:
      return '$serviceName bağlantısına başarıyla dışa aktarıldı';
    case AppLanguage.arabic:
      return 'تم التصدير بنجاح إلى $serviceName';
    case AppLanguage.english:
    default:
      return 'Successfully exported to $serviceName';
  }
}

  // ------------------------------
  // >>> NEUE STRINGS FÜR APPOINTMENT_CREATION_PAGE
  // ------------------------------
  String get pleaseSelectStartTimeError {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Bitte wähle eine Startzeit aus.';
      case AppLanguage.turkish:
        return 'Lütfen bir başlangıç zamanı seçin.';
      case AppLanguage.arabic:
        return 'من فضلك اختر وقت البدء.';
      case AppLanguage.english:
      default:
        return 'Please select a start time.';
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
      case AppLanguage.english:
      default:
        return 'Advanced Options';
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
      case AppLanguage.english:
      default:
        return 'Fewer Options';
    }
  }

  String get reminderInMinutes {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Erinnerung (Min. vorher)';
      case AppLanguage.turkish:
        return 'Hatırlatma (Dakika önce)';
      case AppLanguage.arabic:
        return 'تذكير (دقائق قبل الموعد)';
      case AppLanguage.english:
      default:
        return 'Reminder (min. before)';
    }
  }

  String get selectCategoryLabel {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kategorie wählen';
      case AppLanguage.turkish:
        return 'Kategori Seçiniz';
      case AppLanguage.arabic:
        return 'اختر الفئة';
      case AppLanguage.english:
      default:
        return 'Select Category';
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

  // >>> Getter für "filterCategories"
  String get filterCategories {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Kategorien filtern';
      case AppLanguage.turkish:
        return 'Kategorileri Filtrele';
      case AppLanguage.arabic:
        return 'تصفية الفئات';
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
      case AppLanguage.english:
      default:
        return 'Time';
    }
  }

  String get qiblaDirection {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Qibla Richtung';
      case AppLanguage.turkish:
        return 'Kıble yönü';
      case AppLanguage.arabic:
        return 'اتجاه القبلة';
      case AppLanguage.english:
      default:
        return 'Qibla direction';
    }
  }

  String get endDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Enddatum';
      case AppLanguage.turkish:
        return 'Bitiş tarihi';
      case AppLanguage.arabic:
        return 'تاريخ الانتهاء';
      case AppLanguage.english:
      default:
        return 'End date';
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
}
