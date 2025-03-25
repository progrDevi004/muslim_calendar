import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

class ProjectRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> ensureProjectTableExists() async {
    final db = await _databaseHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 2,
        progress INTEGER NOT NULL DEFAULT 0,
        categoryId INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (categoryId) REFERENCES categories (id) 
          ON DELETE CASCADE
      )
    ''');
  }

  // Projekt einfügen
  Future<int> insertProject(ProjectModel project) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    return await db.insert('projects', project.toMap());
  }

  // Projekt aktualisieren
  Future<int> updateProject(ProjectModel project) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  // Projekt löschen
  Future<int> deleteProject(int id) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Alle Projekte abrufen
  Future<List<ProjectModel>> getAllProjects() async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    final maps = await db.query('projects');

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Kategorien für alle Projekte laden
    for (var project in projects) {
      project.category =
          await _categoryRepository.getCategoryById(project.categoryId);
    }

    return projects;
  }

  // Projekt nach ID abrufen
  Future<ProjectModel?> getProjectById(int id) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final project = ProjectModel.fromMap(maps.first);
      project.category =
          await _categoryRepository.getCategoryById(project.categoryId);
      return project;
    }

    return null;
  }

  // Projekte nach Kategorie filtern
  Future<List<ProjectModel>> getProjectsByCategory(int categoryId) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'projects',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Kategorien für alle Projekte laden
    for (var project in projects) {
      project.category =
          await _categoryRepository.getCategoryById(project.categoryId);
    }

    return projects;
  }

  // Projekte nach Datum filtern
  Future<List<ProjectModel>> getProjectsByDateRange(
      DateTime start, DateTime end) async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;

    final maps = await db.query(
      'projects',
      where:
          '(startDate <= ? AND endDate >= ?) OR (startDate BETWEEN ? AND ?) OR (endDate BETWEEN ? AND ?)',
      whereArgs: [
        end.toIso8601String(),
        start.toIso8601String(),
        start.toIso8601String(),
        end.toIso8601String(),
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Kategorien für alle Projekte laden
    for (var project in projects) {
      project.category =
          await _categoryRepository.getCategoryById(project.categoryId);
    }

    return projects;
  }

  // Aktive Projekte für einen bestimmten Tag abrufen
  Future<List<ProjectModel>> getProjectsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return getProjectsByDateRange(startOfDay, endOfDay);
  }

  // Statistiken: Anzahl der Projekte nach Priorität
  Future<Map<int, int>> getProjectCountByPriority() async {
    await ensureProjectTableExists();
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT priority, COUNT(*) as count
      FROM projects
      GROUP BY priority
    ''');

    final Map<int, int> counts = {};
    for (var item in result) {
      counts[item['priority'] as int] = item['count'] as int;
    }

    return counts;
  }
}
