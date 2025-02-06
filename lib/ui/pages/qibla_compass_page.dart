// lib/ui/pages/qibla_compass_page.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Für Ladeanimation
import 'dart:math' as math;

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
    // Wenn die Berechtigung abgelehnt wurde, zeige eine Fehlermeldung.
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Qibla Kompass'),
        ),
        body: const Center(
          child: Text(
            'Die Standortberechtigung wurde verweigert.\nBitte erteile die Berechtigung, um den Kompass nutzen zu können.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    // Falls _deviceSupportFuture noch null ist, zeigen wir einen Ladeindikator.
    if (_deviceSupportFuture == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Qibla Kompass'),
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
        title: const Text('Qibla Kompass'),
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
            return const Center(
              child: Text(
                'Fehler beim Abrufen der Qibla-Richtung',
                textAlign: TextAlign.center,
              ),
            );
          }
          final deviceSupported = snapshot.data!;
          if (!deviceSupported) {
            return const Center(
              child: Text(
                'Ihr Gerät unterstützt den Kompass nicht.',
                style: TextStyle(fontSize: 16, color: Colors.red),
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
                return const Center(
                  child: Text('Fehler beim Abrufen der Qibla-Richtung'),
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
                child: buildCompass(correctedAngle, qiblahDegrees),
              );
            },
          );
        },
      ),
    );
  }

  /// Baut eine ansprechende Kompass-UI inklusive:
  /// - drehendem Pfeil, der die Qibla-Richtung anzeigt,
  /// - einem visuellen Marker auf dem Kreis, der Qibla markiert,
  /// - und der textuellen Anzeige des Qibla-Winkels.
  Widget buildCompass(double angle, double qiblahDegrees) {
    // Berechne die Position des Qibla-Markers (auf dem Kreis)
    // Der Kreis hat eine Breite/Höhe von 300 -> Radius ca. 150.
    // Wir platzieren den Marker etwas innerhalb des Rands (z. B. 140)
    const double markerRadius = 140.0;
    final double markerX = markerRadius * math.sin(angle);
    final double markerY = -markerRadius * math.cos(angle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          height: 300,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anzeige der Himmelsrichtungen
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
              // Der drehende Kompasspfeil, der auf Qibla zeigt.
              Transform.rotate(
                angle: angle,
                child: const Icon(
                  Icons.navigation,
                  size: 80,
                  color: Colors.redAccent,
                ),
              ),
              // Der Qibla-Marker auf dem äußeren Rand des Kreises.
              Transform.translate(
                offset: Offset(markerX, markerY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.place,
                      size: 24,
                      color: Colors.green,
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Qibla",
                      style: TextStyle(
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
        ),
        const SizedBox(height: 16),
        // Anzeige der Qibla-Richtung in Grad als Text.
        Text(
          "Qibla Richtung: ${qiblahDegrees.toStringAsFixed(0)}°",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
