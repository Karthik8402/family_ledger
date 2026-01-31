import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget that shows an offline indicator banner when there's no internet connection
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty || 
                      results.every((r) => r == ConnectivityResult.none);
    
    // Prent duplicate updates if status hasn't changed
    if (isOffline == _isOffline) return;

    if (mounted) {
      setState(() {
        _isOffline = isOffline;
        // Show banner immediately when offline, hide with delay when online
        if (isOffline) {
          _showBanner = true;
        } else {
          // Small delay before hiding to avoid flickering
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isOffline) {
              setState(() => _showBanner = false);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Offline Banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showBanner ? null : 0,
          child: _showBanner
              ? Material(
                  color: _isOffline 
                      ? Colors.orange.shade700 
                      : Colors.green.shade600,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOffline 
                                ? Icons.cloud_off 
                                : Icons.cloud_done,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOffline 
                                ? 'You\'re offline. Changes will sync when connected.'
                                : 'Back online! Syncing...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().slideY(begin: -1, end: 0, duration: 300.ms)
              : const SizedBox.shrink(),
        ),
        
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
