import 'package:dvote/dvote.dart';
import 'package:dvote_common/flavors/config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/util.dart';

/// AppStateModel handles the global state of the application.
///
/// Updates on the children models will be notified by the objects themselves.
///
class AppStateModel implements ModelPersistable, ModelRefreshable {
  /// Index of the currently active identity
  final EventualNotifier<int> selectedAccount = EventualNotifier<int>(-1);

  /// All Gateways known to us, regardless of the entity.
  /// This value can't be directly set. Use `setValue` instead.
  final EventualNotifier<BootNodeGateways> bootnodes =
      EventualNotifier<BootNodeGateways>()
          .withFreshnessTimeout(Duration(minutes: 2));

  final EventualNotifier<int> averageBlockTime =
      EventualNotifier<int>(5); // 5 seconds by default
  final EventualNotifier<int> referenceBlock =
      EventualNotifier<int>().withFreshnessTimeout(Duration(seconds: 20));
  final EventualNotifier<DateTime> referenceBlockTimestamp =
      EventualNotifier<DateTime>().withFreshnessTimeout(Duration(seconds: 20));

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
      this.bootnodes.setToLoading();
      final gwList = globalBootnodesPersistence.get();
      this.bootnodes.setValue(gwList);
    } catch (err) {
      devPrint(err);
      this
          .bootnodes
          .setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the current bootnodes data to the persistent storage
  @override
  Future<void> writeToStorage() async {
    try {
      // Gateway boot nodes
      if (this.bootnodes.hasValue)
        await globalBootnodesPersistence.write(this.bootnodes.value);
      else
        await globalBootnodesPersistence
            .write(BootNodeGateways()); // empty data
    } catch (err) {
      devPrint(err);
      throw PersistError("Cannot store the current state");
    }
  }

  /// Fetch the list of bootnodes and store it locally
  @override
  Future<void> refresh([bool force = false]) async {
    try {
      // Refresh bootnodes
      await this.refreshBootNodes(force);

      // Refresh vochain state
      await this.refreshBlockInfo(force);

      await this.writeToStorage();
    } catch (err) {
      devPrint("ERR: $err");
      throw err;
    }
  }

  Future<void> refreshBootNodes([bool force = false]) async {
    if (!force && this.bootnodes.isFresh)
      return;
    else if (!force && this.bootnodes.isLoading) return;

    this.bootnodes.setToLoading();
    try {
      if (FlavorConfig.isProduction()) {
        // Get the bootnodes URL from the blockchain
        final gwList = await getDefaultGatewaysDetails(
            FlavorConfig.instance.constants.networkId);
        this.bootnodes.setValue(gwList);
      } else {
        // Use the parameterized URL
        devPrint(
            "Checking " + FlavorConfig.instance.constants.gatewayBootNodesUrl);
        final gwList = await getGatewaysDetailsFromBootNode(
            FlavorConfig.instance.constants.gatewayBootNodesUrl);
        this.bootnodes.setValue(gwList);
      }
    } catch (err) {
      this.bootnodes.setError("Cannot fetch the boot nodes list",
          keepPreviousValue: true);
      throw err;
    }
  }

  Future<void> refreshBlockInfo([bool force = false]) async {
    if (!force && this.referenceBlock.isFresh)
      return;
    else if (!force && this.referenceBlock.isLoading) return;

    this.referenceBlock.setToLoading();

    try {
      final dvoteGw = await getDVoteGateway();
      if (dvoteGw == null) throw Exception();
      final newReferenceblock = await getBlockHeight(dvoteGw);

      if (newReferenceblock == null) {
        this.referenceBlock.setError("Unable to retrieve reference block");
        this
            .referenceBlockTimestamp
            .setError("Unable to retrieve reference block");
      } else {
        this.referenceBlock.setValue(newReferenceblock);
        this.referenceBlockTimestamp.setValue(DateTime.now());
      }
    } catch (err) {
      this.referenceBlock.setError("Network error");
      this.referenceBlockTimestamp.setError("Network error");
      devPrint(err);
      throw err;
    }
  }
  // CUSTOM METHODS

  /// Returns a duration if the block times are defined or `null` otherwise
  DateTime getDateTimeAtBlock(int blockNumber) {
    if (!this.referenceBlock.hasValue || !this.referenceBlockTimestamp.hasValue)
      return null;

    final blockDiff = blockNumber - this.referenceBlock.value;
    final durationDiff = getDurationForBlocks(blockDiff);

    return DateTime.now().add(durationDiff);
  }

  /// Returns a duration if the block times are defined or `null` otherwise
  Duration getDurationForBlocks(int blockCount) {
    // TODO: fetch average block time from the GW at some point
    if (!this.referenceBlock.hasValue) return null;

    return new Duration(seconds: this.averageBlockTime.value * blockCount);
  }

  get currentLanguage => "default";

  AccountModel get currentAccount {
    if (!globalAccountPool.hasValue)
      return null;
    else if (globalAccountPool.value.length <= selectedAccount.value ||
        selectedAccount.value < 0) return null;

    return globalAccountPool.value[selectedAccount.value];
  }
}
