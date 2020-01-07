import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocdoni/constants/storage-names.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/constants/settings.dart';

final String _storageFileBootNodes = BOOTNODES_STORE_FILE;

/// AppStateModel handles the global state of the application.
/// 
/// IMPORTANT: All **updates** on the state must call `notifyListeners()`
///
class AppStateModel extends StateModel<AppState> {
  @override
  setValue(AppState newValue) {
    if (!(newValue.selectedAccount is int) ||
        newValue.selectedAccount < 0 ||
        newValue.selectedAccount > globalAccountPool.value.length) {
      throw Exception("Invalid account index");
    } else if (!(newValue.bootnodes is StateModel) ||
        !newValue.bootnodes.hasValue) {
      throw Exception("Invalid bootnode list");
    }

    super.setValue(newValue);
  }

  // INTERNAL DATA HANDLERS

  AccountModel getSelectedAccount(int accountIdx) {
    if (!hasValue)
      throw Exception("The app has no state yet");
    else if (!globalAccountPool.hasValue)
      return null;
    else if (globalAccountPool.value.length <= accountIdx || accountIdx < 0)
      throw Exception("Index out of bounds");

    return globalAccountPool.value[accountIdx];
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
    // Gateway boot nodes
    try {
      BootNodeGateways gwList;

      final storageDir = await getApplicationDocumentsDirectory();
      final fd = File("${storageDir.path}/$_storageFileBootNodes");

      this.value.bootnodes.setToLoading();
      if (await fd.exists()) {
        final bytes = await fd.readAsBytes();
        gwList = BootNodeGateways.fromBuffer(bytes);
      } else {
        gwList = BootNodeGateways();
      }

      this.value.bootnodes.setValue(gwList);
      notifyListeners();
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
    try {
      // Gateway boot nodes
      final storageDir = await getApplicationDocumentsDirectory();
      final fd = File("${storageDir.path}/$_storageFileBootNodes");

      await fd.writeAsBytes(value.bootnodes.value.writeToBuffer());
    } catch (err) {
      print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  /// Fetch the list of bootnodes and store it locally
  @override
  Future<void> refresh() async {
    try {
      this.value.bootnodes.setToLoading();

      final gwList = await getDefaultGatewaysInfo(NETWORK_ID);

      this.value.bootnodes.setValue(gwList);

      await writeToStorage();
      notifyListeners();

      return globalVochain.refresh();
    } catch (err) {
      if (!kReleaseMode) print("ERR: $err");
      this.value.bootnodes.setError("Cannot fetch the boot nodes list",
          keepPreviousValue: true);
      throw err;
    }
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class AppState {
  /// Index of the currently active identity
  int selectedAccount;

  /// All Gateways known to us, regardless of the entity.
  /// This value can't be directly set. Use `setValue` instead.
  final StateModel<BootNodeGateways> bootnodes;

  AppState(this.selectedAccount, this.bootnodes);
}
