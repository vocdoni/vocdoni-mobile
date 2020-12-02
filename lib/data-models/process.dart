import 'dart:convert';
import 'package:dvote/dvote.dart';
// import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:dvote/wrappers/process-results.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:convert/convert.dart';
import "dart:developer";
import 'package:web3dart/crypto.dart';
import 'package:web3dart/credentials.dart';

final hexRegexp =
    RegExp(r"^0?x?[0-9a-f]+$", caseSensitive: false, multiLine: false);

/// This class should be used exclusively as a global singleton.
/// ProcessPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateContainer or EventualNotifier.
///
class ProcessPoolModel extends EventualNotifier<List<ProcessModel>>
    implements ModelPersistable, ModelRefreshable, ModelCleanable {
  ProcessPoolModel() {
    this.setDefaultValue(List<ProcessModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(List<ProcessModel>());

    try {
      this.setToLoading();
      final processList = Globals.processesPersistence.get();
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
      log(err);
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
          .where((processModel) =>
              processModel is ProcessModel && processModel.metadata.hasValue)
          .map((processModel) {
            // COPY STATE FIELDS INTO META
            processModel.metadata.value.meta[META_PROCESS_ID] =
                processModel.processId;
            processModel.metadata.value.meta[META_ENTITY_ID] =
                processModel.entityId;

            if (processModel.isInCensus.hasValue)
              processModel.metadata.value.meta[META_PROCESS_CENSUS_BELONGS] =
                  processModel.isInCensus.value ? "true" : "false";

            if (processModel.hasVoted.hasValue)
              processModel.metadata.value.meta[META_PROCESS_HAS_VOTED] =
                  processModel.hasVoted.value ? "true" : "false";

            if (processModel.censusSize.hasValue)
              processModel.metadata.value.meta[META_PROCESS_CENSUS_SIZE] =
                  processModel.censusSize.value.toString();

            return processModel.metadata.value;
          })
          .cast<ProcessMetadata>()
          .toList();
      await Globals.processesPersistence.writeAll(processList);
    } catch (err) {
      log(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh({bool force = false}) async {
    if (!hasValue ||
        Globals.appState.currentAccount == null ||
        !Globals.appState.currentAccount.entities.hasValue) return;

    log("Refreshing related user's processes");

    try {
      // Get a filtered list of the Entities of the current user
      final entityIds = Globals.appState.currentAccount.entities.value
          .map((entity) => entity.reference.entityId)
          .toList();

      // This will call `setValue` on the individual models that are already within the pool.
      // No need to update the pool list itself.
      final updatableProcs = this
          .value
          .where((processModel) => entityIds.contains(processModel.entityId))
          .toList();
      for (final procModel in updatableProcs) {
        await procModel.refresh(force: force);
      }

      await this.writeToStorage();
    } catch (err) {
      log(err);
    }
  }

  /// Cleans the ephemeral state of all processes
  @override
  void cleanEphemeral() {
    this.value.forEach((process) => process.cleanEphemeral());
  }

  /// Removes the given feed from the pool and persists the new pool.
  Future<void> remove(List<ProcessModel> processModelsToRemove) async {
    if (!this.hasValue) throw Exception("The pool has no value yet");

    final updatedValue = this
        .value
        .where((poolProcess) {
          for (var rmModel in processModelsToRemove) {
            if (poolProcess.processId == rmModel.processId)
              return false; // get it out
          }

          return true; // keep it
        })
        .cast<ProcessModel>()
        .toList();
    this.setValue(updatedValue);

    await this.writeToStorage();
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
class ProcessModel implements ModelRefreshable, ModelCleanable {
  final String processId;
  final String entityId;
  final String lang = "default";

  final metadata = EventualNotifier<ProcessMetadata>();
  final results = EventualNotifier<ProcessResultsDigested>()
      .withFreshnessTimeout(Duration(seconds: 10));
  final isInCensus =
      EventualNotifier<bool>().withFreshnessTimeout(Duration(minutes: 5));
  final hasVoted =
      EventualNotifier<bool>().withFreshnessTimeout(Duration(minutes: 5));
  final currentParticipants =
      EventualNotifier<int>().withFreshnessTimeout(Duration(minutes: 5));
  final censusSize =
      EventualNotifier<int>().withFreshnessTimeout(Duration(minutes: 30));
  final startDate =
      EventualNotifier<DateTime>().withFreshnessTimeout(Duration(minutes: 1));
  final endDate =
      EventualNotifier<DateTime>().withFreshnessTimeout(Duration(minutes: 1));

  List<dynamic> choices = [];

  ProcessModel(this.processId, this.entityId,
      [ProcessMetadata metadata,
      bool isInCensus,
      bool hasVoted,
      int currentParticipants]) {
    if (metadata is ProcessMetadata) {
      // Ensure we can read it back
      metadata.meta[META_PROCESS_ID] = this.processId;
      metadata.meta[META_ENTITY_ID] = this.entityId;
      this.metadata.setDefaultValue(metadata);
    }

    if (isInCensus is bool) this.isInCensus.setDefaultValue(isInCensus);
    if (hasVoted is bool) this.hasVoted.setDefaultValue(hasVoted);
    if (currentParticipants is int)
      this.currentParticipants.setDefaultValue(currentParticipants);
  }

  ProcessModel.fromMetadata(
      ProcessMetadata metadata, this.processId, this.entityId) {
    // Ensure we can read it back
    metadata.meta[META_PROCESS_ID] = this.processId;
    metadata.meta[META_ENTITY_ID] = this.entityId;

    this.metadata.setDefaultValue(metadata);

    switch (this.metadata.value.meta[META_PROCESS_CENSUS_BELONGS]) {
      case "true":
        this.isInCensus.setDefaultValue(true);
        break;
      case "false":
        this.isInCensus.setDefaultValue(false);
        break;
    }

    switch (this.metadata.value.meta[META_PROCESS_HAS_VOTED]) {
      case "true":
        this.hasVoted.setDefaultValue(true);
        break;
      case "false":
        this.hasVoted.setDefaultValue(false);
        break;
    }

    if (this.metadata.value.meta[META_PROCESS_CENSUS_SIZE] is String) {
      final strValue =
          this.metadata.value.meta[META_PROCESS_CENSUS_SIZE] ?? "0";
      final newSize = int.tryParse(strValue) ?? 0;
      this.censusSize.setDefaultValue(newSize);
    }
  }

  @override
  Future<void> refresh({bool force = false}) {
    log("Refreshing process ${this.processId}");

    return refreshMetadata(force: force)
        .catchError((_) {}) // update what we can
        .then((_) => refreshResults(force: force))
        .catchError((_) {}) // update what we can
        .then((_) => refreshIsInCensus(force: force))
        .catchError((_) {})
        .then((_) => refreshHasVoted(force: force))
        .catchError((_) {})
        .then((_) => refreshCurrentParticipants(force: force))
        .catchError((_) {})
        .then((_) => refreshCensusSize(force: force))
        .catchError((_) {})
        .then((_) => refreshDates(force: force))
        .catchError((_) {});
  }

  Future<void> refreshMetadata({bool force = false}) async {
    if (!force && this.metadata.isFresh)
      return;
    else if (!force && this.metadata.isLoading && this.metadata.isLoadingFresh)
      return;

    log("- [Process meta] Refreshing [${this.processId}]");

    // TODO: Don't refetch if the IPFS hash is the same

    try {
      this.metadata.setToLoading();
      final newMetadata =
          await getProcessMetadata(this.processId, AppNetworking.pool);
      if (!(newMetadata is ProcessMetadata))
        throw Exception("The process cannot be found");

      newMetadata.meta[META_PROCESS_ID] =
          this.processId; // Ensure we can read it back
      newMetadata.meta[META_ENTITY_ID] = this.entityId;

      log("- [Process meta] Refreshing DONE [${this.processId}]");

      this.metadata.setValue(newMetadata);
    } catch (err) {
      log("- [Process meta] Refreshing ERROR: $err [${this.processId}]");

      this.metadata.setError("error.couldNotFetchTheProcessDetails");
    }
  }

  Future<void> refreshResults({bool force = false}) async {
    if (!this.metadata.hasValue)
      return;
    else if (!force && this.results.isFresh)
      return;
    else if (!force && this.results.isLoading) return;

    log("- [Process results] Refreshing [${this.processId}]");

    try {
      this.results.setToLoading();
      final newResults = await getResultsDigest(
          this.processId, AppNetworking.pool,
          meta: this.metadata.value);
      if (!(newResults is ProcessResultsDigested))
        throw Exception("The process cannot be found");

      log("- [Process results] Refreshing DONE [${this.processId}]");

      this.results.setValue(newResults);
    } catch (err) {
      log("- [Process results] Refreshing ERROR: $err [${this.processId}]");

      this.results.setError("error.couldNotFetchTheProcessResults");
    }
  }

  Future<void> refreshIsInCensus({bool force = false}) async {
    if (!this.metadata.hasValue)
      return;
    else if (!force && this.isInCensus.isFresh)
      return;
    else if (!force && this.isInCensus.isLoading)
      return;
    else if (this.isInCensus.value == true)
      return; // we should never be excluded from a census once within

    final account = Globals.appState.currentAccount;
    if (account is! AccountModel)
      throw Exception("No current account selected");
    else if (!account.hasPublicKeyForEntity(this.entityId)) {
      log("The public key is not loaded yet for the entity " + this.entityId);
      this.isInCensus.setValue(null);
      return;
    }

    log("- [Process census presence] Refreshing [${this.processId}]");

    try {
      this.isInCensus.setToLoading();

      final pubKey =
          account.getPublicKeyForEntity(this.entityId).replaceAll("0x", "");

      // TODO: Revert back to digested

      // Undigested
      final censusPublicKeyClaim = base64.encode(hex.decode(pubKey));
      final alreadyDigested = false;

      // // Digested
      // final censusPublicKeyClaim = Hashing.digestHexClaim(pubKey);
      // final alreadyDigested = true;

      final proof = await generateProof(this.metadata.value.census.merkleRoot,
          censusPublicKeyClaim, alreadyDigested, AppNetworking.pool);
      if (proof is! String || !hexRegexp.hasMatch(proof)) {
        this.isInCensus.setValue(false);
        return;
      }

      final valid = await checkProof(this.metadata.value.census.merkleRoot,
          censusPublicKeyClaim, alreadyDigested, proof, AppNetworking.pool);

      log("- [Process census presence] Refreshing DONE [${this.processId}]");

      this.isInCensus.setValue(valid);
    } catch (err) {
      log("- [Process census presence] Refreshing ERROR: $err [${this.processId}]");

      // NOTE: Leave the comment to enforce i18n parsing
      // getText(context, "error.theCensusIsNotAvailable")
      this.isInCensus.setError("error.theCensusIsNotAvailable");
    }
  }

  Future<void> refreshHasVoted({bool force = false}) async {
    if (!force && this.hasVoted.isFresh)
      return;
    else if (!force && this.hasVoted.isLoading)
      return;
    else if (!this.hasVoted.hasError && this.hasVoted.value == true)
      return; // If you already voted, you can't un-vote

    final account = Globals.appState.currentAccount;
    if (account is! AccountModel)
      throw Exception("No current account selected");
    else if (!account.hasPublicKeyForEntity(this.entityId)) {
      log("The public key is not loaded yet for the entity " + this.entityId);
      this.isInCensus.setValue(null);
      return;
    }

    log("- [refreshHasVoted] [${this.processId}]");

    try {
      this.hasVoted.setToLoading();

      final entity = this.entity;
      if (entity is! EntityModel) throw Exception("No entity for process");

      final hexPubKey = account.getPublicKeyForEntity(this.entityId);
      final publicKeyBytes = hex.decode(hexPubKey.replaceAll("0x04", ""));

      final addrBytes = publicKeyToAddress(publicKeyBytes);
      final userAddress = EthereumAddress(addrBytes).hexEip55;

      final pollNullifier =
          await getSignedVoteNullifier(userAddress, this.processId);

      final success = await getEnvelopeStatus(
              this.processId, pollNullifier, AppNetworking.pool)
          .catchError((_) {});

      if (success is bool) {
        log("- [Process voted] Refreshing DONE [${this.processId}]");

        this.hasVoted.setValue(success);
      } else {
        log("- [Process voted] Refreshing NO BOOL [${this.processId}]");

        // NOTE: Leave the comment to enforce i18n parsing
        // getText(context, "error.couldNotCheckTheProcessStatus")
        this.hasVoted.setError("error.couldNotCheckTheProcessStatus");
      }
    } catch (err) {
      log("- [Process voted] Refreshing ERROR: $err [${this.processId}]");

      // NOTE: Leave the comment to enforce i18n parsing
      // getText(context, "error.couldNotCheckTheVoteStatus")
      this.hasVoted.setError("error.couldNotCheckTheVoteStatus");
    }
  }

  Future<void> refreshCensusSize({bool force = false}) {
    if (!this.metadata.hasValue)
      return null;
    else if (!force && this.censusSize.isFresh)
      return Future.value();
    else if (!force && this.censusSize.isLoading) return Future.value();

    log("- [Process census] Refreshing [${this.processId}]");

    this.censusSize.setToLoading();
    return getCensusSize(
            this.metadata.value.census.merkleRoot, AppNetworking.pool)
        .then((size) {
      log("- [Process census] Refreshing DONE: size $size [${this.processId}]");

      return this.censusSize.setValue(size);
    }).catchError((err) {
      log("- [Process census] Refreshing ERROR: $err [${this.processId}]");

      this.censusSize.setError("The census info is not available");
    });
  }

  Future<void> refreshCurrentParticipants({bool force = false}) {
    if (!this.metadata.hasValue)
      return Future.value();
    else if (!force && this.currentParticipants.isFresh)
      return Future.value();
    else if (!force && this.currentParticipants.isLoading)
      return Future.value();

    log("- [Process participants] Refreshing [${this.processId}]");

    this.currentParticipants.setToLoading();
    return getEnvelopeHeight(this.processId, AppNetworking.pool)
        .then((numVotes) {
      log("- [Process participants] Refreshing DONE [${this.processId}]");

      return this.currentParticipants.setValue(numVotes);
    }).catchError((err) {
      log("- [Process participants] Refreshing ERROR: $err [${this.processId}]");

      this.currentParticipants.setError("The process info is not available");
    });
  }

  Future<void> refreshDates({bool force = false}) {
    if (!this.metadata.hasValue)
      return null;
    else if (!force && this.startDate.isFresh)
      return null;
    else if (!force && this.startDate.isLoading) return null;

    log("- [Process dates] Refreshing [${this.processId}]");

    final startBlock = this.metadata.value.startBlock;
    final endBlock =
        this.metadata.value.startBlock + this.metadata.value.blockCount;
    return Globals.appState
        .refreshBlockStatus()
        .then((_) => estimateDateAtBlock(startBlock, AppNetworking.pool,
            status: Globals.appState.blockStatus.value))
        .then((startDate) => this.startDate.setValue(startDate))
        .then((_) => estimateDateAtBlock(endBlock, AppNetworking.pool,
            status: Globals.appState.blockStatus.value))
        .then((endDate) {
      log("- [Process dates] Refreshing [DONE ${this.processId}]");

      this.endDate.setValue(endDate);
    }).catchError((err, stack) {
      log("- [Process dates] ERROR: $err [${this.processId}]");
      // log(stack);

      if (!this.startDate.hasValue) this.startDate.setError("Cannot estimate");
      this.endDate.setError("Cannot estimate");
    });
  }

  /// Cleans the ephemeral state of the process related to an account
  @override
  void cleanEphemeral() {
    this.isInCensus.setValue(null);
    this.hasVoted.setValue(null);
    this.currentParticipants.setValue(null);
    this.censusSize.setValue(null);
    this.choices = [];
  }

  // GETTERS

  /// Returns the entity model that corresponds to the current process. Returns null if not found.
  EntityModel get entity {
    if (!Globals.entityPool.hasValue) return null;

    return Globals.entityPool.value.firstWhere((entity) {
      if (!(entity is EntityModel) || !entity.metadata.hasValue) return false;

      return entity.reference.entityId == entityId;
    }, orElse: () => null);
  }

  double get currentParticipation {
    if (!this.censusSize.hasValue || !this.currentParticipants.hasValue)
      return 0.0;
    else if (this.censusSize.value <= 0)
      return 0.0;
    else if (this.currentParticipants == this.censusSize) return 100.0;

    return this.currentParticipants.value *
        100.0 /
        this.censusSize.value.toDouble();
  }
}
