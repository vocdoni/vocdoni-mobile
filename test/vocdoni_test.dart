import 'package:flutter_test/flutter_test.dart';

import 'package:vocdoni/lib/encryption.dart';
import 'dart:typed_data';

void main() {
  testBoxEncryptionWrapper();
}

testBoxEncryptionWrapper() {
  final msg1 =
      "Change is a tricky thing, it threatens what we find familiar with...";
  final msg2 =
      "Changes are a hacky thing that threaten what we are familiar with...";

  final passphrase1 = "Top secret";
  final passphrase2 = "Ultra top secret";

  test('Encryption wrapper: String encryption should match', () {
    final encrypted1 = Symmetric.encryptString(msg1, passphrase1);
    final decrypted1 = Symmetric.decryptString(encrypted1, passphrase1);
    expect(decrypted1, msg1, reason: "Decrypted string does not match");

    final encrypted2 = Symmetric.encryptString(msg2, passphrase1);
    final decrypted2 = Symmetric.decryptString(encrypted2, passphrase1);
    expect(decrypted2, msg2, reason: "Decrypted string does not match");

    final encrypted3 = Symmetric.encryptString(msg1, passphrase2);
    final decrypted3 = Symmetric.decryptString(encrypted3, passphrase2);
    expect(decrypted3, msg1, reason: "Decrypted string does not match");

    final encrypted4 = Symmetric.encryptString(msg2, passphrase2);
    final decrypted4 = Symmetric.decryptString(encrypted4, passphrase2);
    expect(decrypted4, msg2, reason: "Decrypted string does not match");
  });

  test('Encryption wrapper: Byte array encryption should match', () {
    final msg1Buffer = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final msg2Buffer =
        Uint8List.fromList([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]);

    final encrypted1 = Symmetric.encryptBytes(msg1Buffer, passphrase1);
    final decrypted1 = Symmetric.decryptBytes(encrypted1, passphrase1);
    expect(decrypted1.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted2 = Symmetric.encryptBytes(msg2Buffer, passphrase1);
    final decrypted2 = Symmetric.decryptBytes(encrypted2, passphrase1);
    expect(decrypted2.join(","), msg2Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted3 = Symmetric.encryptBytes(msg1Buffer, passphrase2);
    final decrypted3 = Symmetric.decryptBytes(encrypted3, passphrase2);
    expect(decrypted3.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted4 = Symmetric.encryptBytes(msg2Buffer, passphrase2);
    final decrypted4 = Symmetric.decryptBytes(encrypted4, passphrase2);
    expect(decrypted4.join(","), msg2Buffer.join(","),
        reason: "Decrypted string does not match");
  });

  test('Encryption wrapper: Bytes should match', () {
    final msg1Buffer = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final msg2Buffer =
        Uint8List.fromList([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]);

    final encrypted1 = Symmetric.encryptRaw(msg1Buffer, passphrase1);
    final decrypted1 = Symmetric.decryptRaw(encrypted1, passphrase1);
    expect(decrypted1.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted2 = Symmetric.encryptRaw(msg2Buffer, passphrase1);
    final decrypted2 = Symmetric.decryptRaw(encrypted2, passphrase1);
    expect(decrypted2.join(","), msg2Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted3 = Symmetric.encryptRaw(msg1Buffer, passphrase2);
    final decrypted3 = Symmetric.decryptRaw(encrypted3, passphrase2);
    expect(decrypted3.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted4 = Symmetric.encryptRaw(msg2Buffer, passphrase2);
    final decrypted4 = Symmetric.decryptRaw(encrypted4, passphrase2);
    expect(decrypted4.join(","), msg2Buffer.join(","),
        reason: "Decrypted string does not match");
  });

  test('Encryption wrapper: Invalid passphrases should fail', () {
    final expectedErrorString =
        "The message is forged or malformed or the shared secret is invalid";
    final unexpectedErrorString = """Expected: <1>
  Actual: <0>
Decrypting should have failed but didn't
""";

    try {
      final encrypted1 = Symmetric.encryptString(msg1, passphrase1);
      Symmetric.decryptString(
          encrypted1, passphrase1 + "INVALID_PASSPHRASE_THAT_DOES_NOT_MATCH");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted2 = Symmetric.encryptString(msg2, passphrase1);
      Symmetric.decryptString(
          encrypted2, passphrase1 + "INVALID_PASSPHRASE_THAT_DOES_NOT_MATCH");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted3 = Symmetric.encryptString(msg1, passphrase2);
      Symmetric.decryptString(
          encrypted3, passphrase2 + "1234 RANDOM PASSPHRASE");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted4 = Symmetric.encryptString(msg2, passphrase2);
      Symmetric.decryptString(
          encrypted4, passphrase2 + "1234 RANDOM PASSPHRASE");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }
  });
}
