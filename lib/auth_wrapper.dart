import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/family_setup_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'widgets/biometric_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<GoogleSignInAccount?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // debugPrint('Auth: Waiting for auth state...');
          return const Scaffold(
              backgroundColor: Colors.white,
              body:
                  Center(child: CircularProgressIndicator(color: Colors.teal)));
        }

        // debugPrint('Auth: Snapshot hasData=${authSnapshot.hasData}');
        if (authSnapshot.hasData) {
          // User is logged in, check if they have a family
          return _FamilyCheckWrapper(userId: authSnapshot.data!.id);
        }

        return const LoginScreen();
      },
    );
  }
}

class _FamilyCheckWrapper extends StatelessWidget {
  final String userId;

  const _FamilyCheckWrapper({required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<UserModel?>(
      stream: firestoreService.streamUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data;

        // If user profile doesn't exist or no family, show family setup
        if (user == null || user.familyId == null || user.familyId!.isEmpty) {
          return const FamilySetupScreen();
        }

        // User has a family, show home with biometric check
        return const BiometricWrapper(child: HomeScreen());
      },
    );
  }
}
