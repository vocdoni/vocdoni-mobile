import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';

void main() async {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.github.io/gateways.json",
      networkId: "goerli");
  FlavorConfig(flavor: Flavor.PRODUCTION, constants: constants);

  // Start the app
  mainCommon();
}
