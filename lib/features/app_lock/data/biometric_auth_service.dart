import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final available = await _localAuthentication.getAvailableBiometrics();
      debugPrint(
          '[BiometricAuthService] isSupported: $isSupported, canCheck: $canCheck, available: $available');
      if (!isSupported && !canCheck) return false;
      return true;
    } catch (e, stack) {
      debugPrint('[BiometricAuthService] isAvailable error: $e\n$stack');
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      final result = await _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      debugPrint('[BiometricAuthService] authenticate result: $result');
      return result;
    } catch (e, stack) {
      debugPrint('[BiometricAuthService] authenticate error: $e\n$stack');
      return false;
    }
  }
}
