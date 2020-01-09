import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/state-value.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// EntityPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class EntityPoolModel extends StateModel<List<EntityModel>> {
  EntityPoolModel() {
    this.setValue(List<EntityModel>());
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
      final entityMetadataList = globalEntitiesPersistence.get();
      final entityModelList = entityMetadataList
          .map((entityMeta) {
            // READ INDIRECT MODELS
            final procsModels =
                EntityModel.getPersistedProcessesForEntity(entityMeta);
            final feedModel = EntityModel.getPersistedFeedForEntity(entityMeta);

            return EntityModel(entityMeta, procsModels, feedModel);
          })
          .cast<EntityModel>()
          .toList();
      this.setValue(entityModelList);
      // notifyListeners(); // Not needed => `setValue` already does it
    } catch (err) {
      if (!kReleaseMode) print(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
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
          .map((entityModel) => entityModel.value.metadata)
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
    try {
      final myEntities = List<EntityModel>();
      // TODO: Get a filtered EntityModel list of the Entities of the current user

      // This will call `setValue` on the individual models already within the pool.
      // No need to rebuild an updated pool list.
      await Future.wait(
          myEntities.map((entityModel) => entityModel.refresh()).toList());

      await this.writeToStorage();
      // notifyListeners(); // Not needed => `setValue` already does it on every model
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw err;
    }
  }
}

/// EntityModel encapsulates the relevant information of a Vocdoni Entity.
/// This includes its metadata and the participation processes.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class EntityModel extends StateModel<EntityState> {
  EntityModel(EntityMetadata meta, List<ProcessModel> procs, FeedModel feed) {
    final newValue = EntityState();
    newValue.metadata.setValue(meta);
    newValue.processes.setValue(procs);
    newValue.newsFeed.setValue(feed);
    this.setValue(newValue);
  }

  @override
  Future<void> refresh() async {
    // TODO: Get the IPFS hash
    // TODO: Don't refetch if the IPFS hash is the same
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    // TODO: Force a write() to persistence if changed
  }

  // STATIC HELPERS

  static List<ProcessModel> getPersistedProcessesForEntity(
      EntityMetadata meta) {
    return globalProcessesPersistence
        .get()
        .where((procMeta) {
          // TODO: FILTER BY ENTITY ID
          return true;
        })
        .map((procMeta) => ProcessModel(procMeta))
        .cast<ProcessModel>()
        .toList();
  }

  static FeedModel getPersistedFeedForEntity(EntityMetadata meta) {
    final feedData = globalFeedPersistence.get().firstWhere((feed) {
      // TODO: FILTER BY ENTITY ID IN META
      return true;
    }, orElse: null);
    return FeedModel(feedData);
  }
}

// Use this class as a data container only. Any logic that updates the state
// should be defined above in the model class
class EntityState {
  final StateValue<EntityMetadata> metadata = StateValue<EntityMetadata>();
  final StateValue<List<ProcessModel>> processes =
      StateValue<List<ProcessModel>>();
  final StateValue<FeedModel> newsFeed = StateValue<FeedModel>();
}
