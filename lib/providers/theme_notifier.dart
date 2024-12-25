// lib/providers/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = false;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  /// Ermittelt den aktuell anzuwendenden ThemeMode
  ThemeMode get currentThemeMode {
    if (_useSystemTheme) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Manuelles Umschalten zwischen Hell/Dunkel
  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    // Wenn man manuell schaltet, deaktivieren wir "System-Theme"
    _useSystemTheme = false;
    _saveToPrefs();
    notifyListeners();
  }

  /// Aktiviert/Deaktiviert das Übernehmen des System-Themes
  void toggleSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    if (useSystem) {
      // Dark Mode wird ignoriert, wir folgen dem System
      _isDarkMode = false;
    }
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkModeEnabled') ?? false;
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkModeEnabled', _isDarkMode);
    prefs.setBool('useSystemTheme', _useSystemTheme);
  }
}
