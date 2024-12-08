import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'prayer_time_appointment.dart';
import '../database/database_helper.dart';

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<dynamic> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }

  void addAppointment(Appointment appointment) {
    appointments!.add(appointment);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  void updateAppointment(int index, Appointment appointment) {
    appointments![index] = appointment;
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  void removeAppointment(int index) {
    appointments!.removeAt(index);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  void addPrayerTimeAppointment(PrayerTimeAppointment appointment) {
    appointments!.add(appointment);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  void updatePrayerTimeAppointment(int index, PrayerTimeAppointment appointment) {
    appointments![index] = appointment;
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  void removePrayerTimeAppointment(int index) {
    appointments!.removeAt(index);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  // Veritabanından tüm randevuları yükleyen fonksiyon
  Future<void> loadAppointmentsFromDatabase() async {
    final dbHelper = DatabaseHelper();
    final loadedAppointments = await dbHelper.getAllAppointments();
    appointments!.clear();
    appointments!.addAll(loadedAppointments);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  // Veritabanından belirli bir tarih aralığındaki randevuları yükleyen fonksiyon
  Future<void> loadAppointmentsForDateRange(DateTime start, DateTime end) async {
    final dbHelper = DatabaseHelper();
    final loadedAppointments = await dbHelper.getAppointmentsForDateRange(start, end);
    appointments!.clear();
    appointments!.addAll(loadedAppointments);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  // Bir randevuyu veritabanında güncelleyen ve listeyi güncelleyen fonksiyon
  Future<void> updateAndSaveAppointment(PrayerTimeAppointment appointment) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateAppointment(appointment);
    final index = appointments!.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      updatePrayerTimeAppointment(index, appointment);
    }
  }

  // Bir randevuyu veritabanından silen ve listeden kaldıran fonksiyon
  Future<void> deleteAndRemoveAppointment(int appointmentId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteAppointment(appointmentId);
    final index = appointments!.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      removePrayerTimeAppointment(index);
    }
  }
}