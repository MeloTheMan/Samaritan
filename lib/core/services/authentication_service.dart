import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_storage_service.dart';

@lazySingleton
class AuthenticationService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _secureStorage;

  static const String _pinKey = 'user_pin';

  AuthenticationService(this._localAuth, this._secureStorage);

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à vos données de santé',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithPIN(String pin) async {
    final storedPin = await _secureStorage.readEncrypted(_pinKey);
    return storedPin == pin;
  }

  Future<void> setupPIN(String pin) async {
    await _secureStorage.saveEncrypted(_pinKey, pin);
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPINSetup() async {
    final pin = await _secureStorage.readEncrypted(_pinKey);
    return pin != null && pin.isNotEmpty;
  }
}
