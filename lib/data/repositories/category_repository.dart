// lib/data/repositories/category_repository.dart

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
}
