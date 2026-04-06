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
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null;
    } catch (e) {
      // If we can't read the storage (e.g. decryption error), treat as not set up
      // but log the error if possible.
      return false;
    }
  }

  /// Sets up the vault with a new PIN.
  Future<void> setupVault(String pin) async {
    try {
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
      _sessionKey = await _encryptionService.deriveKey(pin, salt);
    } catch (e) {
      // Handle potential storage write errors
      throw Exception('Failed to setup vault: ${e.toString()}');
    }
  }

  /// Unlocks the vault using the PIN.
  Future<bool> unlockWithPin(String pin) async {
    try {
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
        _sessionKey = await _encryptionService.deriveKey(pin, salt);
        return true;
      }
    } catch (e) {
      // Storage decryption error or other platform error
      // Rethrow to be handled by the UI
      throw Exception(
        'Vault storage is unreadable. This can happen if the app\'s signature has changed. '
        'Please try resetting the vault. Error: ${e.toString()}',
      );
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
          _sessionKey = await _encryptionService.deriveKey(pin, salt);
          return true;
        }
      }
    } catch (e) {
      // Handle error (including storage decryption errors)
      if (e.toString().contains('decryption') ||
          e.toString().contains('KeyStore')) {
        throw Exception(
          'Biometric unlock failed due to secure storage error. '
          'Please use your PIN or reset the vault.',
        );
      }
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
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _saltKey);
    } catch (e) {
      // If delete fails (very rare), we might need to wipe all
      await _storage.deleteAll();
    }
    _sessionKey = null;
  }

  /// Helper to get user's SALT (for multi-device sync - in future)
  Future<String?> getSalt() async {
    try {
      return await _storage.read(key: _saltKey);
    } catch (e) {
      return null;
    }
  }

  /// Verifies if a PIN is correct without setting it as the session key.
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _storage.read(key: _pinKey);
      return storedPin == pin;
    } catch (e) {
      return false;
    }
  }

  /// Updates the vault with a new PIN.
  /// Note: The caller is responsible for re-encrypting data before/after calling this if needed.
  Future<void> changePin(String newPin) async {
    try {
      final salt = await _storage.read(key: _saltKey) ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await _storage.write(key: _pinKey, value: newPin);
      await _storage.write(key: _saltKey, value: salt);

      // Update session key
      _sessionKey = await _encryptionService.deriveKey(newPin, salt);
    } catch (e) {
      throw Exception('Failed to change PIN: ${e.toString()}');
    }
  }
}
