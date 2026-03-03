import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si la biométrie est disponible
  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Authentification par empreinte digitale
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Veuillez confirmer votre identité',
      );
    } catch (e) {
      return false;
    }
  }
}
