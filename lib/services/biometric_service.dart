import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  bool? _isSupportedCached;
  bool? _canCheckBiometricsCached;

  /// Checks if the device supports biometric authentication.
  /// Results are cached to avoid redundant platform calls.
  Future<bool> isSupported() async {
    if (_isSupportedCached != null) return _isSupportedCached!;
    try {
      _isSupportedCached = await _auth.isDeviceSupported();
      return _isSupportedCached!;
    } catch (e) {
      debugPrint('Error checking device support: $e');
      return false;
    }
  }

  /// Checks if biometrics are available and configured.
  /// Results are cached for performance.
  Future<bool> canCheckBiometrics() async {
    if (_canCheckBiometricsCached != null) return _canCheckBiometricsCached!;
    try {
      _canCheckBiometricsCached = await _auth.canCheckBiometrics;
      return _canCheckBiometricsCached!;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Combined check for both hardware support and availability.
  Future<bool> isAvailable() async {
    final supported = await isSupported();
    if (!supported) return false;
    return await canCheckBiometrics();
  }

  /// Standardized authentication method with optimized options.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected authentication error: $e');
      return false;
    }
  }
}
