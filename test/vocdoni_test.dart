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

  test('Encryption wrapper: Strings should match', () {
    final encrypted1 = encryptString(msg1, passphrase1);
    final decrypted1 = decryptAsString(encrypted1, passphrase1);
    expect(decrypted1, msg1, reason: "Decrypted string does not match");

    final encrypted2 = encryptString(msg2, passphrase1);
    final decrypted2 = decryptAsString(encrypted2, passphrase1);
    expect(decrypted2, msg2, reason: "Decrypted string does not match");

    final encrypted3 = encryptString(msg1, passphrase2);
    final decrypted3 = decryptAsString(encrypted3, passphrase2);
    expect(decrypted3, msg1, reason: "Decrypted string does not match");

    final encrypted4 = encryptString(msg2, passphrase2);
    final decrypted4 = decryptAsString(encrypted4, passphrase2);
    expect(decrypted4, msg2, reason: "Decrypted string does not match");
  });

  test('Encryption wrapper: Bytes should match', () {
    final msg1Buffer = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final msg2Buffer =
        Uint8List.fromList([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]);

    final encrypted1 = encrypt(msg1Buffer, passphrase1);
    final decrypted1 = decrypt(encrypted1, passphrase1);
    expect(decrypted1.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted2 = encrypt(msg2Buffer, passphrase1);
    final decrypted2 = decrypt(encrypted2, passphrase1);
    expect(decrypted2.join(","), msg2Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted3 = encrypt(msg1Buffer, passphrase2);
    final decrypted3 = decrypt(encrypted3, passphrase2);
    expect(decrypted3.join(","), msg1Buffer.join(","),
        reason: "Decrypted string does not match");

    final encrypted4 = encrypt(msg2Buffer, passphrase2);
    final decrypted4 = decrypt(encrypted4, passphrase2);
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
      final encrypted1 = encryptString(msg1, passphrase1);
      decryptAsString(
          encrypted1, passphrase1 + "INVALID_PASSPHRASE_THAT_DOES_NOT_MATCH");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted2 = encryptString(msg2, passphrase1);
      decryptAsString(
          encrypted2, passphrase1 + "INVALID_PASSPHRASE_THAT_DOES_NOT_MATCH");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted3 = encryptString(msg1, passphrase2);
      decryptAsString(encrypted3, passphrase2 + "1234 RANDOM PASSPHRASE");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }

    try {
      final encrypted4 = encryptString(msg2, passphrase2);
      decryptAsString(encrypted4, passphrase2 + "1234 RANDOM PASSPHRASE");
      expect(0, 1, reason: "Decrypting should have failed but didn't");
    } on TestFailure catch (err) {
      if (err.message == unexpectedErrorString) throw err.message;
    } catch (err) {
      if (err != expectedErrorString) throw err;
    }
  });
}
