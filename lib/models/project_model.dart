import 'package:Taqvimi/models/category_model.dart';

class ProjectModel {
  final int? id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int priority; // 1-3: Niedrig, Mittel, Hoch
  final int progress; // 0-100%
  final int categoryId;
  CategoryModel? category; // Optional: Für Verbindung mit Kategorie
  final bool isActive;

  ProjectModel({
    this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.progress,
    required this.categoryId,
    this.category,
    this.isActive = true,
  });

  // Neuer Constructor für neue Projekte (ohne ID)
  factory ProjectModel.newProject({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    int priority = 2,
    int progress = 0,
    required int categoryId,
    CategoryModel? category,
    bool isActive = true,
  }) {
    return ProjectModel(
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      priority: priority,
      progress: progress,
      categoryId: categoryId,
      category: category,
      isActive: isActive,
    );
  }

  // DB-Mapping
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'priority': priority,
      'progress': progress,
      'categoryId': categoryId,
      'isActive': isActive ? 1 : 0,
    };

    // Füge ID nur hinzu, wenn nicht null (für neue Einträge)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'] ?? 'Unbenanntes Projekt',
      description: map['description'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      priority: map['priority'] ?? 2,
      progress: map['progress'] ?? 0,
      categoryId: map['categoryId'],
      isActive: map['isActive'] == 1,
    );
  }

  // Kopie mit geänderten Werten
  ProjectModel copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    int? progress,
    int? categoryId,
    CategoryModel? category,
    bool? isActive,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, startDate: $startDate, endDate: $endDate, categoryId: $categoryId, progress: $progress%)';
  }
}

// Enum für die Priorität der Projekte
enum ProjectPriority {
  low,
  medium,
  high,
}

// Hilfsfunktion um von int auf Enum zu konvertieren
ProjectPriority intToPriority(int value) {
  switch (value) {
    case 1:
      return ProjectPriority.low;
    case 3:
      return ProjectPriority.high;
    case 2:
    default:
      return ProjectPriority.medium;
  }
}

// Hilfsfunktion um von Enum auf int zu konvertieren
int priorityToInt(ProjectPriority priority) {
  switch (priority) {
    case ProjectPriority.low:
      return 1;
    case ProjectPriority.high:
      return 3;
    case ProjectPriority.medium:
    default:
      return 2;
  }
}
