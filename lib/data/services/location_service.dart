import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service zur automatischen Standortbestimmung
class LocationService with ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _currentCity;
  String? _currentCountry;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String? get currentCity => _currentCity;
  String? get currentCountry => _currentCountry;

  /// Initialisiert den LocationService und versucht, den Standort zu ermitteln,
  /// falls automatische Standortbestimmung in den Einstellungen aktiviert ist
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final automaticLocation = prefs.getBool('automaticLocation') ?? false;

    // Stadt und Land aus den SharedPreferences laden
    _currentCity = prefs.getString('defaultCity');
    _currentCountry = prefs.getString('defaultCountry');

    if (automaticLocation) {
      await determineLocation();
    }
  }

  /// Ermittelt den aktuellen Standort und speichert ihn in SharedPreferences
  Future<bool> determineLocation() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Prüfe und fordere Berechtigungen an
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _hasError = true;
          _errorMessage = 'Standortberechtigungen wurden verweigert';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _hasError = true;
        _errorMessage = 'Standortberechtigungen wurden dauerhaft verweigert';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Position ermitteln
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Reverse Geocoding mit OpenStreetMap Nominatim
      final locationInfo =
          await _reverseGeocode(position.latitude, position.longitude);

      if (locationInfo != null) {
        _currentCity = locationInfo['city'];
        _currentCountry = locationInfo['country'];

        // 4. In SharedPreferences speichern
        final prefs = await SharedPreferences.getInstance();
        if (_currentCity != null && _currentCountry != null) {
          await prefs.setString('defaultCity', _currentCity!);
          await prefs.setString('defaultCountry', _currentCountry!);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _hasError = true;
      _errorMessage = 'Standort konnte nicht ermittelt werden';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Fehler bei der Standortbestimmung: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Führt Reverse Geocoding durch, um aus Koordinaten eine Stadt und ein Land zu ermitteln
  Future<Map<String, String>?> _reverseGeocode(
      double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=10&addressdetails=1');

      final response =
          await http.get(uri, headers: {'User-Agent': 'MuslimCalendarApp'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        String? city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['hamlet'] ??
            address['suburb'];

        String? country = address['country'];

        if (city != null && country != null) {
          return {
            'city': city,
            'country': country,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gibt den aktuellen Standort zurück, wenn vorhanden
  Future<Map<String, String?>> getCurrentLocation() async {
    if (_currentCity != null && _currentCountry != null) {
      return {
        'city': _currentCity,
        'country': _currentCountry,
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('defaultCity');
    final country = prefs.getString('defaultCountry');

    return {
      'city': city,
      'country': country,
    };
  }
}
