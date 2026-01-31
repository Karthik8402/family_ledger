import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'biometrics_enabled';

  // Check if biometrics is available on device
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false; // Not supporting web biometrics yet
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics support: $e');
      return false;
    }
  }

  // Check if user has enabled biometrics in settings
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  // Toggle biometrics setting
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  // Authenticate user
  Future<bool> authenticate() async {
    try {
      if (!await isDeviceSupported()) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Family Ledger',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }
}
