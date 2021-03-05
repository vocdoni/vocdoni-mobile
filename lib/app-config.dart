import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:dvote/constants.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/logger.dart';

/// Contains the compile-time defined config variables:
/// - `APP_MODE`: dev, beta, production
/// - `GATEWAY_BOOTNODES_URL`
/// - `NETWORK_ID` xdai, sokol
/// - `LINKING_DOMAIN`

const String _appMode = String.fromEnvironment("APP_MODE", defaultValue: "dev");
String _bootnodesUrlOverride;
String _networkOverride;
String _ensDomainSuffixOverride;
PackageInfo _packageInfo;
AndroidDeviceInfo _androidInfo;
IosDeviceInfo _iosInfo;
String _deviceLanguage;
Map<String, dynamic> _backupQuestionSpecJson;

class AppConfig {
  static const APP_MODE = _appMode;

  static bool isDevelopment() => _appMode == "dev";
  static bool isBeta() => _appMode == "beta";
  static bool isProduction() => _appMode == "production";

  static String get bootnodesUrl =>
      _bootnodesUrlOverride ?? _GATEWAY_BOOTNODES_URL;

  static String get networkId => _networkOverride ?? NETWORK_ID;

  static String get ensDomainSuffix {
    if (_ensDomainSuffixOverride is String) return _ensDomainSuffixOverride;
    if (_appMode == "dev") return DEVELOPMENT_ENS_DOMAIN_SUFFIX;
    if (_appMode == "beta") return STAGING_ENS_DOMAIN_SUFFIX;
    return PRODUCTION_ENS_DOMAIN_SUFFIX;
  }

  // CONFIG VARS
  static const _GATEWAY_BOOTNODES_URL = String.fromEnvironment(
    "GATEWAY_BOOTNODES_URL",
    defaultValue: _appMode == "dev"
        ? "https://bootnodes.vocdoni.net/gateways.dev.json"
        : "https://bootnodes.vocdoni.net/gateways.json",
  );

  static const NETWORK_ID = String.fromEnvironment(
    "NETWORK_ID",
    defaultValue: _appMode == "dev" ? "goerli" : "xdai",
  );

  static const LINKING_DOMAIN = String.fromEnvironment(
    "LINKING_DOMAIN",
    defaultValue: _appMode == "dev" ? "dev.vocdoni.link" : "vocdoni.link",
  );

  static String get linkingDomain {
    if (bootnodesUrl.contains("dev")) return "dev.vocdoni.link";
    if (bootnodesUrl.contains("stg")) return "stg.vocdoni.link";
    return "vocdoni.link";
  }

  static String get vochainExplorerUrl {
    if (bootnodesUrl.contains("dev")) return "https://explorer.dev.vocdoni.net";
    if (bootnodesUrl.contains("stg")) return "https://explorer-stg.vocdoni.net";
    return "https://explorer.vocdoni.net";
  }

  static PackageInfo get packageInfo => _packageInfo;

  /// NOT used in app locale or language settings
  static String get defaultDeviceLanguage => _deviceLanguage;

  static String osVersion() {
    if (_androidInfo != null) return "Android " + _androidInfo.version.baseOS;
    if (_iosInfo != null) return "iOS " + _iosInfo.systemVersion;
    return "";
  }

  static Map<String, String> get backupQuestionTexts {
    if (_backupQuestionSpecJson.length == 0) return {};
    if (_backupQuestionSpecJson["versions"] is! Map ||
        _backupQuestionSpecJson["versions"].length == 0) return {};
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION] is! Map ||
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION].length == 0)
      return {};
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["questions"]
            is! Map ||
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["questions"]
                .length ==
            0) return {};
    Map<String, dynamic> questions =
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["questions"];
    return questions.cast<String, String>();
  }

  static Map<String, String> get backupAuthOptions {
    if (_backupQuestionSpecJson.length == 0) return {};
    if (_backupQuestionSpecJson["versions"] is! Map ||
        _backupQuestionSpecJson["versions"].length == 0) return {};
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION] is! Map ||
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION].length == 0)
      return {};
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["auth"]
            is! Map ||
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["auth"]
                .length ==
            0) return {};
    Map<String, dynamic> auth =
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["auth"];
    return auth.cast<String, String>();
  }

  static String get backupLinkFormat {
    if (_backupQuestionSpecJson.length == 0) return "";
    if (_backupQuestionSpecJson["versions"] is! Map ||
        _backupQuestionSpecJson["versions"].length == 0) return "";
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION] is! Map ||
        _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION].length == 0)
      return "";
    if (_backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]["linkFormat"]
        is! String) return "";
    return _backupQuestionSpecJson["versions"][BACKUP_LINK_VERSION]
        ["linkFormat"];
  }

  // STATIC SETTERS TO INITIALIZE RUNTIME CONFIGS

  static setBootnodesUrlOverride(String url) async {
    try {
      _bootnodesUrlOverride = url;
    } catch (err) {
      throw err;
    }
  }

  static setNetworkOverride(String network) async {
    try {
      _networkOverride = network;
    } catch (err) {
      throw err;
    }
  }

  static setEnsDomainSuffixOverride(String suffix) async {
    try {
      _ensDomainSuffixOverride = suffix;
    } catch (err) {
      throw err;
    }
  }

  static init() async {
    _setPackageInfo();
    _setDeviceInfo();
    _setDefaultDeviceLanguage();
    _setBackupQuestionSpecJson();
  }

  static _setPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (err) {
      logger.log(err);
    }
  }

  static _setDeviceInfo() async {
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

  /// NOT used in app locale or language settings
  static _setDefaultDeviceLanguage() async {
    try {
      _deviceLanguage = (await Devicelocale.preferredLanguages)[0];
    } catch (err) {
      _deviceLanguage = "";
      logger.log(err);
    }
  }

  static _setBackupQuestionSpecJson() async {
    try {
      final jsonDefaultStrings = await rootBundle
          .loadString('lib/common-client-libs/backup/questions.spec.json');
      _backupQuestionSpecJson = json.decode(jsonDefaultStrings);
    } catch (err) {
      logger.log("ERROR could not parse backup question spec: $err");
    }
  }
}
