import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:flutter/material.dart';

void main() {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.vocdoni.net/gateways.dev.json",
      networkId: "sokol",
      linkingDomain: "dev.vocdoni.link");
  FlavorConfig(
      flavor: Flavor.DEV, constants: constants, bannerColor: Colors.red);

  // Start the app
  mainCommon();
}
