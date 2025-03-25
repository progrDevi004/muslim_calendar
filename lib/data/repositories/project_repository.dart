import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

class ProjectRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final CategoryRepository categoryRepository = CategoryRepository();

  // Stellt sicher, dass die Projekt-Tabelle existiert
  Future<void> _ensureProjectTableExists(Database db) async {
    try {
      // Überprüfen, ob die Tabelle existiert
      await db.query('projects', limit: 1);
    } catch (e) {
      // Tabelle existiert nicht, erstellen wir sie
      debugPrint("Projekte-Tabelle existiert nicht. Erstelle sie neu...");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          priority INTEGER DEFAULT 2, 
          progress INTEGER DEFAULT 0,
          categoryId INTEGER NOT NULL,
          isActive INTEGER DEFAULT 1,
          FOREIGN KEY (categoryId) REFERENCES categories(id)
        )
      ''');
      debugPrint("Projekte-Tabelle wurde erstellt.");
    }
  }

  // Alle Projekte abrufen
  Future<List<ProjectModel>> getAllProjects() async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query('projects');
    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Für jedes Projekt die zugehörige Kategorie laden
    for (var project in projects) {
      try {
        final category =
            await categoryRepository.getCategoryById(project.categoryId);
        if (category != null) {
          project.category = category;
        }
      } catch (e) {
        debugPrint(
            "Fehler beim Laden der Kategorie für Projekt ${project.id}: $e");
      }
    }

    return projects;
  }

  // Projekt nach ID abrufen
  Future<ProjectModel?> getProjectById(int id) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final project = ProjectModel.fromMap(maps.first);

    // Kategorie laden
    try {
      final category =
          await categoryRepository.getCategoryById(project.categoryId);
      if (category != null) {
        project.category = category;
      }
    } catch (e) {
      debugPrint("Fehler beim Laden der Kategorie für Projekt $id: $e");
    }

    return project;
  }

  // Projekte nach Kategorie abrufen
  Future<List<ProjectModel>> getProjectsByCategory(int categoryId) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Für jedes Projekt die zugehörige Kategorie laden
    for (var project in projects) {
      try {
        final category =
            await categoryRepository.getCategoryById(project.categoryId);
        if (category != null) {
          project.category = category;
        }
      } catch (e) {
        debugPrint(
            "Fehler beim Laden der Kategorie für Projekt ${project.id}: $e");
      }
    }

    return projects;
  }

  // Projekte für einen bestimmten Zeitraum abrufen
  Future<List<ProjectModel>> getProjectsInDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    // Projekte abrufen, die im angegebenen Zeitraum liegen oder diesen überschneiden
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM projects 
      WHERE 
        (startDate <= ? AND endDate >= ?) OR
        (startDate <= ? AND endDate >= ?) OR
        (startDate >= ? AND endDate <= ?)
    ''', [
      endDate.toIso8601String(),
      startDate.toIso8601String(),
      startDate.toIso8601String(),
      startDate.toIso8601String(),
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Für jedes Projekt die zugehörige Kategorie laden
    for (var project in projects) {
      try {
        final category =
            await categoryRepository.getCategoryById(project.categoryId);
        if (category != null) {
          project.category = category;
        }
      } catch (e) {
        debugPrint(
            "Fehler beim Laden der Kategorie für Projekt ${project.id}: $e");
      }
    }

    return projects;
  }

  // Neues Projekt hinzufügen
  Future<int> insertProject(ProjectModel project) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    debugPrint("Speichere Projekt: ${project.toString()}");
    return await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Projekt aktualisieren
  Future<int> updateProject(ProjectModel project) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    if (project.id == null) {
      throw ArgumentError('Project ID cannot be null');
    }

    debugPrint("Aktualisiere Projekt: ${project.toString()}");
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  // Projekt löschen
  Future<int> deleteProject(int id) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    debugPrint("Lösche Projekt mit ID: $id");
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Projekt-Fortschritt aktualisieren
  Future<int> updateProjectProgress(int id, int progress) async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    debugPrint("Aktualisiere Fortschritt für Projekt $id auf $progress%");
    return await db.update(
      'projects',
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Alle aktiven Projekte abrufen
  Future<List<ProjectModel>> getActiveProjects() async {
    final db = await dbHelper.database;
    await _ensureProjectTableExists(db);

    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    final projects = List.generate(maps.length, (i) {
      return ProjectModel.fromMap(maps[i]);
    });

    // Für jedes Projekt die zugehörige Kategorie laden
    for (var project in projects) {
      try {
        final category =
            await categoryRepository.getCategoryById(project.categoryId);
        if (category != null) {
          project.category = category;
        }
      } catch (e) {
        debugPrint(
            "Fehler beim Laden der Kategorie für Projekt ${project.id}: $e");
      }
    }

    return projects;
  }
}
