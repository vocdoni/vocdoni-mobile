import 'dart:ui';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/data-models/account.dart';

/// AppStateModel handles the global state of the application.
///
/// Updates on the children models will be notified by the objects themselves.
///
class AppStateModel implements ModelPersistable, ModelRefreshable {
  /// Index of the currently active identity
  final selectedAccount = EventualNotifier<int>(-1);
  final locale = EventualNotifier<Locale>();
  final blockStatus =
      EventualValue<BlockStatus>().withFreshnessTimeout(Duration(seconds: 30));

  /// All Gateways known to us, regardless of the entity.
  /// This value can't be directly set. Use `setValue` instead.
  final bootnodeInfo = EventualNotifier<BootNodeGateways>()
      .withFreshnessTimeout(Duration(minutes: 2));
  String analyticsKey = "";

  // INTERNAL DATA HANDLERS

  selectAccount(int accountIdx) {
    if (!Globals.accountPool.hasValue || Globals.accountPool.value.length == 0)
      throw Exception("No account is ready to be used");
    else if (accountIdx == selectedAccount.value) return;

    if (!(accountIdx is int) ||
        accountIdx < 0 ||
        accountIdx >= Globals.accountPool.value.length) {
      throw Exception("Index out of bounds");
    }
    this.selectedAccount.setValue(accountIdx);
    if (this.currentAccount is! AccountModel)
      throw Exception("No account available");

    Globals.appState.currentAccount.cleanEphemeral();
    Globals.appState.currentAccount.refresh(force: false);

    // if no analytics ID (new account or account from old app version) set analytics ID and write to storage
    if (Globals.appState.currentAccount.identity.value.analyticsID == null ||
        Globals.appState.currentAccount.identity.value.analyticsID == "") {
      if ((Globals.accountPool.hasValue &&
              Globals.accountPool.value.length > 1) ||
          Globals.appState.analyticsKey.length == 0) {
        // If there are already accounts, or the default analytics key is not set, generate a new key for this user
        Globals.appState.currentAccount.identity.value.analyticsID =
            generateAnalyticsKey();
        print(
            "Generated key ${Globals.appState.currentAccount.identity.value.analyticsID}");
      } else {
        Globals.appState.currentAccount.identity.value.analyticsID =
            Globals.appState.analyticsKey;
        print(
            "Used existing key ${Globals.appState.currentAccount.identity.value.analyticsID}");
      }
      Globals.accountPool.writeToStorage();
    }
    Globals.analytics.setUser();
  }

  /// Defines the new locale to use for the app
  Future<void> selectLocale(Locale newLocale) {
    if (newLocale == locale.value)
      return Future.value();
    else if (!SUPPORTED_LANGUAGES.contains(newLocale.languageCode))
      return Future.error(Exception("Unsupported locale"));

    return AppLocalization.load(newLocale).then((_) {
      logger.log("[App] Switched to ${newLocale.languageCode}");
      locale.value = newLocale;

      return this.writeToStorage();
    }).catchError((err) {
      logger.log("[App] Could not change the locale: $err");
    });
  }

  // EXTERNAL DATA HANDLERS

  /// Read the list of bootnodes from the persistent storage
  @override
  Future<void> readFromStorage() async {
    // Gateway boot nodes
    try {
      this.bootnodeInfo.setToLoading();
      final gwList = Globals.bootnodesPersistence.get();
      this.bootnodeInfo.setValue(gwList);

      // Settings
      final settings = Globals.settingsPersistence.get();
      if (settings is Map && settings["locale"] is String) {
        if (SUPPORTED_LANGUAGES.contains(settings["locale"]))
          await selectLocale(Locale(settings["locale"]));
      }
      if (settings is Map && settings["bootnodeUrlOverride"] is String) {
        AppConfig.setBootnodesUrlOverride(settings["bootnodeUrlOverride"]);
      }
      if (settings is Map && settings["networkIdOverride"] is String) {
        AppConfig.setNetworkOverride(settings["networkIdOverride"]);
      }
      if (settings is Map && settings["analyticsKey"] is String) {
        this.analyticsKey = settings["analyticsKey"];
      }
    } catch (err) {
      logger.log(err);
      this
          .bootnodeInfo
          .setError("Cannot read the app state", keepPreviousValue: true);
      throw RestoreError(
          "There was an error while accessing the local data: $err");
    }
  }

