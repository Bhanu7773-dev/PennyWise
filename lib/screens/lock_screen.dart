import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biometric_service.dart';
import '../utils/app_theme.dart';
import 'package:vibration/vibration.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const LockScreen({super.key, required this.child, required this.isEnabled});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isLocked = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isEnabled) {
      _authenticate();
    } else {
      _isLocked = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isEnabled) return;

    if (state == AppLifecycleState.paused) {
      // App went to background - lock it
      setState(() {
        _isLocked = true;
      });
    } else if (state == AppLifecycleState.resumed && _isLocked) {
      // App came back - authenticate
      _authenticate();
    }
  }

  @override
  void didUpdateWidget(LockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If lock was disabled, unlock
    if (!widget.isEnabled && _isLocked) {
      setState(() {
        _isLocked = false;
      });
    }
    // If lock was just enabled (e.g., settings loaded after cold start), lock and authenticate
    if (widget.isEnabled && !oldWidget.isEnabled) {
      setState(() {
        _isLocked = true;
      });
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    // Provide immediate haptic feedback for button press
    Vibration.vibrate(duration: 50, amplitude: 128);

    setState(() {
      _isAuthenticating = true;
    });

    try {
      // Use combined fast check from BiometricService
      final isAvailable = await _biometricService.isAvailable();

      if (!isAvailable) {
        // No biometrics available, unlock anyway
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
        return;
      }

      final didAuthenticate = await _biometricService.authenticate(
        localizedReason: 'Authenticate to access PennyWise',
        biometricOnly: false, // Allow PIN/pattern as fallback
      );

      if (didAuthenticate) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      debugPrint('Auth error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled || !_isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // App name
              const Text(
                'PennyWise',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Locked',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),

              // Authenticate button
              if (_isAuthenticating)
                const CircularProgressIndicator(color: AppTheme.primary)
              else
                GestureDetector(
                  onTap: _authenticate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Unlock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                'Use fingerprint, face, or device PIN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
