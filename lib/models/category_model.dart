// lib/models/category_model.dart

import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
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
      // ignore: deprecated_member_use
      'color': color.value,
      'isDefault': isDefault ? 1 : 0,
    };

    // Füge ID nur hinzu, wenn nicht 0 (für neue Einträge)
    if (id != null && id != 0) {
      map['id'] = id;
    }

    return map;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    // Stelle sicher, dass wir einen gültigen Farbwert haben
    int colorValue = 0xFF2196F3; // Standardfarbe (blau)

    if (map['color'] != null) {
      try {
        // Für den Fall, dass der Wert als String gespeichert ist
        if (map['color'] is String) {
          colorValue = int.parse(map['color']);
        } else {
          colorValue = map['color'] as int;
        }

        // Stelle sicher, dass der Alpha-Kanal gesetzt ist
        if ((colorValue & 0xFF000000) == 0) {
          colorValue |= 0xFF000000;
        }
      } catch (e) {
        // Spezifische Standardfarben je nach Kategoriename
        if (map['name'] == 'Privat') {
          colorValue = Colors.blue.value;
        } else if (map['name'] == 'Islam') {
          colorValue = Colors.red.value;
        } else if (map['name'] == 'Geschäftlich') {
          colorValue = Colors.green.value;
        }
      }
    } else {
      // Spezifische Standardfarben je nach Kategoriename wenn keine Farbe gesetzt ist
      if (map['name'] == 'Privat') {
        colorValue = Colors.blue.value;
      } else if (map['name'] == 'Islam') {
        colorValue = Colors.red.value;
      } else if (map['name'] == 'Geschäftlich') {
        colorValue = Colors.green.value;
      }
    }

    return CategoryModel(
      id: map['id'],
      name: map['name'] ?? 'Unbenannt',
      color: Color(colorValue),
      isDefault: map['isDefault'] == 1,
    );
  }

  @override
  String toString() {
    // ignore: deprecated_member_use
    return 'CategoryModel(id: $id, name: $name, color: ${color.value.toRadixString(16)}, isDefault: $isDefault)';
  }
}
