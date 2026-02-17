import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Derives a 32-byte key from a PIN and a salt using PBKDF2 with 100,000 iterations.
  /// This provides significant resistance against brute-force attacks.
  /// Uses the 'cryptography' package which leverages native platform APIs for performance.
  Future<encrypt.Key> deriveKey(String pin, String salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    // Pbkdf2 implementation in 'cryptography' is already optimized and
    // often uses native platform APIs (via cryptography_flutter).
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: pin,
      nonce: utf8.encode(salt),
    );

    final keyBytes = await secretKey.extractBytes();
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypts plain text using the provided key.
  /// Returns a Base64 encoded string containing IV + Ciphertext.
  String encryptText(String plainText, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Ciphertext for storage
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);

    return base64.encode(combined);
  }

  /// Decrypts a Base64 encoded string (IV + Ciphertext) using the provided key.
  String decryptText(String combinedBase64, encrypt.Key key) {
    try {
      final combined = base64.decode(combinedBase64);
      final iv = encrypt.IV(combined.sublist(0, 16));
      final ciphertext = combined.sublist(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );
      return encrypter.decrypt(encrypt.Encrypted(ciphertext), iv: iv);
    } catch (e) {
      // Decryption failed. This is handled by callers.
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }
}
