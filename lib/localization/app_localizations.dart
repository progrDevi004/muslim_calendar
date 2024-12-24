// lib/localization/app_localizations.dart

import 'package:flutter/material.dart';
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
  String getRecurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return _currentLanguage == AppLanguage.german
            ? 'Täglich'
            : _currentLanguage == AppLanguage.turkish
                ? 'Günlük'
                : _currentLanguage == AppLanguage.arabic
                    ? 'يومي'
                    : 'Daily';
      case RecurrenceType.weekly:
        return _currentLanguage == AppLanguage.german
            ? 'Wöchentlich'
            : _currentLanguage == AppLanguage.turkish
                ? 'Haftalık'
                : _currentLanguage == AppLanguage.arabic
                    ? 'أسبوعي'
                    : 'Weekly';
      case RecurrenceType.monthly:
        return _currentLanguage == AppLanguage.german
            ? 'Monatlich'
            : _currentLanguage == AppLanguage.turkish
                ? 'Aylık'
                : _currentLanguage == AppLanguage.arabic
                    ? 'شهري'
                    : 'Monthly';
      case RecurrenceType.yearly:
        return _currentLanguage == AppLanguage.german
            ? 'Jährlich'
            : _currentLanguage == AppLanguage.turkish
                ? 'Yıllık'
                : _currentLanguage == AppLanguage.arabic
                    ? 'سنوي'
                    : 'Yearly';
    }
  }

  String getRecurrenceRangeLabel(RecurrenceRange range) {
    switch (range) {
      case RecurrenceRange.noEndDate:
        return _currentLanguage == AppLanguage.german
            ? 'Ohne Enddatum'
            : _currentLanguage == AppLanguage.turkish
                ? 'Bitiş Tarihi Yok'
                : _currentLanguage == AppLanguage.arabic
                    ? 'بدون تاريخ انتهاء'
                    : 'No End Date';
      case RecurrenceRange.endDate:
        return _currentLanguage == AppLanguage.german
            ? 'Endet an bestimmtem Tag'
            : _currentLanguage == AppLanguage.turkish
                ? 'Belirli bir tarihte sona erer'
                : _currentLanguage == AppLanguage.arabic
                    ? 'ينتهي بتاريخ معين'
                    : 'End On Specific Day';
      case RecurrenceRange.count:
        return _currentLanguage == AppLanguage.german
            ? 'Endet nach Anzahl'
            : _currentLanguage == AppLanguage.turkish
                ? 'Belirli bir sayıda sona erer'
                : _currentLanguage == AppLanguage.arabic
                    ? 'ينتهي بعد عدد محدد'
                    : 'End After Count';
    }
  }

  String get recurrenceOptionNoEndDate {
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
  }

  String get recurrenceOptionEndDate {
    switch (_currentLanguage) {
      case AppLanguage.german:
        return 'Endet an bestimmtem Tag';
      case AppLanguage.turkish:
        return 'Belirli bir tarihte sona erer';
      case AppLanguage.arabic:
        return 'ينتهي بتاريخ معين';
      case AppLanguage.english:
      default:
        return 'Specific End Date';
    }
  }

  String get recurrenceOptionCount {
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
        return 'Aufgaben heute';
      case AppLanguage.turkish:
        return 'Bugünkü Görevler';
      case AppLanguage.arabic:
        return 'المهمة القادمة';
      case AppLanguage.english:
      default:
        return 'Tasks today';
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
}
