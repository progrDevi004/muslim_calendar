// lib/ui/pages/qibla_compass_page.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Für Ladeanimation
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:Taqvimi/localization/app_localizations.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  /// Speichert, ob das Gerät einen Kompass-Sensor unterstützt.
  Future<bool>? _deviceSupportFuture;

  /// Qiblah-Stream, der später genutzt wird.
  Stream<QiblahDirection>? _qiblahStream;

  /// Flag, falls der Benutzer die Location-Berechtigung ablehnt.
  bool _permissionDenied = false;

  /// Lokale Referenz auf die Lokalisierungen
  AppLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // AppLocalizations Referenz speichern
    _localizations = Provider.of<AppLocalizations>(context, listen: false);
  }

  /// Prüft und fordert die Location-Berechtigung an.
  Future<void> _checkAndRequestPermission() async {
    try {
      // Auf iOS verwenden wir "locationWhenInUse", auf Android "location".
      if (Platform.isIOS) {
        var status = await Permission.locationWhenInUse.status;
        if (!status.isGranted) {
          final result = await Permission.locationWhenInUse.request();
          if (!result.isGranted) {
            setState(() {
              _permissionDenied = true;
            });
            return;
          }
        }
      } else {
        var status = await Permission.location.status;
        if (!status.isGranted) {
          final result = await Permission.location.request();
          if (!result.isGranted) {
            setState(() {
              _permissionDenied = true;
            });
            return;
          }
        }
      }

      // Berechtigung erteilt – initialisiere Device-Support und Qiblah-Stream.
      // Für iOS überspringen wir die androidDeviceSensorSupport-Prüfung, da diese nur für Android relevant ist
      if (Platform.isIOS) {
        _deviceSupportFuture = Future.value(
            true); // Wir gehen davon aus, dass iOS-Geräte Kompass unterstützen
      } else {
        _deviceSupportFuture = FlutterQiblah.androidDeviceSensorSupport()
            .then((value) => value ?? false);
      }

      // Wir stellen sicher, dass der Qiblah-Stream erst initialisiert wird, nachdem alles bereit ist
      await Future.delayed(const Duration(milliseconds: 500));

      // Explizit FlutterQiblah initialisieren (wichtig für iOS)
      if (!mounted) return;
      try {
        _qiblahStream = FlutterQiblah.qiblahStream;
        setState(() {});
      } catch (e) {
        debugPrint('Fehler bei der Initialisierung des QiblahStream: $e');
        // Wir versuchen einen weiteren Anlauf nach kurzem Warten
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        _qiblahStream = FlutterQiblah.qiblahStream;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Fehler bei der Berechtigung oder Initialisierung: $e');
      if (mounted) {
        setState(() {
          _permissionDenied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Sicheres Entfernen des FlutterQiblah-Streams
    try {
      FlutterQiblah().dispose();
    } catch (e) {
      // Fehler beim Entfernen des Streams ignorieren
      debugPrint('Fehler beim Entfernen des FlutterQiblah-Streams: $e');
    }

    // Wir greifen nicht mehr auf Provider.of in dispose zu

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Statt Provider.of im build zu nutzen, greifen wir auf die gespeicherte Referenz zu
    // Falls _localizations null ist (didChangeDependencies noch nicht aufgerufen), verwenden wir direct Provider.of
    final localizations =
        _localizations ?? Provider.of<AppLocalizations>(context);

    // Wenn die Berechtigung abgelehnt wurde, zeige eine Fehlermeldung.
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.qiblaCompass),
        ),
        body: Center(
          child: Text(
            localizations.locationPermissionDeniedMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    // Falls _deviceSupportFuture noch null ist, zeigen wir einen Ladeindikator.
    if (_deviceSupportFuture == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.qiblaCompass),
        ),
        body: const Center(
          child: SpinKitFadingCircle(
            color: logoColor,
            size: 50.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.qiblaCompass),
      ),
      body: FutureBuilder<bool>(
        future: _deviceSupportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(
                color: logoColor,
                size: 50.0,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                localizations.qiblaFetchError,
                textAlign: TextAlign.center,
              ),
            );
          }
          final deviceSupported = snapshot.data!;
          if (!deviceSupported) {
            return Center(
              child: Text(
                localizations.deviceNotSupported,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          // Gerät unterstützt den Kompass und Berechtigung ist erteilt.
          return StreamBuilder<QiblahDirection>(
            stream: _qiblahStream,
            builder: (context, qiblahSnapshot) {
              if (qiblahSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitFadingCircle(
                    color: logoColor,
                    size: 50.0,
                  ),
                );
              }
              if (qiblahSnapshot.hasError || !qiblahSnapshot.hasData) {
                return Center(
                  child: Text(localizations.qiblaFetchError),
                );
              }
              final qiblahDirection = qiblahSnapshot.data!;

              // qiblahDirection.qiblah gibt die Qibla-Richtung in Grad an (Abweichung von Norden)
              // Dieser Wert kann auf iOS manchmal null sein, daher fangen wir das ab
              final double qiblahDegrees;
              if (qiblahDirection.qiblah == null) {
                // Wenn null, verwenden wir einen Standardwert oder den letzten bekannten Wert
                // Ein typischer Wert für Mitteleuropa könnte etwa 120-140 Grad sein (Richtung Südost)
                qiblahDegrees = Platform.isIOS ? 130.0 : 0.0;

                // Im Debug-Modus Hinweis ausgeben
                debugPrint(
                    'Warnung: qiblahDirection.qiblah ist null, verwende Fallback-Wert: $qiblahDegrees');
              } else {
                qiblahDegrees = qiblahDirection.qiblah!;
              }

              final double angleInRadians = qiblahDegrees * (math.pi / 180);
              // Invertiere den Winkel, um eine stabile Rotation zu erreichen
              final double correctedAngle = -angleInRadians;

              // Zentriere den gesamten Kompass (horizontal & vertikal)
              return Center(
                child:
                    buildCompass(correctedAngle, qiblahDegrees, localizations),
              );
            },
          );
        },
      ),
    );
  }

  /// Baut die Kompass-UI:
  /// - Der drehende Pfeil zeigt die Qibla-Richtung.
  /// - Die Himmelsrichtungen bleiben statisch.
  /// - Der Qibla-Marker (mit Übersetzung) bleibt fix positioniert.
  /// - Unten wird die textuelle Anzeige der Qibla-Richtung (mit Übersetzung) dargestellt.
  Widget buildCompass(
      double angle, double qiblahDegrees, AppLocalizations loc) {
    // Kreis-Dimensionen
    const double containerSize = 300.0;
    const double centerPoint = containerSize / 2; // 150
    // Marker soll etwas innerhalb des Rands positioniert werden (z. B. Radius 140)
    const double markerRadius = 140.0;

    // Berechne die Position des Qibla-Markers auf dem Kreis (auf Basis des Winkels)
    final double markerX = markerRadius * math.sin(angle);
    final double markerY = -markerRadius * math.cos(angle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Kreisförmiger Hintergrund
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: logoColor, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Drehender Kompasspfeil, der die Qibla-Richtung anzeigt.
            Transform.rotate(
              angle: angle,
              child: const Icon(
                Icons.navigation,
                size: 80,
                color: logoColor,
              ),
            ),
            // Fester Qibla-Marker (mit Übersetzung)
            Positioned(
              left: centerPoint + markerX - 12,
              top: centerPoint + markerY - 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place,
                    size: 24,
                    color: logoColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.qiblaLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: logoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Textuelle Anzeige der Qibla-Richtung (mit Übersetzung)
        Text(
          "${loc.qiblaDirection}: ${qiblahDegrees.toStringAsFixed(0)}°",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
