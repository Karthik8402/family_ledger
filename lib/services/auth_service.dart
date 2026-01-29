import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  final _authStreamController = StreamController<GoogleSignInAccount?>.broadcast();

  AuthService() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _authStreamController.add(account);
    });
    _init();
  }

  Future<void> _init() async {
    try {
      // Try to restore previous session silently
      // Increased timeout for better reliability
      await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Silent sign-in timed out');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    } finally {
      // Ensure we emit null if no user, so StreamBuilder can show login
      if (_googleSignIn.currentUser == null) {
        _authStreamController.add(null);
      }
    }
  }

  Stream<GoogleSignInAccount?> get authStateChanges => _authStreamController.stream;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      return googleUser;
    } catch (e) {
      throw 'Failed to sign in with Google: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
