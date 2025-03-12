import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:muslim_calendar/data/services/google_calendar_sync_service.dart';
import 'package:muslim_calendar/data/repositories/appointment_repository.dart';
import 'package:muslim_calendar/models/appointment_model.dart';

class GoogleCalendarSyncWidget extends StatefulWidget {
  final AppointmentModel? appointment;
  final bool isSettingsScreen;

  const GoogleCalendarSyncWidget({
    Key? key,
    this.appointment,
    this.isSettingsScreen = false,
  }) : super(key: key);

  @override
  State<GoogleCalendarSyncWidget> createState() =>
      _GoogleCalendarSyncWidgetState();
}

class _GoogleCalendarSyncWidgetState extends State<GoogleCalendarSyncWidget> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userName;
  late bool _syncEnabled;
  DateTime? _lastTokenRefresh;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  @override
  void initState() {
    super.initState();
    _syncEnabled = widget.appointment?.syncWithGoogleCalendar ?? false;
    _checkGoogleAuthStatus();
  }

  Future<void> _checkGoogleAuthStatus() async {
    setState(() => _isLoading = true);

    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          setState(() {
            _isAuthenticated = true;
            _userName = account.displayName;
            _lastTokenRefresh = DateTime.now();
          });

          // Initialisiere den Google Calendar Sync Service
          if (!_isInitialized) {
            await _initializeGoogleCalendarSync(account);
          }
        } else {
          // Konto existiert, aber stilles Anmelden fehlgeschlagen
          setState(() {
            _isAuthenticated = false;
            _userName = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Prüfen des Anmeldestatus: $e');
      setState(() {
        _isAuthenticated = false;
        _userName = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Prüft, ob das Token aktualisiert werden muss (älter als 45 Minuten)
  bool _needsTokenRefresh() {
    if (_lastTokenRefresh == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastTokenRefresh!);

    // Tokens laufen typischerweise nach 1 Stunde ab, wir aktualisieren nach 45 Minuten
    return difference.inMinutes > 45;
  }

  Future<void> _initializeGoogleCalendarSync(
      GoogleSignInAccount account) async {
    try {
      final googleAuth = await account.authentication;

      final authClient = GoogleAuthClient(googleAuth.accessToken!);

      final syncService =
          Provider.of<GoogleCalendarSyncService>(context, listen: false);
      final success = await syncService.initialize(authClient);

      if (success) {
        setState(() {
          _isInitialized = true;
          _lastTokenRefresh = DateTime.now();
        });
      } else {
        _showErrorSnackbar(
            'Fehler bei der Initialisierung der Google Calendar-Verbindung');
      }
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung von Google Calendar: $e');
      _showErrorSnackbar('Fehler bei der Initialisierung: $e');

      // Anmeldestatus zurücksetzen bei schwerwiegenden Fehlern
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        await _handleAuthError();
      }
    }
  }

  Future<void> _handleAuthError() async {
    setState(() {
      _isAuthenticated = false;
      _isInitialized = false;
      _userName = null;
    });

    _showErrorSnackbar(
        'Authentifizierungsfehler: Bitte melden Sie sich erneut an');

    // Abmelden, um aktuelle Token-Probleme zu löschen
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Fehler beim Abmelden nach Auth-Fehler: $e');
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _initializeGoogleCalendarSync(account);

        setState(() {
          _isAuthenticated = true;
          _userName = account.displayName;
          _lastTokenRefresh = DateTime.now();
        });

        // Führe initiale Synchronisierung durch
        await _syncGoogleCalendar();
      } else {
        _showErrorSnackbar('Anmeldung abgebrochen');
      }
    } catch (e) {
      debugPrint('Fehler beim Anmelden: $e');
      _showErrorSnackbar('Anmeldung fehlgeschlagen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);

    try {
      // Versuche, die aktuelle Anmeldesitzung zu aktualisieren
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _initializeGoogleCalendarSync(account);
        setState(() {
          _lastTokenRefresh = DateTime.now();
        });
        debugPrint('Token erfolgreich aktualisiert');
      } else {
        // Falls das stille Anmelden fehlschlägt, normale Anmeldung versuchen
        await _signIn();
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Tokens: $e');
      // Versuche vollständige Neuanmeldung
      await _handleAuthError();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await _googleSignIn.signOut();
      setState(() {
        _isAuthenticated = false;
        _userName = null;
        _isInitialized = false;
        _syncEnabled = false;
        _lastTokenRefresh = null;
      });

      // Deaktiviere Synchronisierung für diesen Termin
      if (widget.appointment != null && widget.appointment!.id != null) {
        final repo = Provider.of<AppointmentRepository>(context, listen: false);
        await repo.setGoogleSyncStatus(widget.appointment!.id!, false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erfolgreich abgemeldet'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Fehler beim Abmelden: $e');
      _showErrorSnackbar('Fehler beim Abmelden: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncGoogleCalendar() async {
    // Prüfe, ob Token-Aktualisierung nötig ist
    if (_isAuthenticated && _needsTokenRefresh()) {
      debugPrint('Token zu alt, wird aktualisiert...');
      await _refreshToken();
    }

    if (!_isAuthenticated) {
      _showErrorSnackbar('Bitte melden Sie sich an, um zu synchronisieren');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final syncService =
          Provider.of<GoogleCalendarSyncService>(context, listen: false);
      final success = await syncService.syncAllAppointments();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisierung erfolgreich'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackbar('Synchronisierung fehlgeschlagen');
      }
    } catch (e) {
      debugPrint('Fehler bei der Synchronisierung: $e');

      // Besondere Behandlung für Authentifizierungsfehler
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        await _handleAuthError();
      } else {
        _showErrorSnackbar('Synchronisierung fehlgeschlagen: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleSync(bool value) async {
    if (!_isAuthenticated) {
      // Nutzer muss angemeldet sein, um Synchronisierung zu aktivieren
      _showErrorSnackbar(
          'Bitte melden Sie sich an, um die Synchronisierung zu aktivieren');
      return;
    }

    // Prüfe, ob Token-Aktualisierung nötig ist
    if (_needsTokenRefresh()) {
      await _refreshToken();
      if (!_isAuthenticated) {
        return; // Wenn Authentifizierung fehlgeschlagen ist
      }
    }

    if (widget.appointment != null && widget.appointment!.id != null) {
      setState(() => _isLoading = true);

      try {
        final repo = Provider.of<AppointmentRepository>(context, listen: false);
        await repo.setGoogleSyncStatus(widget.appointment!.id!, value);

        // Im erfolgreichen Fall Status aktualisieren
        setState(() => _syncEnabled = value);

        // Synchronisiere, wenn aktiviert
        if (value) {
          await _syncGoogleCalendar();
        }
      } catch (e) {
        debugPrint('Fehler beim Ändern des Sync-Status: $e');
        _showErrorSnackbar('Fehler beim Ändern des Sync-Status: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wenn in Einstellungen, zeige vollständiges Widget, sonst nur Synchronisierungsschalter
    if (widget.isSettingsScreen) {
      return _buildSettingsWidget();
    } else {
      return _buildAppointmentSyncToggle();
    }
  }

  Widget _buildSettingsWidget() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Kalender',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!_isAuthenticated)
              _buildSignInButton()
            else
              _buildAuthenticatedView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Mit Google anmelden'),
        onPressed: _signIn,
      ),
    );
  }

  Widget _buildAuthenticatedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_circle, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Angemeldet als: $_userName',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_lastTokenRefresh != null)
                    Text(
                      'Aktualisiert: ${_formatDateTime(_lastTokenRefresh!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Alle mit Google zu synchronisierenden Termine werden automatisch '
          'in Ihrem Google Kalender aktualisiert. Termine, die von Gebetszeiten '
          'abhängen, werden als Einzeltermine synchronisiert.',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Jetzt synchronisieren'),
              onPressed: _syncGoogleCalendar,
            ),
            TextButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Abmelden'),
              onPressed: _signOut,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final today = DateTime.now();
    if (dateTime.year == today.year &&
        dateTime.month == today.month &&
        dateTime.day == today.day) {
      return 'Heute ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAppointmentSyncToggle() {
    return _isAuthenticated
        ? SwitchListTile(
            title: const Text('Mit Google Kalender synchronisieren'),
            subtitle: Text(_syncEnabled
                ? 'Dieser Termin wird mit Google synchronisiert'
                : 'Dieser Termin wird nicht mit Google synchronisiert'),
            value: _syncEnabled,
            onChanged: _toggleSync,
          )
        : ListTile(
            title: const Text('Mit Google Kalender synchronisieren'),
            subtitle: const Text('Melden Sie sich in den Einstellungen an, um '
                'Termine mit Google Kalender zu synchronisieren'),
            trailing: ElevatedButton(
              onPressed: _signIn,
              child: const Text('Anmelden'),
            ),
          );
  }
}

// Hilfsklasse für die Google API-Authentifizierung
class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
