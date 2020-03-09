import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // To hash the passphrase to a fixed length
import 'package:pinenacl/public.dart';
import 'package:pinenacl/secret.dart' show SecretBox;

class Symmetric {
  /// Encrypts the given data using NaCl SecretBox and returns a Uint8List containing `nonce[24] + cipherText[]`.
  /// The 24 first bytes represent the nonce, and the rest of the buffer contains the cipher text.
  static Uint8List encryptRaw(Uint8List buffer, String passphrase) {
    final key = utf8.encode(passphrase);
    final keyDigest =
        sha256.convert(key); // Hash the passphrase to get a 32 byte key
    final box = SecretBox(keyDigest.bytes);
    final encrypted = box.encrypt(buffer);

    return Uint8List.fromList(encrypted.toList());
  }

  /// Encrypts the given data using NaCl SecretBox and returns a Base64 string containing `nonce[24] + cipherText[]`.
  /// The 24 first bytes represent the nonce, and the rest of the buffer contains the cipher text.
  static String encryptBytes(Uint8List buffer, String passphrase) {
    final encryptedBuffer = encryptRaw(buffer, passphrase);

    return base64.encode(encryptedBuffer);
  }

  /// Encrypts the given string using NaCl SecretBox and returns a Base64 string containing `nonce[24] + cipherText[]`.
  /// The 24 first bytes must contain the nonce, and the rest of the buffer needs to contain the cipher text.
  static String encryptString(String message, String passphrase) {
    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final encryptedBuffer = encryptRaw(messageBytes, passphrase);

    return base64.encode(encryptedBuffer);
  }

  /// Decrypts a byte array containing `nonce[24] + cipherText[]` using NaCl SecretBox:
  /// https://github.com/ilap/pinenacl-dart#a-secret-key-encryption-example
  static Uint8List decryptRaw(Uint8List encryptedBuffer, String passphrase) {
    final key = utf8.encode(passphrase);
    final keyDigest =
        sha256.convert(key); // Hash the passphrase to get a 32 byte key
    final box = SecretBox(keyDigest.bytes);

    final encrypted = EncryptedMessage(
        cipherText: encryptedBuffer.sublist(24),
        nonce: encryptedBuffer.sublist(0, 24));
    return box.decrypt(encrypted);
  }

  /// Decrypts a byte array containing `nonce[24] + cipherText[]` using NaCl SecretBox:
  /// https://github.com/ilap/pinenacl-dart#a-secret-key-encryption-example
  static Uint8List decryptBytes(String encryptedBase64, String passphrase) {
    final encryptedBuffer = base64.decode(encryptedBase64);
    return decryptRaw(encryptedBuffer, passphrase);
  }

  /// Decrypts a byte array containing `nonce[24] + cipherText[]` into a String using NaCl SecretBox:
  /// https://github.com/ilap/pinenacl-dart#a-secret-key-encryption-example
  static String decryptString(String encryptedBase64, String passphrase) {
    final encryptedBuffer = base64.decode(encryptedBase64);
    final strBytes = decryptRaw(encryptedBuffer, passphrase);

    return utf8.decode(strBytes);
  }
}

class Asymmetric {}
