# Anleitung zur Integration der Google Calendar-Synchronisierung

## 1. Integration in die Termin-Bearbeitungsseite

In der `appointment_creation_page.dart` Datei füge folgenden Import hinzu:

```dart
import 'package:taqvimi/ui/widgets/google_calendar_sync_widget.dart';
```

Dann füge das Widget an der passenden Stelle im Formular hinzu, zum Beispiel nach den Erinnerungseinstellungen:

```dart
// Nach den Erinnerungseinstellungen
const Divider(),
// Google Calendar Sync Widget
GoogleCalendarSyncWidget(
  appointment: widget.editingAppointment,
  isSettingsScreen: false,
),
```

## 2. Integration in die Einstellungsseite

In der `settings_page.dart` Datei füge folgenden Import hinzu:

```dart
import 'package:taqvimi/ui/widgets/google_calendar_sync_widget.dart';
```

Dann füge das Widget in der Einstellungsliste hinzu, zum Beispiel nach den Theme-Einstellungen:

```dart
// Neue Kategorie für externe Integrationen
ListTile(
  title: Text('Integration mit externen Diensten',
    style: Theme.of(context).textTheme.titleLarge,
  ),
),
// Google Calendar Sync Widget
const GoogleCalendarSyncWidget(
  isSettingsScreen: true,
),
```

## 3. Setup der Entwicklerplattform

Um die Google Calendar-Integration zu aktivieren, musst du folgende Schritte durchführen:

1. Gehe zur [Google Cloud Console](https://console.cloud.google.com/).
2. Erstelle ein neues Projekt.
3. Aktiviere die Calendar API für dieses Projekt.
4. Erstelle OAuth 2.0-Anmeldedaten (Client-ID).
5. Füge die SHA-1-Signatur deiner App hinzu.
6. Konfiguriere die OAuth-Einwilligungsbildschirm.

## 4. Android-Integration

In der `android/app/build.gradle` Datei muss die SHA-1-Signatur deiner App angegeben werden:

```gradle
signingConfigs {
    debug {
        keyAlias 'androiddebugkey'
        keyPassword 'android'
        storeFile file('debug.keystore')
        storePassword 'android'
    }
    // Release-Konfiguration...
}
```

Füge in der `android/app/src/main/AndroidManifest.xml` Datei folgende Berechtigungen hinzu:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.GET_ACCOUNTS"/>
```

## 5. iOS-Integration

In der `ios/Runner/Info.plist` Datei füge Folgendes hinzu:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

Ersetze "YOUR-CLIENT-ID" mit deiner Google OAuth Client ID.

## 6. Tipps für Tests

- Synchronisierung funktioniert nur mit echten Google-Konten.
- Bei Debugging kann es hilfreich sein, die Protokolle zu überprüfen.
- Überprüfe, ob die Google Calendar API-Limits eingehalten werden.
- Teste sowohl normale als auch gebetszeitabhängige Termine.