  /// Write the current bootnodes data to the persistent storage
  @override
  Future<void> writeToStorage() async {
    try {
      // Gateway boot nodes
      if (this.bootnodeInfo.hasValue) {
        await Globals.bootnodesPersistence.write(this.bootnodeInfo.value);
      } else {
        await Globals.bootnodesPersistence
            .write(BootNodeGateways()); // empty data
      }

      // Settings
      final settings = {
        "locale": locale?.value?.languageCode ?? DEFAULT_LANGUAGE,
        "bootnodeUrlOverride": AppConfig.bootnodesUrl,
        "networkIdOverride": AppConfig.networkId,
        "analyticsKey": this.analyticsKey,
      };
      await Globals.settingsPersistence.write(settings);
    } catch (err) {
      logger.log("ERR storing app state: $err");
      throw PersistError("Cannot store the current state");
    }
  }

  /// Fetch the list of bootnodes and store it locally
  @override
  Future<void> refresh({bool force = false}) async {
    try {
      // Refresh bootnodes
      await this.refreshBootNodes(force);

      await this.writeToStorage();
    } catch (err) {
      logger.log("ERR: $err");
      throw Exception("Unable to update bootnodes: $err");
    }
  }

  Future<void> refreshBootNodes([bool force = false]) async {
    if (!force && this.bootnodeInfo.isFresh)
      return;
    else if (!force && this.bootnodeInfo.isLoading) return;

    this.bootnodeInfo.setToLoading();
    try {
      logger.log("[App] Fetching " + AppConfig.bootnodesUrl);
      final bnGatewayInfo = await fetchBootnodeInfo(AppConfig.bootnodesUrl);

      logger.log("[App] Gateway discovery");
      final gateways = await discoverGatewaysFromBootnodeInfo(bnGatewayInfo,
          networkId: AppConfig.networkId,
          alternateEnvironment: AppConfig.alternateEnvironment);

      logger.log("[App] Gateway Pool ready");
      AppNetworking.setGateways(gateways, AppConfig.networkId);

      this.bootnodeInfo.setValue(bnGatewayInfo);
    } catch (err) {
      this.bootnodeInfo.setError("Cannot fetch the boot nodes list",
          keepPreviousValue: true);
      throw err;
    }
  }

  Future<void> refreshBlockStatus([bool force = false]) async {
    if (!force && this.blockStatus.isFresh)
      return;
    else if (!force && this.blockStatus.isLoading) return;

    this.blockStatus.setToLoading();
    try {
      logger.log("[App] Fetching block status");
      final status = await getBlockStatus(AppNetworking.pool);

      this.blockStatus.setValue(status);
    } catch (err) {
      this
          .blockStatus
          .setError("Cannot fetch the block status", keepPreviousValue: true);
      throw err;
    }
  }

  // CUSTOM METHODS

  /// Used to determine the language to read the content from.
  /// Currently, everything is using "default".
  get currentLanguage => "default";
  get materialLocale {
    switch (locale.value?.languageCode ?? "") {
      case "":
        return null;
      case "eo":
        return Locale("eo");
      default:
        return locale.value;
    }
  }

  AccountModel get currentAccount {
    if (!Globals.accountPool.hasValue)
      return null;
    else if (Globals.accountPool.value.length <= selectedAccount.value ||
        selectedAccount.value < 0) return null;

    return Globals.accountPool.value[selectedAccount.value];
  }
}
