import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricKey = 'biometric_enabled';

  // 1. Cek apakah device support biometric (Fingerprint/Face)
  Future<bool> isBiometricAvailable() async {
    try {
      // Cek apakah device punya hardware biometric
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print("❌ Biometric Check Error: $e");
      return false;
    }
  }

  // 2. Ambil daftar biometric yang tersedia (untuk info di UI)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // 3. Tampilkan dialog autentikasi biometric
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk membuka Rex4Red',
        options: const AuthenticationOptions(
          stickyAuth: true,       // Dialog tidak hilang jika app ke background
          biometricOnly: false,   // Izinkan fallback PIN/Pattern jika biometric gagal
          useErrorDialogs: true,  // Tampilkan dialog error bawaan OS
        ),
      );
    } catch (e) {
      print("❌ Biometric Auth Error: $e");
      return false;
    }
  }

  // 4. Baca preferensi user: apakah biometric lock diaktifkan?
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  // 5. Simpan preferensi user: aktif/nonaktif biometric lock
  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }
}
