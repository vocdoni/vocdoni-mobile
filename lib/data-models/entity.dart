import 'dart:convert';
import 'package:dvote/util/json-signature.dart';
import 'package:dvote/util/parsers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:dvote/dvote.dart';

import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/model-base.dart';
import 'package:eventual/eventual.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/notifications.dart';

// POOL

/// This class should be used exclusively as a global singleton.
/// EntityPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using EventualNotifier or EventualNotifier.
///
class EntityPoolModel extends EventualNotifier<List<EntityModel>>
    implements ModelPersistable, ModelRefreshable, ModelCleanable {
  EntityPoolModel() {
    this.setDefaultValue(List<EntityModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  /// and populate related models
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(List<EntityModel>());

    try {
      this.setToLoading();
      // Identities
      final entityMetadataList = Globals.entitiesPersistence.get();
      final entityModelList = entityMetadataList
          .map((entityMeta) {
            // READ INDIRECT MODELS
            final entityRef = EntityReference();
            entityRef.entityId = entityMeta.meta[META_ENTITY_ID];
            entityRef.entryPoints
                .addAll(entityMeta.meta[META_ENTITY_ENTRY_POINTS].split(","));

            final procsModels = EntityModel.getProcessesPersistedForEntity(
                entityMeta.meta[META_ENTITY_ID]);
            final feedModel =
                EntityModel.getFeedForEntity(entityMeta.meta[META_ENTITY_ID]);

            return EntityModel(entityRef, entityMeta, procsModels, feedModel);
          })
          .cast<EntityModel>()
          .toList();
      this.setValue(entityModelList);
    } catch (err) {
      logger.log(err);
      this.setError("Cannot read the persisted data", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.setValue(List<EntityModel>());

    try {
      // WRITE THE DIRECT DATA THAT WE MANAGE
      final entitiesMeta = this
          .value
          .where((item) => item.metadata.hasValue)
          .map((entityModel) {
            final val = entityModel.metadata.value;
            val.meta[META_ENTITY_ID] = entityModel.reference.entityId;
            val.meta[META_ENTITY_ENTRY_POINTS] =
                entityModel.reference.entryPoints.join(",");
            return val;
          })
          .cast<EntityMetadata>()
          .toList();
      await Globals.entitiesPersistence.writeAll(entitiesMeta);

      // Cascade the write request for the process ad feed pools
      await Globals.processPool.writeToStorage();
      await Globals.feedPool.writeToStorage();
    } catch (err) {
      logger.log(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh({bool force = false, String derivedPrivateKey}) async {
    if (!hasValue ||
        Globals.appState.currentAccount == null ||
        !Globals.appState.currentAccount.entities.hasValue) return;

    try {
      // Get a filtered list of the Entities of the current user
      final entityIds = Globals.appState.currentAccount.entities.value
          .map((entity) => entity.reference.entityId)
          .toList();

      // This will call `setValue` on the individual models already within the pool.
      // No need to update the pool list itself.
      final entities = this
          .value
          .where((entityModel) =>
              entityIds.contains(entityModel.reference.entityId))
          .toList();
      for (final entityModel in entities) {
        await entityModel.refresh(
            force: force, derivedPrivateKey: derivedPrivateKey);
      }

      await this.writeToStorage();
    } catch (err) {
      logger.log(err);
      throw err;
    }
  }

  /// Cleans the ephemeral state of all entities
  @override
  void cleanEphemeral() {
    this.value.forEach((entity) => entity.cleanEphemeral());
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
      await Globals.processPool.remove(modelToRemove.processes.value);
    }

    // Remove the entity feed if not used elsewhere
    if (modelToRemove.feed.hasValue) {
      await Globals.feedPool.remove(modelToRemove.feed.value);
    }
  }
}

// MODEL

/// EntityModel encapsulates the relevant information of a Vocdoni Entity.
/// This includes its metadata and the participation processes.
///
class EntityModel implements ModelRefreshable, ModelCleanable {
  final EntityReference reference; // This is never fetched
  final metadata = EventualNotifier<EntityMetadata>()
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 5 : 1));
  final processes = EventualNotifier<List<ProcessModel>>()
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 5 : 1));
  final feed = EventualNotifier<Feed>()
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 5 : 1));

  final visibleActions = EventualNotifier<List<EntityMetadata_Action>>()
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 5 : 1));
  final registerAction = EventualNotifier<EntityMetadata_Action>()
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 30 : 1));
  final isRegistered = EventualNotifier<bool>(false)
      .withFreshnessTimeout(Duration(minutes: kReleaseMode ? 30 : 1));
  final notificationTopics = EventualNotifier<bool>();

  /// The timestamp used to sign the precomputed request: `{"method":"getVisibility","timestamp":1234...}`
  int actionVisibilityTimestampUsed;

  /// The signature of `actionVisibilityTimestampUsed`. Used for action visibility checks
  String actionVisibilityCheckSignature;

  /// Builds an EntityModel with the given reference and optional data.
  /// Overwrites the `entityId` and `entryPoints` of the `metadata.meta{}` field
  EntityModel(this.reference,
      [EntityMetadata entityMeta, List<ProcessModel> procs, Feed feed]) {
    if (entityMeta is EntityMetadata) {
      entityMeta.meta[META_ENTITY_ID] =
          this.reference.entityId; // Ensure we can read it back later on
      entityMeta.meta[META_ENTITY_ENTRY_POINTS] = this
          .reference
          .entryPoints
          .join(","); // Ensure we can read it back later on
      this.metadata.setDefaultValue(entityMeta);
    } else {
      final newMetadata = EntityMetadata();
      newMetadata.meta[META_ENTITY_ID] = this.reference.entityId;
      newMetadata.meta[META_ENTITY_ENTRY_POINTS] =
          this.reference.entryPoints.join(",");
      this.metadata.setDefaultValue(entityMeta);
    }

    if (procs is List) this.processes.setDefaultValue(procs);
    if (feed is Feed) this.feed.setDefaultValue(feed);
  }

  /// Fetch any internal items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  /// **IMPORTANT**: Persistence is not managed by this function. Make sure to call `writeToPersistence` on the pool right after.
  @override
  Future<void> refresh({bool force = false, String derivedPrivateKey}) async {
    if (derivedPrivateKey is String) {
      await refreshSignedTimestamp(derivedPrivateKey);
    }

    // TODO: Simplify and call the dependent refresh's after refreshMetadata

    return refreshMetadata(force: force, skipChildren: false);

    // refreshMetadata will call the dependent models if needed
    // The metadata needs to be refreshed first
  }

  /// Fetch the Entity metadata (if needed) and optionally fetch the models that depend on it (processes, feed and visible actions)
  Future<void> refreshMetadata(
      {bool force = false, bool skipChildren = true}) async {
    // TODO: Get the IPFS hash
    // TODO: Don't refetch if the IPFS hash is the same

    if (!(reference is EntityReference))
      return;
    else if (!force && this.metadata.isLoading && this.metadata.isLoadingFresh)
      return;

    logger.log("[Entity meta] Refreshing [${reference.entityId}]");

    final oldEntityMetadata = this.metadata;
    EntityMetadata freshEntityMetadata;
    bool needsProcessListReload = false;
    bool needsFeedReload = false;

    try {
      if (force || !this.metadata.hasValue || !this.metadata.isFresh) {
        this.metadata.setToLoading();

        freshEntityMetadata = await fetchEntity(reference, AppNetworking.pool);
        freshEntityMetadata.meta[META_ENTITY_ID] = reference.entityId;

        if (this.metadata.hasValue) {
          // Preserve old `meta` key/values
          for (var k in metadata.value.meta.keys) {
            freshEntityMetadata.meta[k] = metadata.value.meta[k];
          }
        }

        logger.log("- [Entity meta] Refreshing [DONE] [${reference.entityId}]");

        this.metadata.setValue(freshEntityMetadata);
      }
    } catch (err) {
      logger.log(
          "- [Entity meta] Refreshing [ERROR: $err] [${reference.entityId}]");

      this.metadata.setError("The entity's data cannot be fetched",
          keepPreviousValue: true);
    }
    // if at this point there is no metadata, skip
    if (this.metadata.hasError || !this.metadata.hasValue)
      return;
    else if (skipChildren) return;

    // If the metadata didn't update, ensure we have a value
    if (freshEntityMetadata == null) freshEntityMetadata = this.metadata.value;

    // Trigger updates on child models

    try {
      // Process ID's changed?
      if (oldEntityMetadata.hasValue &&
          !listEquals(oldEntityMetadata.value.votingProcesses.active,
              freshEntityMetadata.votingProcesses.active)) {
        needsProcessListReload = true;
      }

      // URI changed?
      if (!oldEntityMetadata.hasValue)
        needsFeedReload = true;
      else if (oldEntityMetadata.hasValue) {
        if (!(oldEntityMetadata.value.newsFeed[Globals.appState.currentLanguage]
                is String) ||
            oldEntityMetadata
                    .value.newsFeed[Globals.appState.currentLanguage] !=
                freshEntityMetadata.newsFeed[Globals.appState.currentLanguage])
          needsFeedReload = true;
      }

      logger.log("- [Entity children] Loading [${reference.entityId}]");

      return Future.wait([
        this.refreshProcesses(force: needsProcessListReload),
        this.refreshFeed(force: needsFeedReload),
        refreshVisibleActions(force: force)
      ]);
    } catch (err) {
      logger.log(
          "- [Entity children] Loading [ERROR: $err] [${reference.entityId}]");

      throw err;
    }
  }

  Future<void> refreshProcesses({bool force = false}) async {
    if (!this.metadata.hasValue)
      return;
    else if (!force && !(this.metadata.value.votingProcesses.active is List) ||
        this.metadata.value.votingProcesses.active.length == 0)
      return;
    else if (!force && this.processes.isFresh) return;

    this.processes.setToLoading();

    try {
      final newGlobalProcessPoolList = List<ProcessModel>();
      newGlobalProcessPoolList.addAll(Globals.processPool.value.where((item) =>
          item.entityId != this.reference.entityId)); // clone without ours

      // make new processes list
      final oldEntityProcessModels = this.processes.value ?? [];
      final newProcessIds = this.metadata.value.votingProcesses.active;

      logger.log(
          "- [Entity procs] Loading [${this.metadata.value.votingProcesses.active.length} active]");

      // add new
      final List<ProcessModel> myFreshProcessModels =
          await Future.wait(newProcessIds
              .map((processId) async {
                final prevModel = oldEntityProcessModels.firstWhere(
                    (model) =>
                        model.processId == processId &&
                        model.entityId == this.reference.entityId,
                    orElse: () => null);

                if (prevModel is ProcessModel) {
                  await prevModel.refreshMetadata().catchError((_) {});
                  return prevModel;
                } else {
                  final newModel =
                      ProcessModel(processId, this.reference.entityId);
                  await newModel.refreshMetadata().catchError((_) {});
                  return newModel;
                }
              })
              .cast<Future<ProcessModel>>()
              .toList());

      // local update
      this.processes.setValue(myFreshProcessModels);

      // global update
      newGlobalProcessPoolList.addAll(myFreshProcessModels); // merge
      Globals.processPool.setValue(newGlobalProcessPoolList);
      await Globals.processPool.writeToStorage();
    } catch (err) {
      logger.log(
          "- [Entity procs] Loading [ERROR: $err] [${reference.entityId}]");

      this.processes.setError("Could not update the process list",
          keepPreviousValue: true);
      throw err;
    }
  }

  Future<void> refreshFeed({bool force = false}) async {
    if (!this.metadata.hasValue)
      return;
    else if (!force && this.feed.isLoading && this.feed.isLoadingFresh) return;

    if (!(this.metadata.value.newsFeed[Globals.appState.currentLanguage]
        is String)) return;

    try {
      final currentContentUri =
          this.metadata.value.newsFeed[Globals.appState.currentLanguage];

      if (this.feed.hasValue &&
          this.feed.value.meta[META_FEED_CONTENT_URI] == currentContentUri) {
        // URI not changed
        if (!force && this.feed.isFresh) return;
      }

      // TODO: Don't refetch if the CURI is an IPFS hash and it didn't change

      this.feed.setToLoading();

      logger.log("- [Entity feed] Loading [${this.reference.entityId}]");

      // Fetch from a new URI
      final cUri = ContentURI(currentContentUri);

      final result = await fetchFileString(cUri, AppNetworking.pool);
      final Feed feed = parseFeed(result);
      feed.meta[META_FEED_CONTENT_URI] = currentContentUri;
      feed.meta[META_ENTITY_ID] = this.reference.entityId;
      feed.meta[META_LANGUAGE] = Globals.appState.currentLanguage;

      this.feed.setValue(feed);

      logger.log("- [Entity feed] Loading [DONE] [${this.reference.entityId}]");

      final idx = Globals.feedPool.value.indexWhere(
          (feed) => feed.meta[META_ENTITY_ID] == this.reference.entityId);
      if (idx < 0) {
        Globals.feedPool.value.add(this.feed.value);
      } else {
        Globals.feedPool.value[idx] = this.feed.value;
      }
      Globals.feedPool.notifyChange();

      await Globals.feedPool.writeToStorage();
    } catch (err) {
      logger
          .log("- [Entity feed] Loading [ERROR: $err] [${reference.entityId}]");

      this
          .feed
          .setError("Could not fetch the News Feed", keepPreviousValue: true);
      throw err;
    }
  }

  /// Precompute a request signature for entity registry backends to accept
  /// our requests for a certain period of time
  Future<void> refreshSignedTimestamp(String derivedPrivateKey) async {
    // TODO: Add the entity ID to the Payload (nice to have, since the public key is unique to the entity)

    final ts = DateTime.now().millisecondsSinceEpoch;
    final body = {"method": "getVisibility", "timestamp": ts};
    final signature =
        await JSONSignature.signJsonPayloadAsync(body, derivedPrivateKey);

    if (signature.startsWith("0x"))
      this.actionVisibilityCheckSignature = signature;
    else
      this.actionVisibilityCheckSignature = "0x" + signature;
    this.actionVisibilityTimestampUsed = ts;
  }

  Future<void> refreshVisibleActions({bool force = false}) async {
    // TODO: Skipping until the new API is available
    return null;
    // TODO: Reenable

    final List<EntityMetadata_Action> visibleStandardActions = [];

    if (!this.metadata.hasValue)
      return;
    else if (!force && this.visibleActions.isFresh)
      return;
    else if (!force &&
        this.visibleActions.isLoading &&
        this.visibleActions.isLoadingFresh) return;

    logger.log("- [Entity actions] Loading [${reference.entityId}]");

    this.registerAction.setToLoading();
    this.isRegistered.setToLoading();
    this.visibleActions.setToLoading();

    try {
      await Future.wait(this
          .metadata
          .value
          .actions
          .map((action) async {
            if (action.type == "register") {
              await _isActionVisible(action, this.reference.entityId)
                  .then((visible) {
                if (!(visible is bool)) throw Exception();
                this.isRegistered.setValue(!visible);
                this.registerAction.setValue(action);
              }).catchError((err) {
                // capture the error locally
                this
                    .registerAction
                    .setError("Could not load the register status");
                this
                    .isRegistered
                    .setError("Could not load the register status");
              });
              // final status = await registrationStatus(
              //     this.reference.entityId, dvoteGw, privateKey);
              // this.isRegistered.setValue(status["registered"] == true);
            } else {
              // standard action
              // in case of error: propagate to the global catcher
              final isVisible =
                  await _isActionVisible(action, this.reference.entityId)
                      .catchError((_) => false);
              if (isVisible) visibleStandardActions.add(action);
            }
          })
          .cast<Future>()
          .toList());

      logger.log("- [Entity actions] Loading [DONE] [${reference.entityId}]");

      this.visibleActions.setValue(visibleStandardActions);
    } catch (err) {
      logger.log(
          "- [Entity actions] Loading [ERROR: $err] [${reference.entityId}]");

      // NOTE: leave the comment to force parsing the i18n string
      // The Widget painting this string will need to use getText() with it
      // getText(ctx, "error.couldNotFetchTheEntityDetails")
      this.visibleActions.setError("error.couldNotFetchTheEntityDetails");

      // The request fails entirely. Keep values if already present
      if (this.registerAction.isLoading) {
        // getText(ctx, "error.couldNotFetchTheEntityDetails")
        this.registerAction.setError("error.couldNotLoadTheRegistrationEtatus");
      }
      if (this.isRegistered.isLoading) {
        // getText(ctx, "error.couldNotFetchTheEntityDetails")
        this.isRegistered.setError("error.couldNotLoadTheRegistrationEtatus");
      }
      throw err;
    }
  }

  /// Sends a request to receive notifications for the given entity.
  /// It also stores a key/value to remember the active subscription.
  Future<void> enableNotifications() async {
    if (!metadata.hasValue)
      throw Exception("The model has no metadata yet");
    else if (Globals.appState.currentAccount == null)
      throw Exception("No account selected yet");

    try {
      notificationTopics.loading = true;

      final accountAddr =
          Globals.appState.currentAccount.identity.value.keys[0].rootAddress;

      String key, topic;
      await Future.wait(
          Notifications.supportedNotificationEvents.map((element) {
        key = Notifications.getMetaKeyForAccount(accountAddr, element);
        topic = Notifications.getTopicForEntity(reference.entityId, element);

        metadata.value.meta[key] = "yes";
        return Notifications.subscribe(topic);
      }));

      notificationTopics.value = null;
      metadata.notifyChange();
      Globals.entityPool.writeToStorage();
    } catch (err) {
      notificationTopics.error = err.toString();
      throw Exception("Could not subscribe to the entity's topic");
    }
  }

  /// Removes the active account from the entity's notification subscribers.
  /// If no other account wants notifications from the entity, a request is made to stop receiving them at all.
  Future<void> disableNotifications() async {
    if (!metadata.hasValue)
      throw Exception("The model has no metadata yet");
    else if (Globals.appState.currentAccount == null)
      throw Exception("No account selected yet");

    try {
      notificationTopics.loading = true;

      final accountAddr =
          Globals.appState.currentAccount.identity.value.keys[0].rootAddress;

      // Check if other identities are also registered
      String key, topic;
      final topicsToPreserve = <String>[];
      for (final existingAccount in Globals.accountPool.value) {
        if (!existingAccount.identity.hasValue ||
            !existingAccount.entities.hasValue ||
            existingAccount.identity.value.keys.length == 0)
          continue;
        // skip ourselves
        else if (existingAccount.identity.value.keys[0].rootAddress ==
            accountAddr) continue;

        // does he/she has notifications enabled?
        Notifications.supportedNotificationEvents.forEach((event) {
          key = Notifications.getMetaKeyForAccount(accountAddr, event);
          if (metadata.value.meta.containsKey(key) &&
              metadata.value.meta[key] == "yes") {
            topic = Notifications.getTopicForEntity(reference.entityId, event);
            topicsToPreserve.add(topic);
          }
        });
      }

      // Remove notifications for the entity topics that nobody else wants
      await Future.wait(Notifications.supportedNotificationEvents.map((event) {
        // Remove the topic annotation for the user
        key = Notifications.getMetaKeyForAccount(accountAddr, event);
        metadata.value.meta[key] = "no";

        // Skip if someone else still wants to be notified
        topic = Notifications.getTopicForEntity(reference.entityId, event);
        if (topicsToPreserve.contains(topic)) return Future.value(); // keep

        return Notifications.unsubscribe(topic);
      }));

      notificationTopics.value = null; // repaint the UI
      metadata.notifyChange(); // repaint the UI

      Globals.entityPool.writeToStorage();
    } catch (err) {
      print(err);
      notificationTopics.error = err.toString();
      throw Exception("Could not unsubscribe from the entity's topic");
    }
  }

  /// Determines whether the current account has push notifications enabled for the entity
  bool hasNotificationsEnabled() {
    if (!metadata.hasValue)
      return false;
    else if (Globals.appState.currentAccount == null) return false;

    final accountAddr =
        Globals.appState.currentAccount.identity.value.keys[0].rootAddress;
    final key = Notifications.getMetaKeyForAccount(
      accountAddr,
      Notifications.supportedNotificationEvents[0],
    );
    if (!metadata.value.meta.containsKey(key)) metadata.value.meta[key] = "yes";
    return metadata.value.meta[key] == "yes";
  }

  /// Cleans the ephemeral state of the entity related to an account
  @override
  void cleanEphemeral() {
    if (this.processes.hasValue)
      this.processes.value.forEach((process) => process.cleanEphemeral());

    this.visibleActions.setValue(null);
    this.registerAction.setValue(null);
    this.isRegistered.setValue(null);

    this.actionVisibilityCheckSignature = null;
    this.actionVisibilityTimestampUsed = null;
  }

  // PRIVATE METHODS

  // TODO: DEPRECATED

  /// Returns true/false if the value is defined or the request succeeds. Returns null if the request
  /// can't be signed or the response is otherwise undefined.
  ///
  @deprecated
  Future<bool> _isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    // Hardcoded value
    if (action.visible == "always")
      return true;
    else if (!(action.visible is String) || action.visible == "false")
      return false;

    // OTHERWISE => the `visible` field is expected to be a URL

    if (actionVisibilityCheckSignature == null ||
        actionVisibilityTimestampUsed == null) return null;

    try {
      final Map<String, dynamic> payload = {
        "request": {
          "method": "getVisibility",
          "actionKey": action.actionKey,
          "entityId": entityId,
          "timestamp": actionVisibilityTimestampUsed
        },
        "signature": actionVisibilityCheckSignature
      };

      final Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await http.post(action.visible,
          body: jsonEncode(payload), headers: headers);
      if (!(response.body is String)) throw Exception("Invalid response");

      final body = jsonDecode(response.body);
      if (!(body is Map))
        throw Exception("Invalid response");
      else if (!(body["response"] is Map))
        throw Exception("Invalid response");
      else if (response.statusCode != 200 ||
          body["response"]["error"] is String ||
          body["response"]["ok"] != true)
        throw Exception(body["response"]["error"] ?? "Invalid response");
      else if (body["response"]["visible"] is bool)
        return body["response"]["visible"];
    } catch (err) {
      logger.log("Action visibility error: $err");
      throw err;
    }

    return false;
  }

  // STATIC HELPERS

  /// Returns the EntityModel instance corresponding to the given reference
  /// only if it already belongs to the pool. You need to fetch it otherwise.
  static getFromPool(EntityReference entityRef) {
    if (!Globals.entityPool.hasValue) return null;
    return Globals.entityPool.value.firstWhere((entityModel) {
      return entityModel.reference.entityId == entityRef.entityId;
    }, orElse: () => null);
  }

  /// Gets a filtered list of current process models belonging to the given entity
  static List<ProcessModel> getProcessesForEntity(String entityId) {
    return Globals.processPool.value
        .where((processModel) =>
            processModel.metadata.hasValue &&
            processModel.metadata.value.meta[META_ENTITY_ID] == entityId)
        .cast<ProcessModel>()
        .toList();
  }

  /// Creates a list of Process Model's from the metadata currently persisted that
  /// belongs to the given entity
  static List<ProcessModel> getProcessesPersistedForEntity(String entityId) {
    return Globals.processesPersistence
        .get()
        .where((procMeta) => procMeta.meta[META_ENTITY_ID] == entityId)
        .map((procMeta) {
          return ProcessModel.fromMetadata(procMeta,
              procMeta.meta[META_PROCESS_ID], procMeta.meta[META_ENTITY_ID]);
        })
        .cast<ProcessModel>()
        .toList();
  }

  static Feed getFeedForEntity(String entityId) {
    return Globals.feedPool.value.firstWhere(
        (feed) => feed.meta[META_ENTITY_ID] == entityId,
        orElse: () => null);
  }
}
