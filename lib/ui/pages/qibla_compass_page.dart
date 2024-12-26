// lib/ui/pages/qibla_compass_page.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Für Ladeanimation

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({Key? key}) : super(key: key);

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  final Future<bool> _deviceSupportFuture =
      FlutterQiblah.androidDeviceSensorSupport()
          .then((value) => value ?? false);
  final _qiblahStream = FlutterQiblah.qiblahStream;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!) {
            return const Center(
              child: Text(
                'Ihr Gerät unterstützt den Kompass nicht.',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return StreamBuilder<QiblahDirection>(
              stream: _qiblahStream,
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
                    child: Text('Fehler beim Abrufen der Qibla-Richtung'),
                  );
                }

                final qiblahDirection = snapshot.data!;
                return Center(
                  child: Transform.rotate(
                    angle: (qiblahDirection.direction ?? 0) * (3.14159 / 180),
                    child: const Icon(
                      Icons.navigation,
                      size: 200,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
