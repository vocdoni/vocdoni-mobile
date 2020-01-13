import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';
// import 'package:vocdoni/lib/api.dart';

// POOL

/// This class should be used exclusively as a global singleton via MultiProvider.
/// EntityPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateModel or StateModel.
///
class EntityPoolModel extends StateModel<List<EntityModel>> implements StatePersistable, StateRefreshable {
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
            entityRef.entryPoints.addAll(entityMeta.meta[META_ENTITY_ID].split(","));
            
            // TODO FROM POOL

            final procsModels =
                EntityModel.getPersistedProcessesForEntity(entityMeta);
            final feedModel = EntityModel.getPersistedFeedForEntity(entityMeta);

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
  Future<void> refresh() async {
    if (!hasValue) return;

    try {
      // TODO: Get a filtered EntityModel list of the Entities of the current user

      // This will call `setValue` on the individual models already within the pool.
      // No need to rebuild an updated pool list.
      await Future.wait(
          this.value.map((entityModel) => entityModel.refresh()).toList());

      await this.writeToStorage();
      // notifyListeners(); // Not needed => `setValue` already does it on every model
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw err;
    }
  }
}

// MODEL

/// EntityModel encapsulates the relevant information of a Vocdoni Entity.
/// This includes its metadata and the participation processes.
///
class EntityModel implements StateRefreshable {
  final EntityReference reference; // This is never fetched
  final StateModel<EntityMetadata> metadata = StateModel<EntityMetadata>();
  final StateModel<List<ProcessModel>> processes =
      StateModel<List<ProcessModel>>();
  final StateModel<FeedModel> feed = StateModel<FeedModel>();

  // TODO: Use the missing variables
  // final StateModel<List<EntityMetadata_Action>> visibleActions = StateModel();
  // final StateModel<EntityMetadata_Action> registerAction = StateModel();
  // final StateModel<bool> isRegistered = StateModel(false);

  /// Builds an EntityModel with the given reference and optional data.
  /// Overwrites the `entityId` and `entryPoints` of the `metadata.meta{}` field
  EntityModel(this.reference,
      [EntityMetadata entityMeta, List<ProcessModel> procs, FeedModel feed]) {

    if(entityMeta is EntityMetadata) {
      entityMeta.meta[META_ENTITY_ID] = this.reference.entityId; // Ensure we can read it back later on
      entityMeta.meta[META_ENTITY_ENTRY_POINTS] = this.reference.entryPoints.join(","); // Ensure we can read it back later on
      this.metadata.load(entityMeta);
    }
    else {
      final newMetadata = EntityMetadata();
      newMetadata.meta[META_ENTITY_ID] = this.reference.entityId;
      newMetadata.meta[META_ENTITY_ENTRY_POINTS] = this.reference.entryPoints.join(",");
      this.metadata.load(entityMeta);
    }

    if(procs is List)this.processes.load(procs);
    if(feed is FeedModel) this.feed.load(feed);
  }

  @override
  Future<void> refresh() async {
    // TODO: Get the IPFS hash
    // TODO: Don't refetch if the IPFS hash is the same
    // TODO: Implement refetch of the metadata
    await fetchEntityData(this.entityReference)
    // TODO: Check the last time that data was fetched
    // TODO: `refresh` the voting processes
    // TODO: Get the news feed and `refresh` it
    await fetchEntityNewsFeed(
          this.entityReference, this.entityMetadata.value, this.lang)
    // TODO: Force a write() to persistence if changed
    // TODO: Update the visible actions
    // TODO: Determine whether the user is already registered
  }

  // STATIC HELPERS

  /// Returns the EntityModel instance corresponding to the given reference
  /// only if it already belongs to the pool. You need to fetch it otherwise.
  static getByReference(EntityReference entityRef) {
    if (!globalEntityPool.hasValue) return null;
    return globalEntityPool.value.firstWhere((entityModel) {
      return entityModel.reference.entityId == entityRef.entityId;
    }, orElse: () => null);
  }

  static List<ProcessModel> getPersistedProcessesForEntity(
      EntityMetadata entityMeta) {
    // TODO: GET FROM THE POOL INSTEAD

    return globalProcessesPersistence
        .get()
        .where((procMeta) =>
            procMeta.meta[META_ENTITY_ID] == entityMeta.meta[META_ENTITY_ID])
        .map((procMeta) => ProcessModel(procMeta.meta[META_PROCESS_ID], procMeta.meta[META_ENTITY_ID]))
        .cast<ProcessModel>()
        .toList();
  }

  static FeedModel getPersistedFeedForEntity(EntityMetadata entityMeta) {
    // TODO: GET FROM THE POOL INSTEAD

    final feedData = globalFeedPersistence.get().firstWhere(
        (feed) => feed.meta[META_ENTITY_ID] == entityMeta.meta[META_ENTITY_ID],
        orElse: () => null);
        
    return FeedModel.fromFeed(feedData);
  }

  // TODO: ADAPT

  /*Future<void> updateVisibleActions() async {
    final List<EntityMetadata_Action> actionsToDisplay = [];

    if (!this.entityMetadata.hasValue) return;

    this.visibleActions.setToLoading();
    if (hasState) rebuildStates([EntityStateTags.ACTIONS]);

    for (EntityMetadata_Action action in this.entityMetadata.value.actions) {
      if (action.register == true) {
        if (this.registerAction.value != null)
          continue; //only one registerAction is supported

        this.registerAction.setValue(action);
        this.isRegistered.setValue(
            await isActionVisible(action, this.entityReference.entityId));

        if (hasState) rebuildStates([EntityStateTags.ACTIONS]);
      } else {
        bool isVisible =
            await isActionVisible(action, this.entityReference.entityId);
        if (isVisible) actionsToDisplay.add(action);
      }
    }

    this.visibleActions.setValue(actionsToDisplay);
    if (hasState) rebuildStates([EntityStateTags.ACTIONS]);
  }

  Future<bool> isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    if (action.visible == "true")
      return true;
    else if (action.visible == null || action.visible == "false") return false;

    // ELSE => the `visible` field is a URL

    String publicKey = account.identity.identityId;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;

    // TODO: Get the private key to sign appropriately
    final privateKey = "";
    debugPrint(
        "TODO: Retrieve the private key to sign the action visibility request");

    try {
      Map payload = {
        "type": action.type,
        'publicKey': publicKey,
        "entityId": entityId,
        "timestamp": timestamp,
        "signature": ""
      };

      if (privateKey != "") {
        payload["signature"] = await signString(
            jsonEncode({"timestamp": timestamp.toString()}), privateKey);
      } else {
        payload["signature"] = "0x"; // TODO: TEMP
      }

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
      return false;
    }

    return false;
  }*/
}
