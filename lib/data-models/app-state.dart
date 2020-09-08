import 'package:dvote/dvote.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/data-models/account.dart';
import "dart:developer";

/// AppStateModel handles the global state of the application.
///
/// Updates on the children models will be notified by the objects themselves.
///
class AppStateModel implements ModelPersistable, ModelRefreshable {
  /// Index of the currently active identity
  final selectedAccount = EventualNotifier<int>(-1);

  /// All Gateways known to us, regardless of the entity.
  /// This value can't be directly set. Use `setValue` instead.
  final bootnodeInfo = EventualNotifier<BootNodeGateways>()
      .withFreshnessTimeout(Duration(minutes: 2));

  // INTERNAL DATA HANDLERS

  selectAccount(int accountIdx) {
    if (!globalAccountPool.hasValue || globalAccountPool.value.length == 0)
      throw Exception("No account is ready to be used");
    else if (accountIdx == selectedAccount.value) return;

    if (!(accountIdx is int) ||
        accountIdx < 0 ||
        accountIdx >= globalAccountPool.value.length) {
      throw Exception("Index out of bounds");
    }
    this.selectedAccount.setValue(accountIdx);
  }

  // EXTERNAL DATA HANDLERS

  /// Read the list of bootnodes from the persistent storage
  @override
  Future<void> readFromStorage() async {
    // Gateway boot nodes
    try {
      this.bootnodeInfo.setToLoading();
      final gwList = globalBootnodesPersistence.get();
      this.bootnodeInfo.setValue(gwList);
    } catch (err) {
      log(err);
      this
          .bootnodeInfo
          .setError("Cannot read the app state", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the current bootnodes data to the persistent storage
  @override
  Future<void> writeToStorage() async {
    try {
      // Gateway boot nodes
      if (this.bootnodeInfo.hasValue)
        await globalBootnodesPersistence.write(this.bootnodeInfo.value);
      else
        await globalBootnodesPersistence
            .write(BootNodeGateways()); // empty data
    } catch (err) {
      log(err);
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
      log("ERR: $err");
      throw err;
    }
  }

  Future<void> refreshBootNodes([bool force = false]) async {
    if (!force && this.bootnodeInfo.isFresh)
      return;
    else if (!force && this.bootnodeInfo.isLoading) return;

    this.bootnodeInfo.setToLoading();
    try {
      log("[App] Fetching " + AppConfig.GATEWAY_BOOTNODES_URL);
      final bnGatewayInfo =
          await fetchBootnodeInfo(AppConfig.GATEWAY_BOOTNODES_URL);

      log("[App] Gateway discovery");
      final gateways = await discoverGatewaysFromBootnodeInfo(bnGatewayInfo,
          networkId: AppConfig.NETWORK_ID);

      log("[App] Gateway Pool ready");
      AppNetworking.setGateways(gateways, AppConfig.NETWORK_ID);

      this.bootnodeInfo.setValue(bnGatewayInfo);
    } catch (err) {
      this.bootnodeInfo.setError("Cannot fetch the boot nodes list",
          keepPreviousValue: true);
      throw err;
    }
  }

  // CUSTOM METHODS

  get currentLanguage => "default";

  AccountModel get currentAccount {
    if (!globalAccountPool.hasValue)
      return null;
    else if (globalAccountPool.value.length <= selectedAccount.value ||
        selectedAccount.value < 0) return null;

    return globalAccountPool.value[selectedAccount.value];
  }
}
