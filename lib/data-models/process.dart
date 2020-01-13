import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// ProcessPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateValue or StateModel.
///
class ProcessPoolModel extends StateModel<List<ProcessModel>>
    implements StatePersistable, StateRefreshable {
  ProcessPoolModel() {
    this.load(List<ProcessModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.load(List<ProcessModel>());

    try {
      this.setToLoading();
      final processList = globalProcessesPersistence.get();
      final processModelList = processList
          .where((processMeta) =>
              processMeta.meta[META_PROCESS_ID] is String &&
              processMeta.meta[META_ENTITY_ID] is String)
          .map((processMeta) => ProcessModel.fromMetadata(
              processMeta,
              processMeta.meta[META_PROCESS_ID],
              processMeta.meta[META_ENTITY_ID]))
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
    if (!hasValue) this.load(List<ProcessModel>());

    try {
      final processList = this
          .value
          .where((processModel) =>
              processModel is ProcessModel && processModel.metadata.hasValue)
          .map((processModel) => processModel.metadata)
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
          if (!(process is ProcessModel) || !process.metadata.hasValue)
            return false;

          return process.metadata.value.meta[META_ENTITY_ID] == entityId;
        })
        .cast<ProcessModel>()
        .toList();
  }
}

/// ProcessModel encapsulates the relevant information of a Vocdoni Process.
/// This includes its metadata and the participation processes.
///
class ProcessModel implements StateRefreshable {
  final String processId;
  final String entityId;
  final StateModel<ProcessMetadata> metadata = StateModel<ProcessMetadata>();
  final StateModel<bool> isInCensus = StateModel<bool>();
  final StateModel<bool> hasVoted = StateModel<bool>();
  final StateModel<int> currentParticipants = StateModel<int>();

  List<dynamic> choices = [];

  ProcessModel(this.processId, this.entityId,
      [ProcessMetadata metadata,
      bool isInCensus,
      bool hasVoted,
      int currentParticipants]) {
    if (metadata is ProcessMetadata) this.metadata.load(metadata);
    if (isInCensus is bool) this.isInCensus.load(isInCensus);
    if (hasVoted is bool) this.hasVoted.load(hasVoted);
    if (currentParticipants is int)
      this.currentParticipants.load(currentParticipants);
  }

  ProcessModel.fromMetadata(
      ProcessMetadata metadata, this.processId, this.entityId) {
    metadata.meta[META_PROCESS_ID] =
        this.processId; // Ensure we can read it back
    metadata.meta[META_ENTITY_ID] = this.entityId;

    this.metadata.load(metadata);

    switch (this.metadata.value.meta[META_PROCESS_CENSUS_BELONGS]) {
      case "true":
        this.isInCensus.load(true);
        break;
      case "false":
        this.isInCensus.load(false);
        break;
    }
  }

  @override
  Future<void> refresh() {
    return Future.wait([
      refreshMetadata(),
      refreshCensusState(),
    ]);
  }

  Future<void> refreshMetadata() async {
    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same

    try {
      final DVoteGateway dvoteGw = getDVoteGateway();
      final Web3Gateway web3Gw = getWeb3Gateway();

      this.metadata.setToLoading();
      final newMetadata =
          await getProcessMetadata(this.processId, dvoteGw, web3Gw);
      newMetadata.meta[META_PROCESS_ID] =
          this.processId; // Ensure we can read it back
      newMetadata.meta[META_ENTITY_ID] = this.entityId;

      this.metadata.setValue(newMetadata);
    } catch (err) {
      this.metadata.setError("Unable to fetch the process details");
    }
  }

  Future<void> refreshCensusState() async {
    final DVoteGateway dvoteGw = getDVoteGateway();

    this.isInCensus.setToLoading();

    final currentAccount = globalAppState.getSelectedAccount();
    if (!(currentAccount is AccountModel)) return;

    try {
      final base64Claim =
          await digestHexClaim(currentAccount.identity.value.keys[0].publicKey);

      final proof = await generateProof(
          this.metadata.value.census.merkleRoot, base64Claim, dvoteGw);
      if (!(proof is String) || !proof.startsWith("0x")) {
        this.isInCensus.setError("You are not part of the census");
        return;
      }

      final emptyProofRegexp =
          RegExp(r"^0x[0]+$", caseSensitive: false, multiLine: false);

      if (emptyProofRegexp.hasMatch(proof)) {
        this.isInCensus.setValue(false); // 0x0000000000.....
        return;
      }
      this.isInCensus.setValue(true);

      final valid = await checkProof(
          this.metadata.value.census.merkleRoot, base64Claim, proof, dvoteGw);

      this.isInCensus.setValue(valid);
    } catch (error) {
      this.isInCensus.setError("Unable to check the census");
    }
  }
}
