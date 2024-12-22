//data/repositories/appointment_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../models/appointment_model.dart';
import '../database_helper.dart';

class AppointmentRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> insertAppointment(AppointmentModel appointment) async {
    final db = await dbHelper.database;
    return await db.insert(
      'appointments',
      appointment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateAppointment(AppointmentModel appointment) async {
    final db = await dbHelper.database;
    if (appointment.id == null) {
      throw ArgumentError('Appointment ID cannot be null');
    }
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<void> deleteAppointment(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<AppointmentModel?> getAppointment(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AppointmentModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AppointmentModel>> getAllAppointments() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('appointments');
    return maps.map((m) => AppointmentModel.fromMap(m)).toList();
  }
}
