import 'package:flutter/foundation.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/state-value.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/constants/settings.dart';

/// AppStateModel handles the global state of the application.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class AppStateModel extends StateModel<AppState> {
  AppStateModel() {
    this.setValue(AppState());
  }

  @override
  setValue(AppState newValue) {
    if (globalAccountPool.hasValue && globalAccountPool.value.length > 0) {
      if (!(newValue.selectedAccount is int) ||
          newValue.selectedAccount < 0 ||
          newValue.selectedAccount > globalAccountPool.value.length) {
        throw Exception("Invalid account index");
      }
    } else if (!(newValue.bootnodes is StateModel) ||
        !newValue.bootnodes.hasValue) {
      throw Exception("Invalid bootnode list");
    }

    super.setValue(newValue);
    // notifyListeners();  // Not needed => setValue will do it
  }

  // INTERNAL DATA HANDLERS

  AccountModel getSelectedAccount() {
    if (!hasValue)
      throw Exception("The app has no state yet");
    else if (!globalAccountPool.hasValue)
      return null;
    else if (globalAccountPool.value.length <= value.selectedAccount ||
        value.selectedAccount < 0) return null;

    return globalAccountPool.value[value.selectedAccount];
  }

  selectAccount(int accountIdx) {
    if (accountIdx >= globalAccountPool.value.length || accountIdx < 0)
      throw Exception("Index out of bounds");
    else if (accountIdx == value.selectedAccount) return;

    value.selectedAccount = accountIdx;
    notifyListeners();
  }

  // EXTERNAL DATA HANDLERS

  /// Read the list of bootnodes from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(AppState());

    // Gateway boot nodes
    try {
      this.value.bootnodes.setToLoading();
      final gwList = await globalBootnodesPersistence.read();
      this.value.bootnodes.setValue(gwList);
      // notifyListeners(); // Not needed => UI doesn't depend on bootnodes
    } catch (err) {
      print(err);
      this
          .value
          .bootnodes
          .setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the current bootnodes data to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.setValue(AppState());

    try {
      // Gateway boot nodes
      if (value.bootnodes.hasValue)
        await globalBootnodesPersistence.write(value.bootnodes.value);
      else
        await globalBootnodesPersistence
            .write(BootNodeGateways()); // empty data
    } catch (err) {
      print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  /// Fetch the list of bootnodes and store it locally
  @override
  Future<void> refresh() async {
    if (!hasValue) this.setValue(AppState());

    // TODO: Check the last time that data was fetched

    try {
      // Refresh bootnodes
      await this._fetchBootnodes();
      await writeToStorage();

      // Refresh vochain state
      return this._fetchCurrentBlockInfo();
    } catch (err) {
      if (!kReleaseMode) print("ERR: $err");
      throw err;
    }
  }

  // CUSTOM METHODS

  Duration getDurationUntilBlock(int blockNumber) {
    if (!hasValue ||
        !value.referenceBlock.hasValue ||
        !value.referenceBlockTimestamp.hasValue) return null;
    int blocksLeftFromReference = blockNumber - value.referenceBlock.value;
    Duration referenceToBlock = getDurationForBlocks(blocksLeftFromReference);
    Duration nowToReference =
        DateTime.now().difference(value.referenceBlockTimestamp.value);
    return nowToReference - referenceToBlock;
  }

  Duration getDurationForBlocks(int blockCount) {
    //TODO fetch average block time
    return new Duration(seconds: value.averageBlockTime * blockCount);
  }

  Future<void> _fetchBootnodes() async {
    try {
      this.value.bootnodes.setToLoading();
      final gwList = await getDefaultGatewaysInfo(NETWORK_ID);
      this.value.bootnodes.setValue(gwList);
      // notifyListeners(); // Not needed => UI doesn't depend on bootnodes
    } catch (err) {
      this.value.bootnodes.setError("Cannot fetch the boot nodes list",
          keepPreviousValue: true);
      throw err;
    }
  }

  Future<void> _fetchCurrentBlockInfo() async {
    value.referenceBlock.setToLoading();

    try {
      final DVoteGateway dvoteGw = getDVoteGateway();
      final newReferenceblock = await getBlockHeight(dvoteGw);

      if (newReferenceblock == null) {
        value.referenceBlock.setError("Unable to retrieve reference block");
        value.referenceBlockTimestamp
            .setError("Unable to retrieve reference block");
      } else {
        value.referenceBlock.setValue(newReferenceblock);
        value.referenceBlockTimestamp.setValue(DateTime.now());
      }
      // notifyListeners(); // Not needed => UI doesn't depend on referenceBlock
    } catch (err) {
      value.referenceBlock.setError("Network error");
      value.referenceBlockTimestamp.setError("Network error");
      print(err);
      throw err;
    }
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class AppState {
  /// Index of the currently active identity
  int selectedAccount = -1;

  /// All Gateways known to us, regardless of the entity.
  /// This value can't be directly set. Use `setValue` instead.
  final StateValue<BootNodeGateways> bootnodes = StateValue<BootNodeGateways>();

  final int averageBlockTime = 5; // seconds
  final StateValue<int> referenceBlock = StateValue<int>();
  final StateValue<DateTime> referenceBlockTimestamp = StateValue<DateTime>();
}
