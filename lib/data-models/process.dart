import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/state-value.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// ProcessPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateValue or StateModel.
///
class ProcessPoolModel extends StateModel<List<ProcessModel>> {
  ProcessPoolModel() {
    this.setValue(List<ProcessModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(List<ProcessModel>());

    try {
      this.setToLoading();
      final processList = globalProcessesPersistence.get();
      final processModelList = processList
          .map((feed) => ProcessModel.fromMetadata(feed))
          .cast<ProcessModel>()
          .toList();
      this.setValue(processModelList);
    } catch (err) {
      print(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.setValue(List<ProcessModel>());

    try {
      final processList = this
          .value
          .where((processModel) => processModel.hasValue)
          .map((processModel) => processModel.value.metadata)
          .cast<ProcessMetadata>()
          .toList();
      await globalProcessesPersistence.writeAll(processList);
    } catch (err) {
      print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh() async {
    if (!hasValue) return;

    try {
      // TODO: Get a filtered ProcessModel list of the Entities of the current user

      // This will call `setValue` on the individual models already within the pool.
      // No need to rebuild an updated pool list.
      await Future.wait(
          this.value.map((processModel) => processModel.refresh()).toList());

      await this.writeToStorage();
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw err;
    }
  }

  // HELPERS

  /// Returns the voting processes from the given entity
  List<ProcessModel> getFromEntityId(String entityId) {
    if (!this.hasValue) return [];

    return this
        .value
        .where((process) {
          if (!process.hasValue || !process.value.metadata.hasValue)
            return false;

          return process.value.metadata.value.meta[META_ENTITY_ID] == entityId;
        })
        .cast<ProcessModel>()
        .toList();
  }
}

/// ProcessModel encapsulates the relevant information of a Vocdoni Process.
/// This includes its metadata and the participation processes.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateValue or StateModel.
///
class ProcessModel extends StateModel<ProcessState> {
  ProcessModel(String processId, String entityId) {
    final newValue = ProcessState(processId, entityId);
    this.setValue(newValue);
  }

  ProcessModel.fromMetadata(ProcessMetadata processMeta) {
    if (!(processMeta.meta[META_PROCESS_ID] is String))
      throw Exception(
          "The given metadata needs to contain the process ID on meta['processId']");
    else if (!(processMeta.meta[META_ENTITY_ID] is String))
      throw Exception(
          "The given metadata needs to contain the entity ID on meta['entityId']");

    final newValue = ProcessState(
        processMeta.meta[META_PROCESS_ID], processMeta.meta[META_ENTITY_ID]);
    newValue.metadata.setValue(processMeta);
    newValue.isInCensus.setValue(false);

    switch (this.value.metadata.value.meta[META_PROCESS_CENSUS_BELONGS]) {
      case "true":
        this.value.isInCensus.setValue(true);
        break;
      case "false":
        this.value.isInCensus.setValue(false);
        break;
    }
    this.setValue(newValue);
  }

  @override
  Future<void> refresh() {
    this.setToLoading();
    return Future.wait([
      refreshMetadata(),
      refreshCensusState(),
    ]);
  }

  Future<void> refreshMetadata() async {
    if (!this.hasValue)
      throw Exception("Cannot refresh while since no value is loaded");

    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same

    try {
      final DVoteGateway dvoteGw = getDVoteGateway();
      final Web3Gateway web3Gw = getWeb3Gateway();

      this.value.metadata.setToLoading();
      final newMetadata =
          await getProcessMetadata(value.processId, dvoteGw, web3Gw);
      newMetadata.meta[META_PROCESS_ID] = value.processId;
      newMetadata.meta[META_ENTITY_ID] = value.entityId;

      this.value.metadata.setValue(newMetadata);
    } catch (err) {
      this.setError("Unable to fetch the process details");
    }
  }

  Future<void> refreshCensusState() async {
    if (!this.hasValue)
      throw Exception("Cannot refresh while since no value is loaded");

    final DVoteGateway dvoteGw = getDVoteGateway();

    value.isInCensus.setToLoading();

    final currentAccount = globalAppState.getSelectedAccount();
    if (!currentAccount.hasValue) return;

    final base64Claim =
        await digestHexClaim(currentAccount.value.identity.keys[0].publicKey);

    try {
      final proof = await generateProof(
          this.value.metadata.value.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        value.isInCensus.setError("You are not part of the census");
        return;
      }

      final emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) {
        value.isInCensus.setValue(false); // 0x0000000000.....
        return;
      }
      value.isInCensus.setValue(true);

      final valid = await checkProof(
          this.value.metadata.value.census.merkleRoot,
          base64Claim,
          proof,
          dvoteGw);

      this.value.isInCensus.setValue(valid);
    } catch (error) {
      value.isInCensus.setError("Unable to check the census");
    }
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class ProcessState {
  final String processId;
  final String entityId;
  final StateValue<ProcessMetadata> metadata = StateValue<ProcessMetadata>();
  final StateValue<bool> isInCensus = StateValue<bool>();
  final StateValue<bool> hasVoted = StateValue<bool>();
  final StateValue<int> currentParticipants = StateValue<int>();

  List<dynamic> choices = [];

  ProcessState(this.processId, this.entityId);
}
