import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      if (!await _localAuthentication.isDeviceSupported()) return false;
      if (!await _localAuthentication.canCheckBiometrics) return false;
      return (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
