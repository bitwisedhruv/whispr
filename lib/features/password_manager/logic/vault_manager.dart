import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:whispr/services/supabase_service.dart';
import 'encryption_service.dart';

class VaultManager {
  static final VaultManager _instance = VaultManager._internal();
  factory VaultManager() => _instance;
  VaultManager._internal();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _encryptionService = EncryptionService();

  static const _pinKey = 'master_pin';
  static const _saltKey = 'vault_salt';

  encrypt.Key? _sessionKey;

  encrypt.Key? get sessionKey => _sessionKey;
  bool get isVaultLocked => _sessionKey == null;

  /// Checks if the vault has been set up (PIN exists).
  Future<bool> isVaultSetUp() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  /// Sets up the vault with a new PIN.
  Future<void> setupVault(String pin) async {
    // Check if a salt already exists in Supabase
    String? salt = await SupabaseService.getVaultSalt();

    if (salt == null) {
      // New user or no salt synced yet
      salt = DateTime.now().millisecondsSinceEpoch.toString();
      await SupabaseService.updateProfile(vaultSalt: salt);
    }

    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _saltKey, value: salt);

    // Auto-unlock after setup
    _sessionKey = _encryptionService.deriveKey(pin, salt);
  }

  /// Unlocks the vault using the PIN.
  Future<bool> unlockWithPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    String? salt = await _storage.read(key: _saltKey);

    // If local salt is missing but user is logged in, try to fetch from Supabase
    if (salt == null && SupabaseService.currentUser != null) {
      salt = await SupabaseService.getVaultSalt();
      if (salt != null) {
        await _storage.write(key: _saltKey, value: salt);
      }
    }

    if (storedPin == pin && salt != null) {
      _sessionKey = _encryptionService.deriveKey(pin, salt);
      return true;
    }
    return false;
  }

  /// Unlocks the vault using Biometrics.
  /// Note: The PIN must still be stored to derive the key.
  Future<bool> unlockWithBiometrics() async {
    final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
      return false;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock your vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        final pin = await _storage.read(key: _pinKey);
        String? salt = await _storage.read(key: _saltKey);

        // If local salt is missing but user is logged in, try to fetch from Supabase
        if (salt == null && SupabaseService.currentUser != null) {
          salt = await SupabaseService.getVaultSalt();
          if (salt != null) {
            await _storage.write(key: _saltKey, value: salt);
          }
        }

        if (pin != null && salt != null) {
          _sessionKey = _encryptionService.deriveKey(pin, salt);
          return true;
        }
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  /// Locks the vault and clears the session key.
  void lockVault() {
    _sessionKey = null;
  }

  /// Reset the vault (deletes stored PIN and salt).
  /// WARNING: This will make all existing local encrypted data unrecoverable.
  Future<void> resetVault() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _saltKey);
    _sessionKey = null;
  }

  /// Helper to get user's SALT (for multi-device sync - in future)
  Future<String?> getSalt() async => await _storage.read(key: _saltKey);
}
