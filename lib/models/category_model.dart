// lib/models/category_model.dart

import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final Color color;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.isDefault,
  });

  // Neuer Constructor für neue Kategorien (ohne ID)
  factory CategoryModel.newCategory({
    required String name,
    required Color color,
    bool isDefault = false,
  }) {
    return CategoryModel(
      id: 0, // Temporäre ID, wird durch AUTO_INCREMENT ersetzt
      name: name,
      color: color,
      isDefault: isDefault,
    );
  }

  // DB-Mapping
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'color': color.value,
      'isDefault': isDefault ? 1 : 0,
    };

    // Füge ID nur hinzu, wenn nicht 0 (für neue Einträge)
    if (id != 0) {
      map['id'] = id;
    }

    return map;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'Unbenannt',
      color: Color(map['color'] ?? Colors.grey.value),
      isDefault: map['isDefault'] == 1,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, color: ${color.value}, isDefault: $isDefault)';
  }
}
