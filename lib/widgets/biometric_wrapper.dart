import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

class BiometricWrapper extends StatefulWidget {
  final Widget child;

  const BiometricWrapper({super.key, required this.child});

  @override
  State<BiometricWrapper> createState() => _BiometricWrapperState();
}

class _BiometricWrapperState extends State<BiometricWrapper> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticated = false;
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometrics();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-authenticate when app resumes if biometrics is enabled
      // Optional: Add timeout logic, but for now strict lock
      if (_isEnabled && !_isAuthenticated) {
        _authenticate();
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final enabled = await _biometricService.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
      });
      if (enabled) {
        _authenticate();
      } else {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    final authenticated = await _biometricService.authenticate();
    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return widget.child;
    }

    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!_isLoading)
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            if (_isLoading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
