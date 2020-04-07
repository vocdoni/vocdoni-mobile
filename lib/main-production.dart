import 'package:vocdoni/main.dart';
import 'package:dvote_common/flavors/config.dart';

/// The actual main function is defined on main-dev.dart and main-production.dart.
/// These are expected to call mainCommon() when done
void main() async {
  // Set the global flavor config in the singleton
  final constants = FlavorConstants(
      gatewayBootNodesUrl: "https://bootnodes.github.io/gateways.json");
  FlavorConfig(flavor: Flavor.PRODUCTION, constants: constants);

  // Start the app
  mainCommon();
}
