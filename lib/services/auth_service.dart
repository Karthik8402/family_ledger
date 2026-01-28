import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Use Client ID from environment variables (securely loaded from .env)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Attempt to restore the user's session silently
      await _googleSignIn.signInSilently();
    } catch (e) {
      // Silent sign-in failed. This is expected if the user is not logged in 
      // or if there are browser-specific issues (e.g. FedCM / 3rd party cookies).
      // We swallow the error to not interrupt the UI, as the user can sign in manually.
      debugPrint('Silent sign-in ignored error: $e');
    }
  }

  // Stream of auth changes
  Stream<GoogleSignInAccount?> get authStateChanges => _googleSignIn.onCurrentUserChanged;

  // Get current user synchronously
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  // Sign In with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      // On web, this manages the popup. On mobile, it handles native sign-in.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      return googleUser;
    } catch (e) {
      throw 'Failed to sign in with Google: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
