// lib/data/repositories/google_event_mapping_repository.dart

import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:flutter/foundation.dart';

class GoogleEventMapping {
  final int? id;
  final int localAppointmentId;
  final String originalDate; // ISO String Format
  final String googleEventId;
  final DateTime lastSyncedAt;

  // Hilfseigenschaft für die addMapping-Methode
  String get externalId => googleEventId;

  GoogleEventMapping({
    this.id,
    required this.localAppointmentId,
    required this.originalDate,
    required this.googleEventId,
    required this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local_appointment_id': localAppointmentId,
      'original_date': originalDate,
      'google_event_id': googleEventId,
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  factory GoogleEventMapping.fromMap(Map<String, dynamic> map) {
    return GoogleEventMapping(
      id: map['id'],
      localAppointmentId: map['local_appointment_id'],
      originalDate: map['original_date'],
      googleEventId: map['google_event_id'],
      lastSyncedAt: DateTime.parse(map['last_synced_at']),
    );
  }
}

class GoogleEventMappingRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Speichert ein neues Mapping oder aktualisiert ein bestehendes
  Future<int> saveMapping(GoogleEventMapping mapping) async {
    final db = await dbHelper.database;
    return await db.insert(
      'google_event_mappings',
      mapping.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Löscht Mappings für einen lokalen Termin
  Future<int> deleteMappingsForAppointment(int localAppointmentId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'google_event_mappings',
      where: 'local_appointment_id = ?',
      whereArgs: [localAppointmentId],
    );
  }

  // Löscht ein einzelnes Mapping
  Future<int> deleteMapping(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'google_event_mappings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Findet alle Mappings für einen lokalen Termin
  Future<List<GoogleEventMapping>> getMappingsForAppointment(
      int localAppointmentId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'google_event_mappings',
      where: 'local_appointment_id = ?',
      whereArgs: [localAppointmentId],
    );
    return maps.map((map) => GoogleEventMapping.fromMap(map)).toList();
  }

  // Findet ein Mapping für einen lokalen Termin und ein bestimmtes Datum
  Future<GoogleEventMapping?> getMappingForDate(
      int localAppointmentId, DateTime originalDate) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'google_event_mappings',
      where: 'local_appointment_id = ? AND original_date = ?',
      whereArgs: [
        localAppointmentId,
        originalDate.toIso8601String().split('T')[0]
      ],
    );
    if (maps.isEmpty) return null;
    return GoogleEventMapping.fromMap(maps.first);
  }

  // Findet ein Mapping anhand der Google Event ID
  Future<GoogleEventMapping?> getMappingByGoogleEventId(
      String googleEventId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'google_event_mappings',
      where: 'google_event_id = ?',
      whereArgs: [googleEventId],
    );
    if (maps.isEmpty) return null;
    return GoogleEventMapping.fromMap(maps.first);
  }

  // Löscht alte Mappings, die älter als ein bestimmtes Datum sind
  Future<int> cleanupOldMappings(DateTime cutoffDate) async {
    final db = await dbHelper.database;
    final dateStr = cutoffDate.toIso8601String().split('T')[0];
    return await db.delete(
      'google_event_mappings',
      where: 'original_date < ?',
      whereArgs: [dateStr],
    );
  }

  // Findet ein Mapping für einen lokalen Termin und eine Quelle (z.B. 'google')
  Future<GoogleEventMapping?> getMappingForLocalAppointment(
      int localAppointmentId, String source) async {
    final mappings = await getMappingsForAppointment(localAppointmentId);
    if (mappings.isEmpty) return null;

    // Da wir nur Google-Mappings haben, ignorieren wir den source-Parameter
    // und geben das erste Mapping zurück
    return mappings.first;
  }

  // Hilfsmethode zum Hinzufügen eines neuen Mappings
  Future<int> addMapping({
    required int localId,
    required String externalId,
    required String source,
    required String sourceCalendarId,
  }) async {
    final today = DateTime.now();
    final mapping = GoogleEventMapping(
      localAppointmentId: localId,
      originalDate: today.toIso8601String().split('T')[0],
      googleEventId: externalId,
      lastSyncedAt: today,
    );
    return await saveMapping(mapping);
  }

  // Findet ein Mapping anhand der Google Event ID
  Future<GoogleEventMapping?> getMappingByGoogleId(String googleEventId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'google_event_mappings',
      where: 'google_event_id = ?',
      whereArgs: [googleEventId],
    );
    if (maps.isEmpty) return null;
    return GoogleEventMapping.fromMap(maps.first);
  }

  // Neue Methode: Suche und bereinige doppelte Mappings
  Future<int> cleanupDuplicateMappings() async {
    final db = await dbHelper.database;
    
    // Hole alle GoogleEventIDs, die mehr als einmal vorkommen
    final duplicateQuery = '''
      SELECT google_event_id, COUNT(*) as count 
      FROM google_event_mappings 
      GROUP BY google_event_id 
      HAVING count > 1
    ''';
    
    final duplicates = await db.rawQuery(duplicateQuery);
    int cleanedCount = 0;
    
    // Für jede doppelte ID
    for (final dupMap in duplicates) {
      final googleEventId = dupMap['google_event_id'] as String;
      debugPrint("🧹 Bereinige doppelte Mappings für Google-Event-ID: $googleEventId");
      
      // Hole alle Mappings für diese ID
      final mappings = await db.query(
        'google_event_mappings',
        where: 'google_event_id = ?',
        whereArgs: [googleEventId],
        orderBy: 'last_synced_at DESC', // Neueste zuerst
      );
      
      // Behalte nur das neueste Mapping
      if (mappings.length > 1) {
        final newestMapping = mappings.first;
        final newestId = newestMapping['id'] as int;
        
        // Lösche alle anderen Mappings für diese Google-ID
        final deleteCount = await db.delete(
          'google_event_mappings',
          where: 'google_event_id = ? AND id != ?',
          whereArgs: [googleEventId, newestId],
        );
        
        debugPrint("✅ $deleteCount doppelte Mappings für Google-ID $googleEventId entfernt");
        cleanedCount += deleteCount;
      }
    }
    
    return cleanedCount;
  }
}
