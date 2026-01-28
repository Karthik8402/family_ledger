import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/toast_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // 1. Sign in with Google
      final user = await authService.signInWithGoogle();
      
      if (user != null) {
        // 2. Check if user profile exists
        final userProfile = await firestoreService.getUserProfile(user.id);
        
        if (userProfile == null) {
          // 3. Create new profile if first time
          await firestoreService.createUserProfile(
            user.id,
            user.displayName ?? 'User',
            user.email ?? '',
            user.photoUrl,
          );
        } else {
          // 4. If user exists, sync latest Google profile data (photo, name, etc.)
          await firestoreService.syncGoogleProfile(
            user.id,
            user.displayName,
            user.email,
            user.photoUrl,
          );
        }
        
        // Navigation is handled by the auth state stream in AuthWrapper (main.dart)
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Sign In Failed';
        final errorString = e.toString().toLowerCase();

        // 1. Suppress toast for popup_closed (user cancelled)
        if (errorString.contains('popup_closed')) {
          debugPrint('Sign in cancelled by user');
          return; // Exit without showing toast
        } 
        
        if (errorString.contains('network_error')) {
          errorMessage = 'Check your internet connection';
        } else {
          // Clean up the "Exception:" prefix if present
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ToastUtils.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                : [const Color(0xFF00695C), const Color(0xFF00897B), const Color(0xFF4DB6AC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                  
                  const SizedBox(height: 48),
                  
                  // Welcome Text
                  const Text(
                    'Family Ledger',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Shared expenses made simple',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 64),
                  
                  // Google Sign In Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Logo (simulated with Icon if usage of asset is tricky without adding it first, 
                              // but standard practice usually uses an asset. Since I can't guarantee the asset exists, 
                              // I'll use a generic icon or text, but user expects Google logo. 
                              // I'll use a coloured G icon placeholder or text).
                              // Actually, Flutter doesn't have a built-in Google logo icon in Material Icons.
                              // I will stick to text + generic icon or no icon if risk is high.
                              // Let's use a nice "login" icon alongside text for now to be safe,
                              // or just text "Continue with Google".
                              // Simulating the G logo with a container is safer than assuming an asset.
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue, // Simplified Google Blue
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto', 
                                    fontSize: 16
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Secure authentication powered by Google',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
