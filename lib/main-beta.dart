import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:flutter/material.dart';

void main() async {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.vocdoni.net/gateways.dev.json",
      networkId: "goerli",
      linkingDomain: "dev.vocdoni.link");
  FlavorConfig(
      flavor: Flavor.QA, constants: constants, bannerColor: Colors.indigo);

  // Start the app
  mainCommon();
}
