import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/family_setup_screen.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (authSnapshot.hasData) {
          // User is logged in, check if they have a family
          return _FamilyCheckWrapper(userId: authSnapshot.data!.uid);
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
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return StreamBuilder<UserModel?>(
      stream: firestoreService.streamUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = userSnapshot.data;
        
        // If user profile doesn't exist or no family, show family setup
        if (user == null || user.familyId == null || user.familyId!.isEmpty) {
          return const FamilySetupScreen();
        }
        
        // User has a family, show home
        return const HomeScreen();
      },
    );
  }
}
