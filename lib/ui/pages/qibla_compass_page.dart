// lib/ui/pages/qibla_compass_page.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Für Ladeanimation
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  /// Prüft und fordert die Location-Berechtigung an.
  Future<void> _checkAndRequestPermission() async {
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
    _deviceSupportFuture = FlutterQiblah.androidDeviceSensorSupport()
        .then((value) => value ?? false);

    _qiblahStream = FlutterQiblah.qiblahStream;

    setState(() {});
  }

  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context);

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
            color: Colors.blue,
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
                color: Colors.blue,
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
                    color: Colors.blue,
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
              final double qiblahDegrees = qiblahDirection.qiblah ?? 0;
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
                border: Border.all(color: Colors.blueAccent, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Statische Himmelsrichtungen
            const Positioned(
              top: 10,
              child: Text(
                "N",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const Positioned(
              bottom: 10,
              child: Text(
                "S",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const Positioned(
              left: 10,
              child: Text(
                "W",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const Positioned(
              right: 10,
              child: Text(
                "E",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            // Drehender Kompasspfeil, der die Qibla-Richtung anzeigt.
            Transform.rotate(
              angle: angle,
              child: const Icon(
                Icons.navigation,
                size: 80,
                color: Colors.redAccent,
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
                    color: Colors.green,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.qiblaLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
