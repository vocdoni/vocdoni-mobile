import 'package:flutter/foundation.dart';
import "dart:developer";

/// Prints the given text when the app is running in debug mode
void devPrint(Object text) {
  if (kReleaseMode) return;
  log(text);
}
