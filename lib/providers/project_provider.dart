import 'package:flutter/material.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/data/repositories/project_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _projectRepository = ProjectRepository();
  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  bool _isLoading = false;
  String? _error;

  // Getter
  List<ProjectModel> get projects => _projects;
  ProjectModel? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Konstruktor mit automatischem Laden
  ProjectProvider() {
    loadProjects();
  }

  // Alle Projekte laden
  Future<void> loadProjects() async {
    _setLoading(true);

    try {
      _projects = await _projectRepository.getAllProjects();
      _error = null;
    } catch (e) {
      _error = "Fehler beim Laden der Projekte: $e";
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Projekt nach ID laden und als ausgewähltes Projekt festlegen
  Future<void> selectProjectById(int id) async {
    _setLoading(true);

    try {
      final project = await _projectRepository.getProjectById(id);
      _selectedProject = project;
      _error = null;
    } catch (e) {
      _error = "Fehler beim Laden des Projekts: $e";
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Neues Projekt hinzufügen
  Future<bool> addProject(ProjectModel project) async {
    _setLoading(true);

    try {
      final id = await _projectRepository.insertProject(project);
      if (id > 0) {
        await loadProjects(); // Liste neu laden
        _error = null;
        return true;
      } else {
        _error = "Fehler beim Speichern des Projekts";
        return false;
      }
    } catch (e) {
      _error = "Fehler beim Hinzufügen des Projekts: $e";
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Projekt aktualisieren
  Future<bool> updateProject(ProjectModel project) async {
    _setLoading(true);

    try {
      final rowsAffected = await _projectRepository.updateProject(project);
      if (rowsAffected > 0) {
        await loadProjects(); // Liste neu laden

        // Falls das aktualisierte Projekt das ausgewählte Projekt ist, aktualisieren
        if (_selectedProject != null && _selectedProject!.id == project.id) {
          _selectedProject = project;
        }

        _error = null;
        return true;
      } else {
        _error = "Fehler beim Aktualisieren des Projekts";
        return false;
      }
    } catch (e) {
      _error = "Fehler beim Aktualisieren des Projekts: $e";
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Projekt löschen
  Future<bool> deleteProject(int id) async {
    _setLoading(true);

    try {
      final rowsAffected = await _projectRepository.deleteProject(id);
      if (rowsAffected > 0) {
        // Wenn das gelöschte Projekt das ausgewählte Projekt ist, zurücksetzen
        if (_selectedProject != null && _selectedProject!.id == id) {
          _selectedProject = null;
        }

        // Projekt aus der Liste entfernen
        _projects.removeWhere((project) => project.id == id);
        notifyListeners();

        _error = null;
        return true;
      } else {
        _error = "Projekt konnte nicht gelöscht werden";
        return false;
      }
    } catch (e) {
      _error = "Fehler beim Löschen des Projekts: $e";
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Projekte für einen bestimmten Zeitraum laden
  Future<List<ProjectModel>> getProjectsInDateRange(
      DateTime startDate, DateTime endDate) async {
    _setLoading(true);

    try {
      final projects =
          await _projectRepository.getProjectsInDateRange(startDate, endDate);
      _error = null;
      return projects;
    } catch (e) {
      _error = "Fehler beim Laden der Projekte im Zeitraum: $e";
      debugPrint(_error);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Projekte nach Kategorie laden
  Future<List<ProjectModel>> getProjectsByCategory(int categoryId) async {
    _setLoading(true);

    try {
      final projects =
          await _projectRepository.getProjectsByCategory(categoryId);
      _error = null;
      return projects;
    } catch (e) {
      _error = "Fehler beim Laden der Projekte für Kategorie: $e";
      debugPrint(_error);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Nur aktive Projekte laden
  Future<void> loadActiveProjects() async {
    _setLoading(true);

    try {
      _projects = await _projectRepository.getActiveProjects();
      _error = null;
    } catch (e) {
      _error = "Fehler beim Laden der aktiven Projekte: $e";
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Projekt-Fortschritt aktualisieren
  Future<bool> updateProjectProgress(int id, int progress) async {
    try {
      final rowsAffected =
          await _projectRepository.updateProjectProgress(id, progress);
      if (rowsAffected > 0) {
        // Lokale Liste aktualisieren
        final index = _projects.indexWhere((project) => project.id == id);
        if (index != -1) {
          final updatedProject = _projects[index].copyWith(progress: progress);
          _projects[index] = updatedProject;

          // Falls das aktualisierte Projekt das ausgewählte Projekt ist, aktualisieren
          if (_selectedProject != null && _selectedProject!.id == id) {
            _selectedProject = updatedProject;
          }

          notifyListeners();
        }

        _error = null;
        return true;
      } else {
        _error = "Fortschritt konnte nicht aktualisiert werden";
        return false;
      }
    } catch (e) {
      _error = "Fehler beim Aktualisieren des Fortschritts: $e";
      debugPrint(_error);
      return false;
    }
  }

  // Loading-Status setzen und Listener benachrichtigen
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Fehler setzen
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
