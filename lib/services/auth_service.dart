import 'dart:async';
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

  // Stream controller to handle auth state changes and force initial value
  final _authStreamController = StreamController<GoogleSignInAccount?>.broadcast();

  AuthService() {
    // Forward Google Sign-In events to our controller
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _authStreamController.add(account);
    });
    _init();
  }

  Future<void> _init() async {
    try {
      // Attempt to restore the user's session silently
      // We add a timeout so the user isn't staring at a loading screen forever
      // if the network is slow or Google is taking time to respond.
      await _googleSignIn.signInSilently().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Silent sign-in ignored or timed out: $e');
    } finally {
      // CRITICAL: Force an emission to unblock StreamBuilders waiting for connection
      // If user is null (not signed in), this ensures 'null' is emitted so
      // StreamBuilder knows we are done waiting and can show LoginScreen.
      if (_googleSignIn.currentUser == null) {
        _authStreamController.add(null);
      }
    }
  }

  // Stream of auth changes - now using our wrapper controller
  Stream<GoogleSignInAccount?> get authStateChanges => _authStreamController.stream;

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
