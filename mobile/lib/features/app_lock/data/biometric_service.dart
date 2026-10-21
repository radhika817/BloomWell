import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthResult {
  success,
  failed,
  canceled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error;
}

/// Abstract biometric authentication service interface to permit mock injection in tests.
abstract class BiometricService {
  Future<bool> isDeviceSupported();
  Future<bool> canCheckBiometrics();
  Future<BiometricAuthResult> authenticate({required String localizedReason});
}

/// Production biometric authentication wrapper around `LocalAuthentication`.
class LocalBiometricService implements BiometricService {
  LocalBiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    if (kIsWeb) return BiometricAuthResult.notAvailable;

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );
      return didAuthenticate
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricAuthResult.notAvailable;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return BiometricAuthResult.notEnrolled;
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          return BiometricAuthResult.canceled;
        case LocalAuthExceptionCode.temporaryLockout:
          return BiometricAuthResult.lockedOut;
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricAuthResult.permanentlyLockedOut;
        default:
          return BiometricAuthResult.error;
      }
    } catch (_) {
      return BiometricAuthResult.error;
    }
  }
}
