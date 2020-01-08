import 'dart:math';

String randomString() {
  var random = Random.secure();
  var values = List<int>.generate(8, (i) => random.nextInt(256));

  return values.map((int n) => n.toRadixString(16)).toList().join("");
}
