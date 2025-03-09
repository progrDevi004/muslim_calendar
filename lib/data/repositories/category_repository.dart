// lib/data/repositories/category_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:muslim_calendar/models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> insertCategory(CategoryModel category) async {
    final db = await dbHelper.database;
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
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CategoryModel?> getCategory(int id) async {
    final db = await dbHelper.database;
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
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Sucht eine Kategorie anhand des Namens oder erstellt sie, wenn sie nicht existiert.
  /// Gibt die gefundene oder neu erstellte Kategorie zurück.
  Future<CategoryModel> getCategoryByNameOrCreate(String name,
      {Color? color}) async {
    final db = await dbHelper.database;

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
      // Bei Fehler erstelle die Tabelle und versuche es erneut
      await db.execute(
        'CREATE TABLE IF NOT EXISTS categories(id INTEGER PRIMARY KEY, name TEXT, color INTEGER, isDefault INTEGER)',
      );

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
