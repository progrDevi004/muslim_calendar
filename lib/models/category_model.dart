// lib/models/category_model.dart

import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final Color color;

  CategoryModel({
    this.id,
    required this.name,
    required this.color,
  });

  // DB-Mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': color.value,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      color: Color(map['colorValue'] ?? 0xFF000000),
    );
  }
}
