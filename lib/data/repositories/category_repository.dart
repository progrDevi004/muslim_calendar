// lib/data/repositories/category_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:muslim_calendar/models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Hilfsmethode um Farbwert zu extrahieren
  int _colorToInt(Color color) {
    // Ignoriere den Deprecation-Hinweis, da wir den Int-Wert für die DB benötigen
    // ignore: deprecated_member_use
    return color.value;
  }

  // Stellt sicher, dass die Kategorie-Tabelle existiert
  Future<void> _ensureCategoryTableExists(Database db) async {
    try {
      // Überprüfen, ob die Tabelle existiert
      await db.query('categories', limit: 1);

      // Neuer Code: Prüfe, ob die Spalte 'color' existiert
      bool colorColumnExists = false;
      try {
        await db.query('categories', columns: ['color'], limit: 1);
        colorColumnExists = true;
        debugPrint("Spalte 'color' existiert bereits.");
      } catch (e) {
        debugPrint("Spalte 'color' fehlt: $e");
      }

      // Wenn die Spalte 'color' nicht existiert, füge sie hinzu
      if (!colorColumnExists) {
        debugPrint("Füge Spalte 'color' hinzu...");
        try {
          // ignore: deprecated_member_use
          await db.execute(
              'ALTER TABLE categories ADD COLUMN color INTEGER DEFAULT ${Colors.blue.value}');

          // Setze die Standardfarben
          await db.update('categories', {'color': _colorToInt(Colors.blue)},
              where: 'id = 1');
          await db.update('categories', {'color': _colorToInt(Colors.red)},
              where: 'id = 2');
          await db.update('categories', {'color': _colorToInt(Colors.green)},
              where: 'id = 3');

          debugPrint(
              "Spalte 'color' erfolgreich hinzugefügt und Standardfarben gesetzt.");
        } catch (alterError) {
          debugPrint("Fehler beim Hinzufügen der Spalte 'color': $alterError");
        }
      }

      // Prüfen, ob die Spalte 'isDefault' existiert
      try {
        await db.query('categories', columns: ['isDefault'], limit: 1);
        debugPrint("Spalte 'isDefault' existiert bereits.");
      } catch (e) {
        // Spalte 'isDefault' existiert nicht, füge sie hinzu
        debugPrint("Spalte 'isDefault' existiert nicht. Füge sie hinzu...");
        await db.execute(
            'ALTER TABLE categories ADD COLUMN isDefault INTEGER DEFAULT 0');

        // Setze die Standard-Kategorie (ID 1) auf isDefault=1
        await db.update(
          'categories',
          {'isDefault': 1},
          where: 'id = 1',
        );
      }
    } catch (e) {
      // Tabelle existiert nicht, erstellen wir sie
      debugPrint("Kategorien-Tabelle existiert nicht. Erstelle sie neu...");
      await db.execute(
        'CREATE TABLE IF NOT EXISTS categories(id INTEGER PRIMARY KEY, name TEXT, color INTEGER, isDefault INTEGER)',
      );

      // Standard-Kategorien einfügen
      await db.insert(
        'categories',
        {
          'id': 1,
          'name': 'Privat',
          'color': _colorToInt(Colors.blue),
          'isDefault': 1
        },
      );

      await db.insert(
        'categories',
        {
          'id': 2,
          'name': 'Islam',
          'color': _colorToInt(Colors.red),
          'isDefault': 0
        },
      );

      await db.insert(
        'categories',
        {
          'id': 3,
          'name': 'Geschäftlich',
          'color': _colorToInt(Colors.green),
          'isDefault': 0
        },
      );

      debugPrint("Standard-Kategorien wurden erstellt mit korrekten Farben.");
    }
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await dbHelper.database;

    // Stellen Sie sicher, dass die Tabelle existiert
    await _ensureCategoryTableExists(db);

    debugPrint("Speichere Kategorie: ${category.toString()}");

    // Prüfen, ob es einen Konflikt mit einer vorhandenen Kategorie gibt
    final existingCategories = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [category.name],
    );

    if (existingCategories.isNotEmpty) {
      // Es gibt bereits eine Kategorie mit diesem Namen, wir aktualisieren sie
      final existingId = existingCategories.first['id'] as int;
      return await db.update(
        'categories',
        {
          'name': category.name,
          'color': _colorToInt(category.color),
          'isDefault': category.isDefault ? 1 : 0
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
    }

    // Wir fügen eine neue Kategorie ein
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    if (category.id == null) {
      throw ArgumentError('Category ID cannot be null');
    }

    debugPrint("Aktualisiere Kategorie: ${category.toString()}");

    return await db.update(
      'categories',
      {
        'name': category.name,
        'color': _colorToInt(category.color),
        'isDefault': category.isDefault ? 1 : 0
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await dbHelper.database;

    // Stellen Sie sicher, dass die Tabelle korrekt ist
    await _ensureCategoryTableExists(db);

    try {
      // Versuchen zu prüfen, ob es sich um eine Standard-Kategorie handelt
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        columns: ['id', 'isDefault'],
        where: 'id = ?',
        whereArgs: [id],
      );

      // Verhindern, dass ID 1, 2 oder 3 (Privat, Islam, Geschäftlich) gelöscht werden
      if (id == 1 || (maps.isNotEmpty && maps.first['isDefault'] == 1)) {
        throw Exception('Standard-Kategorie können nicht gelöscht werden.');
      }
    } catch (e) {
      // Falls obige Abfrage einen Fehler wirft, prüfen wir ID direkt
      if (id == 1) {
        throw Exception('Standard-Kategorie können nicht gelöscht werden.');
      }
      debugPrint("Warnung bei Kategorie-Löschprüfung: $e");
      // Fahre fort, da wir manuell auf Standard-IDs geprüft haben
    }

    // Zuerst: Aktualisiere alle Termine, die diese Kategorie verwenden
    try {
      // Aktualisiere alle Termine mit dieser Kategorie auf die Standard-Kategorie (ID 1)
      await db.update(
        'appointments',
        {'categoryId': 1},
        where: 'categoryId = ?',
        whereArgs: [id],
      );
      debugPrint(
          "Termine mit Kategorie $id wurden zur Standard-Kategorie verschoben.");
    } catch (e) {
      debugPrint("Fehler beim Aktualisieren von Terminen: $e");
      // Wir machen weiter, auch wenn das Aktualisieren fehlschlägt
    }

    // Löschen der Kategorie
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    debugPrint("Kategorie gelöscht: $id");
  }

  Future<CategoryModel?> getCategory(int id) async {
    final db = await dbHelper.database;

    // Stellen Sie sicher, dass die Tabelle existiert
    await _ensureCategoryTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await dbHelper.database;

    // Stellen Sie sicher, dass die Tabelle existiert
    await _ensureCategoryTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query('categories');

    debugPrint("Geladene Kategorien: ${maps.length}");
    for (final map in maps) {
      debugPrint(
          "Kategorie: id=${map['id']}, name=${map['name']}, color=${map['color']}");
    }

    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Sucht eine Kategorie anhand des Namens oder erstellt sie, wenn sie nicht existiert.
  /// Gibt die gefundene oder neu erstellte Kategorie zurück.
  Future<CategoryModel> getCategoryByNameOrCreate(String name,
      {Color? color}) async {
    final db = await dbHelper.database;

    // Stellen Sie sicher, dass die Tabelle existiert
    await _ensureCategoryTableExists(db);

    try {
      // Suche nach Kategorie mit dem angegebenen Namen (case-insensitive)
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        where: 'LOWER(name) = ?',
        whereArgs: [name.toLowerCase()],
      );

      if (maps.isNotEmpty) {
        // Kategorie existiert, gebe sie zurück
        return CategoryModel.fromMap(maps.first);
      } else {
        // Zufällige Farbe, wenn keine angegeben wurde
        final randomColor = color ??
            Color(0xFF000000 |
                (DateTime.now().millisecondsSinceEpoch & 0xFFFFFF));

        // Kategorie existiert nicht, erstelle sie
        final newCategory = CategoryModel.newCategory(
          name: name,
          color: randomColor,
        );

        final id = await insertCategory(newCategory);

        // Returne die neue Kategorie mit der generierten ID
        return CategoryModel(
          id: id,
          name: newCategory.name,
          color: newCategory.color,
          isDefault: newCategory.isDefault,
        );
      }
    } catch (e) {
      debugPrint("Fehler beim Suchen/Erstellen der Kategorie: $e");

      // Zufällige Farbe, wenn keine angegeben wurde
      final randomColor = color ??
          Color(
              0xFF000000 | (DateTime.now().millisecondsSinceEpoch & 0xFFFFFF));

      // Erstelle die Kategorie
      final newCategory = CategoryModel.newCategory(
        name: name,
        color: randomColor,
      );

      final id = await insertCategory(newCategory);

      return CategoryModel(
        id: id,
        name: newCategory.name,
        color: newCategory.color,
        isDefault: newCategory.isDefault,
      );
    }
  }
}
