// lib/ui/pages/qibla_compass_page.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoIcons und CupertinoButton importieren
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
      debugPrint('QiblaCompass: Überprüfe Standort-Berechtigung...');

      // Auf iOS verwenden wir "locationWhenInUse", auf Android "location".
      if (Platform.isIOS) {
        debugPrint('QiblaCompass: iOS-Plattform erkannt');

        // Überprüfen des Standortstatus
        var status = await Permission.locationWhenInUse.status;
        debugPrint('QiblaCompass: iOS Standortstatus ist: $status');

        if (!status.isGranted) {
          debugPrint('QiblaCompass: iOS Standortberechtigung anfordern...');
          final result = await Permission.locationWhenInUse.request();
          debugPrint('QiblaCompass: iOS Standortanfrage Ergebnis: $result');

          if (!result.isGranted) {
            debugPrint('QiblaCompass: iOS Standortberechtigung abgelehnt');
            setState(() {
              _permissionDenied = true;
            });
            return;
          }
        }

        // Auf iOS brauchen wir für den Kompass auch Bewegungssensoren
        // Auf neueren iOS-Versionen ist möglicherweise eine Sensorerberechtigung nötig
        debugPrint(
            'QiblaCompass: Prüfe auf weitere benötigte Berechtigungen für iOS');

        try {
          // Einige iOS-Versionen benötigen zusätzliche Berechtigungsabfragen
          if (await Permission.sensors.isDenied) {
            debugPrint('QiblaCompass: iOS Sensorberechtigung anfordern...');
            await Permission.sensors.request();
          }
        } catch (e) {
          // Wir fangen den Fehler ab und setzen fort - nicht alle iOS-Versionen unterstützen diese Berechtigung
          debugPrint(
              'QiblaCompass: Fehler bei Sensorberechtigung - ignorieren: $e');
        }
      } else {
        debugPrint('QiblaCompass: Android-Plattform erkannt');
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
      debugPrint(
          'QiblaCompass: Berechtigung erteilt, initialisiere Sensoren...');

      // Für iOS überspringen wir die androidDeviceSensorSupport-Prüfung, da diese nur für Android relevant ist
      if (Platform.isIOS) {
        debugPrint('QiblaCompass: iOS - setze deviceSupport auf true');
        _deviceSupportFuture = Future.value(
            true); // Wir gehen davon aus, dass iOS-Geräte Kompass unterstützen
      } else {
        debugPrint('QiblaCompass: Android - prüfe Sensorunterstützung');
        _deviceSupportFuture =
            FlutterQiblah.androidDeviceSensorSupport().then((value) {
          debugPrint('QiblaCompass: Android Sensorunterstützung: $value');
          return value ?? false;
        });
      }

      // Wir stellen sicher, dass der Qiblah-Stream erst initialisiert wird, nachdem alles bereit ist
      debugPrint('QiblaCompass: Warte kurz vor Stream-Initialisierung...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Explizit FlutterQiblah initialisieren (wichtig für iOS)
      if (!mounted) return;
      try {
        debugPrint('QiblaCompass: Initialisiere Qiblah-Stream...');

        // Auf iOS besonders vorsichtig sein - wir versuchen die Initialisierung mehrfach
        if (Platform.isIOS) {
          // Kompassdaten werden auf iOS manchmal verzögert geliefert
          _qiblahStream = FlutterQiblah.qiblahStream;

          // Zusätzlich eine minimale Verzögerung hinzufügen, um iOS Zeit zu geben
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          _qiblahStream = FlutterQiblah.qiblahStream;
        }

        debugPrint('QiblaCompass: Qiblah-Stream erfolgreich initialisiert');
        setState(() {});
      } catch (e) {
        debugPrint(
            'QiblaCompass: Fehler bei der Initialisierung des QiblahStream: $e');
        // Wir versuchen einen weiteren Anlauf nach kurzem Warten
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        debugPrint(
            'QiblaCompass: Zweiter Versuch zur Initialisierung des Qiblah-Streams...');
        try {
          _qiblahStream = FlutterQiblah.qiblahStream;
          debugPrint('QiblaCompass: Zweiter Versuch erfolgreich');
          setState(() {});
        } catch (e2) {
          debugPrint('QiblaCompass: Auch zweiter Versuch fehlgeschlagen: $e2');
          // Fallback für iOS: Wir erstellen einen vereinfachten/simulierten Stream
          if (Platform.isIOS) {
            debugPrint('QiblaCompass: Verwende iOS Fallback-Lösung');
            // Da wir den Konstruktor nicht direkt aufrufen können, verwenden wir
            // eine andere Strategie - wir lassen den Stream leer und
            // zeigen stattdessen einen statischen Wert in der UI an
            _qiblahStream = Stream.empty();

            // In diesem Fall setzen wir _deviceSupportFuture auf false
            // damit wir eine Fehlermeldung anzeigen können, die den Benutzer auffordert,
            // die Berechtigung in den Einstellungen zu überprüfen
            _deviceSupportFuture = Future.value(false);

            debugPrint(
                'QiblaCompass: Fallback-Stream eingerichtet - zeige Hilfenachricht an');
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint(
          'QiblaCompass: Allgemeiner Fehler bei Berechtigung oder Initialisierung: $e');
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

    // Plattform bestimmen
    final bool isIOS = Platform.isIOS;

    // Sichere Navigation zurück zum Dashboard
    void navigateBack() {
      // debugPrint('QiblaCompassPage: Navigation zurück zum Dashboard...');
      try {
        // Wir verwenden routes statt pop(), um direkt zur HomePage zu navigieren
        // Das verhindert den schwarzen Bildschirm
        Navigator.of(context).pushReplacementNamed('/');
        // debugPrint('QiblaCompassPage: Navigation erfolgreich durchgeführt');
      } catch (e) {
        debugPrint('QiblaCompassPage: Fehler bei der Navigation: $e');
        // Fallback: Versuche normal zu schließen, falls pushReplacementNamed fehlschlägt
        Navigator.of(context).pop();
      }
    }

    // Wir umgeben unsere UI mit WillPopScope, um das Zurück-Verhalten zu überschreiben
    Widget buildScaffold(Widget body) {
      return WillPopScope(
        onWillPop: () async {
          navigateBack();
          return false; // Verhindert das normale Pop-Verhalten
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(localizations.qiblaCompass),
            // Zurück-Button mit sicherer Navigation
            leading: isIOS
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.back),
                    onPressed: navigateBack,
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: navigateBack,
                  ),
          ),
          body: body,
        ),
      );
    }

    // Wenn die Berechtigung abgelehnt wurde, zeige eine Fehlermeldung.
    if (_permissionDenied) {
      return buildScaffold(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.location_slash
                    : Icons.location_off,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.locationPermissionDeniedMessage,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  Platform.isIOS
                      ? 'Bitte aktivieren Sie den Standortzugriff in den Einstellungen, um den Qibla-Kompass zu nutzen. '
                          'Gehen Sie zu Einstellungen → Datenschutz → Ortungsdienste → Taqvimi.'
                      : 'Bitte gewähren Sie der App Zugriff auf Ihren Standort, um den Qibla-Kompass zu nutzen. '
                          'Öffnen Sie die App-Einstellungen, um die Berechtigung zu erteilen.',
                  style:
                      TextStyle(fontSize: 14, color: Colors.blueGrey.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => navigateBack(),
                icon: Icon(Platform.isIOS
                    ? CupertinoIcons.arrow_left
                    : Icons.arrow_back),
                label: const Text('Zurück zur App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: logoColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Falls _deviceSupportFuture noch null ist, zeigen wir einen Ladeindikator.
    if (_deviceSupportFuture == null) {
      return buildScaffold(
        const Center(
          child: SpinKitFadingCircle(
            color: logoColor,
            size: 50.0,
          ),
        ),
      );
    }

    return buildScaffold(
      FutureBuilder<bool>(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.compass
                        : Icons.compass_calibration_outlined,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.deviceNotSupported,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (Platform.isIOS)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Für iOS-Geräte: Bitte überprüfen Sie die Standort- und Bewegungssensor-Berechtigungen in den Einstellungen. '
                        'Gehen Sie zu Einstellungen → Datenschutz → Ortungsdienste → Taqvimi und stellen Sie die Berechtigung auf "Beim Verwenden der App" ein. '
                        'Starten Sie dann die App neu.',
                        style: TextStyle(
                            fontSize: 14, color: Colors.blueGrey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (Platform.isIOS)
                    ElevatedButton.icon(
                      onPressed: () => navigateBack(),
                      icon: const Icon(CupertinoIcons.arrow_left),
                      label: const Text('Zurück zur App'),
                    ),
                ],
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
