import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // To hash the passphrase to a fixed length
import 'package:pinenacl/public.dart';
import 'package:pinenacl/secret.dart' show SecretBox;

/// Encrypts the given data and returns a Uint8List containing `nonce[24] + cipherText[]`.
/// The 24 first bytes represent the nonce, and the rest of the buffer contains the cipher text.
Uint8List encrypt(Uint8List buffer, String passphrase) {
  final key = utf8.encode(passphrase);
  final keyDigest =
      sha256.convert(key); // Hash the passphrase to get a 32 byte key
  final box = SecretBox(keyDigest.bytes);
  final encrypted = box.encrypt(buffer);

  return Uint8List.fromList(encrypted.toList());
}

/// Encrypts the given string and returns a Uint8List containing `nonce[24] + cipherText[]`.
/// The 24 first bytes must contain the nonce, and the rest of the buffer needs to contain the cipher text.
Uint8List encryptString(String data, String passphrase) {
  final strBytes = Uint8List.fromList(utf8.encode(data));

  return encrypt(strBytes, passphrase);
}

/// Decrypts a byte array containing `nonce[24] + cipherText[]` using NaCl SecretBox:
/// https://github.com/ilap/pinenacl-dart#a-secret-key-encryption-example
Uint8List decrypt(Uint8List encryptedBuffer, String passphrase) {
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
String decryptAsString(Uint8List encryptedBuffer, String passphrase) {
  final strBytes = decrypt(encryptedBuffer, passphrase);

  return utf8.decode(strBytes);
}
