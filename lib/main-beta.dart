import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:flutter/material.dart';

/// The actual main function is defined on main-dev.dart and main-production.dart.
/// These are expected to call mainCommon() when done
void main() async {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.github.io/gateways.dev.json");
  FlavorConfig(
      flavor: Flavor.QA, constants: constants, bannerColor: Colors.indigo);

  // Start the app
  mainCommon();
}
