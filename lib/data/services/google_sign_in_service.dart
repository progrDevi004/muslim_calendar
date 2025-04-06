import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  late final GoogleSignIn _googleSignIn;

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    final scopes = [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ];

    // Client-ID nur für iOS hinzufügen
    if (Platform.isIOS) {
      _googleSignIn = GoogleSignIn(
        scopes: scopes,
        clientId:
            '778895687512-t7lq66jbs8ljd1rredheoeoqfe5g8in8.apps.googleusercontent.com',
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: scopes,
      );
    }

    // // Verwende die Android-Version ohne Client-ID
    // _googleSignIn = GoogleSignIn(
    //   scopes: scopes,
    // );
  }

  GoogleSignIn get googleSignIn => _googleSignIn;
}
