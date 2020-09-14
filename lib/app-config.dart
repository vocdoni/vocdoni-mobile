/// Contains the compile-time defined config variables:
/// - `APP_MODE`: dev, beta, production
/// - `GATEWAY_BOOTNODES_URL`
/// - `NETWORK_ID` xdai, sokol
/// - `LINKING_DOMAIN`

class AppConfig {
  static const APP_MODE =
      String.fromEnvironment("APP_MODE", defaultValue: "dev");

  static bool isDevelopment() => APP_MODE == "dev";
  static bool isBeta() => APP_MODE == "beta";
  static bool isProduction() => APP_MODE == "production";

  static const GATEWAY_BOOTNODES_URL = String.fromEnvironment(
      "GATEWAY_BOOTNODES_URL",
      defaultValue: "https://bootnodes.vocdoni.net/gateways.dev.json");

  static const NETWORK_ID =
      String.fromEnvironment("NETWORK_ID", defaultValue: "xdai");

  static const LINKING_DOMAIN = String.fromEnvironment("LINKING_DOMAIN",
      defaultValue: "dev.vocdoni.link");
}
