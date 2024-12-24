//lib/providers/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    _saveToPrefs(isOn);
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkModeEnabled') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkModeEnabled', isOn);
  }
}
