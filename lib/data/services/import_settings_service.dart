import 'package:shared_preferences/shared_preferences.dart';

class ImportSettingsService {
  static const String _importOptionKey = 'google_calendar_import_option';

  /// Speichert die ausgewählte Import-Option
  /// 0: Standardkategorie verwenden
  /// 1: Google-Farben als Kategorien verwenden
  /// 2: Automatisches Mapping nach Kalendername (Kategorien von Google Kalender übernehmen)
  static Future<void> saveImportOption(int option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_importOptionKey, option);
  }

  /// Lädt die gespeicherte Import-Option
  /// Standardwert ist 0 (Standardkategorie verwenden)
  static Future<int> getImportOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_importOptionKey) ?? 0;
  }
}
