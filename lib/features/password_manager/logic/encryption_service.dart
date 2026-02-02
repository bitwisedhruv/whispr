import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Derives a 32-byte key from a PIN and a salt using SHA-256.
  /// In a production environment, PBKDF2 or Argon2 would be better,
  /// but SHA-256 is a good starting point for this implementation.
  encrypt.Key deriveKey(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
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
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

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
      throw Exception('Decryption failed: Likely wrong key or corrupted data.');
    }
  }
}
