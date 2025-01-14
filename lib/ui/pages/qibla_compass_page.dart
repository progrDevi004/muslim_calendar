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
  /// Hier speichern wir später das Ergebnis, ob das Gerät einen Kompass-Sensor unterstützt.
  /// Wir nutzen `Future<bool>?`, weil wir es erst nach der Berechtigungsabfrage initialisieren.
  Future<bool>? _deviceSupportFuture;

  /// Qiblah-Stream, wird erst initialisiert, nachdem Permission gewährt und DeviceSupport geprüft ist.
  Stream<QiblahDirection>? _qiblahStream;

  /// Beim Start prüfen wir zunächst die Berechtigung; wenn vorhanden oder erteilt, initialisieren wir den Qiblah-Support.
  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  /// Fragt die Standort-Berechtigung an, wenn sie noch nicht existiert.
  /// Erst danach initialisieren wir die Qiblah-Infos.
  Future<void> _checkAndRequestPermission() async {
    var status = await Permission.location.status;

    // Wenn die Berechtigung noch nicht erteilt wurde => anfragen
    if (!status.isGranted) {
      final result = await Permission.location.request();
      // Falls danach nicht gewährt => wir brechen ab
      if (!result.isGranted) {
        setState(() {}); // build() wird aufgerufen und kann Error anzeigen
        return;
      }
    }

    // Hier haben wir also sicher eine gültige Standort-Berechtigung
    _deviceSupportFuture = FlutterQiblah.androidDeviceSensorSupport()
        .then((value) => value ?? false);

    // Den Qiblah-Stream direkt initialisieren
    _qiblahStream = FlutterQiblah.qiblahStream;

    // Damit das FutureBuilder und StreamBuilder neu aufgebaut werden
    setState(() {});
  }

  /// Sorgt dafür, dass alle Streams ordentlich beendet werden
  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wenn _deviceSupportFuture noch null ist, haben wir entweder:
    // 1) Keine Berechtigung oder 2) Sind noch im Abfrage-Prozess
    // => Zeige Spinner oder entsprechende Fehlermeldung
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

    // Wenn wir hier sind, gibt es bereits ein Future, das wir im FutureBuilder anzeigen
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Kompass'),
      ),
      body: FutureBuilder<bool>(
        future: _deviceSupportFuture,
        builder: (context, snapshot) {
          // Zeige solange einen Ladeindikator, bis wir wissen, ob das Gerät unterstützt wird
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            );
          }

          // Falls ein Fehler aufgetreten ist oder snapshot keine Daten enthält
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Fehler beim Abrufen der Qibla-Richtung',
                textAlign: TextAlign.center,
              ),
            );
          }

          final deviceSupported = snapshot.data!;
          // Wenn das Gerät den Kompass nicht unterstützt
          if (!deviceSupported) {
            return const Center(
              child: Text(
                'Ihr Gerät unterstützt den Kompass nicht.',
                style: TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Ab hier haben wir sowohl Permission als auch deviceSupport == true
          return StreamBuilder<QiblahDirection>(
            stream: _qiblahStream,
            builder: (context, qiblahSnapshot) {
              // Während die Qiblah-Daten noch geholt werden
              if (qiblahSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blue,
                    size: 50.0,
                  ),
                );
              }

              // Falls hier ein Fehler oder keine Daten
              if (qiblahSnapshot.hasError || !qiblahSnapshot.hasData) {
                return const Center(
                  child: Text('Fehler beim Abrufen der Qibla-Richtung'),
                );
              }

              final qiblahDirection = qiblahSnapshot.data!;
              // WICHTIG: qiblahDirection.qiblah = Abweichung von Norden
              // => Wir drehen das Icon entsprechend
              final angleInRadians =
                  (qiblahDirection.qiblah ?? 0) * (math.pi / 180);

              // Compass-UI: z. B. ein Icon, das passend rotiert wird
              return Center(
                child: Transform.rotate(
                  angle: angleInRadians,
                  child: const Icon(
                    Icons.navigation,
                    size: 200,
                    color: Colors.blue,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
