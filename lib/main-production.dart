import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';

void main() {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.vocdoni.net/gateways.json",
      networkId: "xdai");
  FlavorConfig(flavor: Flavor.PRODUCTION, constants: constants);

  // Start the app
  mainCommon();
}
