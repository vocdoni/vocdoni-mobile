/// Contains the compile-time defined config variables:
/// - `APP_MODE`: dev, beta, production
/// - `GATEWAY_BOOTNODES_URL`
/// - `NETWORK_ID` xdai, sokol
/// - `LINKING_DOMAIN`

const String _appMode = String.fromEnvironment("APP_MODE", defaultValue: "dev");

class AppConfig {
  static const APP_MODE = _appMode;

  static bool isDevelopment() => _appMode == "dev";
  static bool isBeta() => _appMode == "beta";
  static bool isProduction() => _appMode == "production";

  static bool useTestingContracts() => AppConfig.isBeta();

  // CONFIG VARS
  static const GATEWAY_BOOTNODES_URL = String.fromEnvironment(
    "GATEWAY_BOOTNODES_URL",
    defaultValue: _appMode == "dev"
        ? "https://bootnodes.vocdoni.net/gateways.dev.json"
        : "https://bootnodes.vocdoni.net/gateways.json",
  );

  static const NETWORK_ID = String.fromEnvironment(
    "NETWORK_ID",
    defaultValue: _appMode == "dev" ? "sokol" : "xdai",
  );

  static const LINKING_DOMAIN = String.fromEnvironment(
    "LINKING_DOMAIN",
    defaultValue: _appMode == "dev" ? "dev.vocdoni.link" : "vocdoni.link",
  );
}
