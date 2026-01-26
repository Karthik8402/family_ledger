import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred';
    }
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
