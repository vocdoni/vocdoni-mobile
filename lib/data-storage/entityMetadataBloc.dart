import 'dart:io';
import 'package:vocdoni/data-storage/genericBloc.dart';
import "dart:async";
import 'package:dvote/dvote.dart';
import "package:vocdoni/constants/meta-keys.dart";

class EntityMetadataBloc extends GenericBloc<List<EntityMetadata>> {
  final String _storageFile = ENTITIES_STORE_FILE;

  EntityMetadataBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    EntityMetadataStore store;

    try {
      fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return;
      }
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while accessing the local data");
    }

    try {
      final bytes = await fd.readAsBytes();
      store = EntityMetadataStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while processing the local data");
    }
  }

  @override
  Future<void> persist() async {
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      EntityMetadataStore store = EntityMetadataStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw BlocPersistError("There was an error while storing the changes");
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<EntityMetadata> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  Future<void> add(
      EntityMetadata entityMetadata, EntityReference entitySummary) async {
    final currentIndex = value
        .indexWhere((e) => e.meta[META_ENTITY_ID] == entitySummary.entityId);
    // Already exists
    if (currentIndex >= 0) {
      final currentEntities = value;
      currentEntities[currentIndex] = entityMetadata;
      await set(currentEntities);
    } else {
      value.add(entityMetadata);
      await set(value);
    }
  }

  Future<void> remove(String entityIdToRemove) async {
    final entities = value;
    entities.removeWhere((existingEntity) =>
        existingEntity.meta[META_ENTITY_ID] == entityIdToRemove);

    await set(entities);

    //TODO remove feed from newsFeedBloc
  }

  /*Future<void> refreshFrom(List<EntityReference> entities) async {
    // TODO:
    print("Unimplemented: entities > refreshFrom");
  }*/
}
