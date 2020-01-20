import 'dart:convert';
import 'package:dvote/util/parsers.dart';
import 'package:http/http.dart' as http;

import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-notifier.dart';
import 'package:vocdoni/lib/singletons.dart';

// POOL

/// This class should be used exclusively as a global singleton via MultiProvider.
/// EntityPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateNotifier or StateNotifier.
///
class EntityPoolModel extends StateNotifier<List<EntityModel>>
    implements StatePersistable, StateRefreshable {
  EntityPoolModel() {
    this.load(List<EntityModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  /// and populate related models
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.load(List<EntityModel>());

    try {
      this.setToLoading();
      // Identities
      final entityMetadataList = globalEntitiesPersistence.get();
      final entityModelList = entityMetadataList
          .map((entityMeta) {
            // READ INDIRECT MODELS
            final entityRef = EntityReference();
            entityRef.entityId = entityMeta.meta[META_ENTITY_ID];
            entityRef.entryPoints
                .addAll(entityMeta.meta[META_ENTITY_ID].split(","));

            final procsModels = EntityModel.getProcessesForEntity(
                entityMeta.meta[META_ENTITY_ID]);
            final feedModel =
                EntityModel.getFeedForEntity(entityMeta.meta[META_ENTITY_ID]);

            return EntityModel(entityRef, entityMeta, procsModels, feedModel);
          })
          .cast<EntityModel>()
          .toList();
      this.setValue(entityModelList);
    } catch (err) {
      if (!kReleaseMode) print(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.load(List<EntityModel>());

    try {
      // WRITE THE DIRECT DATA THAT WE MANAGE
      final entitiesMeta = this
          .value
          .map((entityModel) => entityModel.metadata)
          .cast<EntityMetadata>()
          .toList();
      await globalEntitiesPersistence.writeAll(entitiesMeta);

      // INDIRECT MODELS SHOULD HAVE UPDATED THEMSELVES AS SOON AS
      // ITS VALUE CHANGED IN THE PAST. WE DON'T HANDLE IT FROM AN EXTERNAL MODEL.
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh([bool force = false]) async {
    if (!this.hasValue) return;

    try {
      // TODO: Get a filtered EntityModel list of the Entities of the current user

      // This will call `setValue` on the individual models already within the pool.
      // No need to rebuild an updated pool list.
      await Future.wait(
          this.value.map((entityModel) => entityModel.refresh(force)).toList());

      await this.writeToStorage();
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw err;
    }
  }

  /// Removes the given entity from the pool and persists the new pool.
  /// Also updates the Feed and Process pools if needed
  Future<void> remove(EntityReference entityRef) async {
    if (!this.hasValue) throw Exception("The pool has no value yet");

    final modelToRemove = this.value.firstWhere(
        (entity) => entity.reference.entityId == entityRef.entityId,
        orElse: () => null);
    if (modelToRemove == null) return;

    final updatedValue = this
        .value
        .where((entity) => entity.reference.entityId != entityRef.entityId)
        .cast<EntityModel>()
        .toList();
    this.setValue(updatedValue);

    await this.writeToStorage();

    // Remove the entity voting processes
    if (modelToRemove.processes.hasValue) {
      await globalProcessPool.remove(modelToRemove.processes.value);
    }

    // Remove the entity feed if not used elsewhere
    if (modelToRemove.feed.hasValue) {
      await globalFeedPool.remove(modelToRemove.feed.value);
    }
  }
}

// MODEL

/// EntityModel encapsulates the relevant information of a Vocdoni Entity.
/// This includes its metadata and the participation processes.
///
class EntityModel implements StateRefreshable {
  final EntityReference reference; // This is never fetched
  final StateNotifier<EntityMetadata> metadata =
      StateNotifier<EntityMetadata>().withFreshness(20);
  final StateNotifier<List<ProcessModel>> processes =
      StateNotifier<List<ProcessModel>>();
  final StateNotifier<FeedModel> feed = StateNotifier<FeedModel>().withFreshness(45);

  final StateNotifier<List<EntityMetadata_Action>> visibleActions = StateNotifier();
  final StateNotifier<EntityMetadata_Action> registerAction = StateNotifier();
  final StateNotifier<bool> isRegistered = StateNotifier(false);

  /// Builds an EntityModel with the given reference and optional data.
  /// Overwrites the `entityId` and `entryPoints` of the `metadata.meta{}` field
  EntityModel(this.reference,
      [EntityMetadata entityMeta, List<ProcessModel> procs, FeedModel feed]) {
    if (entityMeta is EntityMetadata) {
      entityMeta.meta[META_ENTITY_ID] =
          this.reference.entityId; // Ensure we can read it back later on
      entityMeta.meta[META_ENTITY_ENTRY_POINTS] = this
          .reference
          .entryPoints
          .join(","); // Ensure we can read it back later on
      this.metadata.load(entityMeta);
    } else {
      final newMetadata = EntityMetadata();
      newMetadata.meta[META_ENTITY_ID] = this.reference.entityId;
      newMetadata.meta[META_ENTITY_ENTRY_POINTS] =
          this.reference.entryPoints.join(",");
      this.metadata.load(entityMeta);
    }

    if (procs is List) this.processes.load(procs);
    if (feed is FeedModel) this.feed.load(feed);
  }

  /// Fetch any internal items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  /// IMPORTANT: Persistence is not managed by this function. Make sure to call `writeToPersistence` on the pool right after.
  @override
  Future<void> refresh([bool force = false]) {
    return Future.wait(<Future>[
      refreshMetadata(force),
      refreshVisibleActions(force),
      refreshProcesses(force),
      refreshFeed(force)
    ]);
  }

  Future<void> refreshMetadata([bool force = false]) async {
    // TODO: Get the IPFS hash
    // TODO: Don't refetch if the IPFS hash is the same
    if (!(reference is EntityReference))
      return;
    else if (!force && this.metadata.isFresh)
      return;
    else if (!force && this.metadata.isLoading) return;

    final dvoteGw = getDVoteGateway();
    final web3Gw = getWeb3Gateway();

    this.metadata.setToLoading();

    try {
      final EntityMetadata entityMetadata =
          await fetchEntity(reference, dvoteGw, web3Gw);
      entityMetadata.meta[META_ENTITY_ID] = reference.entityId;

      this.metadata.setValue(entityMetadata);
    } catch (err) {
      if (!kReleaseMode) print(err);
      this.metadata.setError("The entity's data cannot be fetched");
    }
  }

  Future<void> refreshProcesses([bool force = false]) async {
    // TODO: Check the last time that data was fetched
    // TODO: `refresh` the voting process list
    ;
  }

  Future<void> refreshFeed([bool force = false]) async {
    if (this.metadata.hasValue)
      return;
    else if (!force && this.feed.isFresh)
      return;
    else if (!force && this.feed.isLoading) return;

    this.feed.setToLoading();

    if (!(this.metadata is EntityMetadata))
      return;
    else if (!(this.metadata.value.newsFeed is Map<String, String>))
      return;
    else if (!(this.metadata.value.newsFeed[globalAppState.currentLanguage]
        is String)) return;

    final dvoteGw = getDVoteGateway();
    this.feed.setToLoading();

    try {
      final cUri = ContentURI(
          this.metadata.value.newsFeed[globalAppState.currentLanguage]);

      final result = await fetchFileString(cUri, dvoteGw);
      final feed = parseFeed(result);
      feed.meta[META_ENTITY_ID] = this.reference.entityId;
      feed.meta[META_LANGUAGE] = globalAppState.currentLanguage;

      this.feed.setValue(FeedModel.fromFeed(feed));
    } catch (err) {
      if (!kReleaseMode) print(err);
      this.feed.setError("Could not fetch the News Feed");
    }
  }

  Future<void> refreshVisibleActions([bool force = false]) async {
    final List<EntityMetadata_Action> visibleStandardActions = [];

    if (!this.metadata.hasValue)
      return;
    else if (!force && this.visibleActions.isFresh)
      return;
    else if (!force && this.visibleActions.isLoading) return;

    this.registerAction.setToLoading();
    this.isRegistered.setToLoading();
    this.visibleActions.setToLoading();

    try {
      await Future.wait(this
          .metadata
          .value
          .actions
          .map((action) async {
            if (action.register) {
              return _isActionVisible(action, this.reference.entityId)
                  .then((visible) {
                if (!(visible is bool)) throw Exception();
                this.registerAction.setValue(action);
                this.isRegistered.setValue(!visible);
              }).catchError((err) {
                // capture the error locally
                this
                    .registerAction
                    .setError("Could not load the register status");
                this
                    .isRegistered
                    .setError("Could not load the register status");
              });
            } else {
              // standard action
              // in case of error: propagate to the global catcher
              bool isVisible =
                  await _isActionVisible(action, this.reference.entityId);
              if (isVisible) visibleStandardActions.add(action);
            }
          })
          .cast<Future>()
          .toList());

      this.visibleActions.setValue(visibleStandardActions);
    } catch (err) {
      this.visibleActions.setError("Could not fetch the entity details");

      // The request fails entirely. Keep values if already present
      if (this.registerAction.isLoading) {
        this.registerAction.setError("Could not load the register status");
      }
      if (this.isRegistered.isLoading) {
        this.isRegistered.setError("Could not load the register status");
      }
    }
  }

  // PRIVATE METHODS

  /// Returns true/false if the value is defined or the request succeeds. Returns null if the request
  /// can't be signed or the response is otherwise undefined.
  ///
  Future<bool> _isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    // Hardcoded value
    if (action.visible == "true")
      return true;
    else if (!(action.visible is String) || action.visible == "false")
      return false;

    // OTHERWISE => the `visible` field is expected to be a URL

    final currentAccount = globalAppState.currentAccount;
    if (!(currentAccount is AccountModel))
      return null;
    else if (!currentAccount.signedTimestamp.hasValue) return null;

    final publicKey = currentAccount.identity.value.identityId;

    try {
      Map payload = {
        "type": action.type,
        'publicKey': publicKey,
        "entityId": entityId,
        "timestamp": currentAccount.timestampUsedToSign.value,
        "signature": currentAccount.signedTimestamp.value
      };

      Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await http.post(action.visible,
          body: jsonEncode(payload), headers: headers);
      if (response.statusCode != 200 || !(response.body is String))
        return false;
      final body = jsonDecode(response.body);
      if (body is Map && body["visible"] == true) return true;
    } catch (err) {
      return null;
    }

    return false;
  }

  // STATIC HELPERS

  /// Returns the EntityModel instance corresponding to the given reference
  /// only if it already belongs to the pool. You need to fetch it otherwise.
  static getFromPool(EntityReference entityRef) {
    if (!globalEntityPool.hasValue) return null;
    return globalEntityPool.value.firstWhere((entityModel) {
      return entityModel.reference.entityId == entityRef.entityId;
    }, orElse: () => null);
  }

  static List<ProcessModel> getProcessesForEntity(String entityId) {
    return globalProcessPool.value
        .where((processModel) =>
            processModel.metadata.hasValue &&
            processModel.metadata.value.meta[META_ENTITY_ID] == entityId)
        .map((processModel) => ProcessModel(
            processModel.metadata.value.meta[META_PROCESS_ID],
            processModel.metadata.value.meta[META_ENTITY_ID]))
        .cast<ProcessModel>()
        .toList();
  }

  static FeedModel getFeedForEntity(String entityId) {
    return globalFeedPool.value.firstWhere(
        (feedModel) => feedModel.entityId == entityId,
        orElse: () => null);
  }
}
