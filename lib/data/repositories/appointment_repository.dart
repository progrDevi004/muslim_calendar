//data/repositories/appointment_repository.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/appointment_model.dart';
import '../../models/category_model.dart';
import '../database_helper.dart';

class AppointmentRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> insertAppointment(AppointmentModel appointment) async {
    final db = await dbHelper.database;
    print(appointment.recurrenceRule);
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

    debugPrint("Geladene Termine: ${maps.length}");

    // Alle Kategorien laden
    List<CategoryModel> allCategories = [];
    try {
      final List<Map<String, dynamic>> categoryMaps =
          await db.query('categories');
      allCategories =
          categoryMaps.map((m) => CategoryModel.fromMap(m)).toList();

      debugPrint("Geladene Kategorien für Termine: ${allCategories.length}");
    } catch (e) {
      debugPrint("Fehler beim Laden der Kategorien: $e");
      // Standard-Kategorie als Fallback
      allCategories = [
        CategoryModel(
          id: 1,
          name: 'Privat',
          color: const Color(0xFF2196F3),
          isDefault: true,
        ),
      ];
    }

    // Standardkategorie definieren (für Termine ohne Kategorie)
    final standardCategory = allCategories.firstWhere((cat) => cat.isDefault,
        orElse: () => CategoryModel(
              id: 1,
              name: 'Privat',
              color: const Color(0xFF2196F3),
              isDefault: true,
            ));

    // Termine konvertieren und dabei Kategorien richtig zuordnen
    final appointments = <AppointmentModel>[];

    for (var map in maps) {
      // Kategorie-ID aus dem Termin-Map extrahieren
      final categoryId = map['categoryId'] as int?;

      // Wenn keine Kategorie zugewiesen ist, Standard-Kategorie verwenden
      if (categoryId == null) {
        final appointment = AppointmentModel.fromMap({
          ...map,
          'categoryId': standardCategory.id,
        });
        appointments.add(appointment);
        continue;
      }

      // Prüfen, ob die Kategorie existiert
      final category = allCategories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => standardCategory,
      );

      // Termin mit korrekter Kategorie erstellen
      final appointment = AppointmentModel.fromMap({
        ...map,
        'categoryId': category.id,
      });
      appointments.add(appointment);
    }

    return appointments;
  }

  Future<AppointmentModel?> getAppointmentByExternalIdGoogle(
      String externalId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'externalIdGoogle = ?',
      whereArgs: [externalId],
    );
    if (maps.isNotEmpty) {
      return AppointmentModel.fromMap(maps.first);
    }
    return null;
  }

  // Methode zum Laden aller Kategorien
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await dbHelper.database;

    try {
      // Versuche die Kategorien zu laden - falls die Tabelle existiert
      final List<Map<String, dynamic>> maps = await db.query('categories');
      return maps.map((m) => CategoryModel.fromMap(m)).toList();
    } catch (e) {
      // Falls die Tabelle nicht existiert oder ein anderer Fehler auftritt,
      // geben wir eine Standard-Kategorie zurück
      return [
        CategoryModel(
          id: 1,
          name: 'Standard',
          color: const Color(0xFF2196F3),
          isDefault: true,
        ),
        CategoryModel(
          id: 2,
          name: 'Import',
          color: const Color(0xFF4CAF50), // Grün
          isDefault: false,
        ),
      ];
    }
  }

  // Methode zum Laden einer Kategorie nach ID
  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await dbHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return CategoryModel.fromMap(maps.first);
      }

      // Wenn keine Kategorie gefunden wurde, Standard-Kategorie zurückgeben
      return CategoryModel(
        id: 1,
        name: 'Privat',
        color: const Color(0xFF2196F3),
        isDefault: true,
      );
    } catch (e) {
      // Falls ein Fehler auftritt, Standard-Kategorie zurückgeben
      return CategoryModel(
        id: 1,
        name: 'Privat',
        color: const Color(0xFF2196F3),
        isDefault: true,
      );
    }
  }

  // Methode zum Speichern einer neuen Kategorie
  Future<int> insertCategory(CategoryModel category) async {
    final db = await dbHelper.database;

    try {
      return await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Falls die Tabelle nicht existiert, erstelle sie
      await db.execute(
        'CREATE TABLE IF NOT EXISTS categories(id INTEGER PRIMARY KEY, name TEXT, color INTEGER, isDefault INTEGER)',
      );

      // Versuche erneut einzufügen
      return await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
