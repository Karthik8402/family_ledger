import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // Stream of Firebase Auth state changes - this is what Firestore uses for request.auth
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  AuthService() {
    // _init(); // Disabled: Prevents auto-login when Google account exists on device
  }

  Future<void> _init() async {
    try {
      // Try to restore previous Google session silently
      final googleUser = await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Silent sign-in timed out');
          return null;
        },
      );

      // If we have a Google user but no Firebase user, sign in to Firebase
      if (googleUser != null && _firebaseAuth.currentUser == null) {
        await _signInToFirebase(googleUser);
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      // 2. Get auth details from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with Google credential - THIS populates request.auth!
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      throw 'Failed to sign in with Google: $e';
    }
  }

  Future<User?> _signInToFirebase(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Failed to sign in to Firebase: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
  }
}
