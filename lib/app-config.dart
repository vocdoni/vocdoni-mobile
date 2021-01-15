import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/logger.dart';

/// Contains the compile-time defined config variables:
/// - `APP_MODE`: dev, beta, production
/// - `GATEWAY_BOOTNODES_URL`
/// - `NETWORK_ID` xdai, sokol
/// - `LINKING_DOMAIN`

const String _appMode = String.fromEnvironment("APP_MODE", defaultValue: "dev");
String _bootnodesUrlOverride;
PackageInfo _packageInfo;
AndroidDeviceInfo _androidInfo;
IosDeviceInfo _iosInfo;

class AppConfig {
  static const APP_MODE = _appMode;

  static bool isDevelopment() => _appMode == "dev";
  static bool isBeta() => _appMode == "beta";
  static bool isProduction() => _appMode == "production";

  static bool useTestingContracts() => AppConfig.isBeta();

  static setBootnodesUrlOverride(String url) async {
    try {
      _bootnodesUrlOverride = url;
      await Globals.appState.refresh(force: true);
    } catch (err) {
      throw err;
    }
  }

  static String get bootnodesUrl =>
      _bootnodesUrlOverride ?? _GATEWAY_BOOTNODES_URL;

  // CONFIG VARS
  static const _GATEWAY_BOOTNODES_URL = String.fromEnvironment(
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

  static const IPFS_DOMAIN = "https://ipfs.io/ipfs/";

  static setPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (err) {
      logger.log(err);
    }
  }

  static PackageInfo get packageInfo => _packageInfo;

  static setDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        _androidInfo = await deviceInfo.androidInfo;
      }
      if (Platform.isIOS) {
        _iosInfo = await deviceInfo.iosInfo;
      }
    } catch (err) {
      logger.log(err);
    }
  }

  static String osVersion() {
    if (_androidInfo != null) return "Andriod " + _androidInfo.version.baseOS;
    if (_iosInfo != null) return "iOS " + _iosInfo.systemVersion;
    return "";
  }
}
