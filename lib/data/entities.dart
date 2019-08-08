import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocdoni/data/generic.dart';
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
import 'package:dvote/dvote.dart';

class EntitiesBloc extends BlocComponent<List<Entity>> {
  final String _storageFile = ENTITIES_STORE_FILE;

  EntitiesBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    EntitiesStore store;

    try {
      fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return;
      }
    } catch (err) {
      print(err);
      throw "There was an error while accessing the local data";
    }

    try {
      final bytes = await fd.readAsBytes();
      store = EntitiesStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw "There was an error processing the local data";
    }
  }

  @override
  Future<void> persist() async {
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      EntitiesStore store = EntitiesStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw "There was an error while storing the changes";
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<Entity> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  Future<void> add(Entity newEntity) async {
    if (!(newEntity is Entity))
      throw FlutterError("The entity parameter is invalid");

    final currentIndex =
        current.indexWhere((e) => e.entityId == newEntity.entityId);
    // Already exists
    if (currentIndex >= 0) {
      final currentEntities = current;
      currentEntities[currentIndex] = newEntity;
      await set(currentEntities);
    } else {
      current.add(newEntity);
      await set(current);

      // Fetch the news feeds if needed
      await newsFeedsBloc.fetchFromEntity(newEntity);
    }
  }

  Future<void> remove(String entityIdToRemove) async {
    final entities = current;
    entities.removeWhere(
        (existingEntity) => existingEntity.entityId == entityIdToRemove);

    await set(entities);

    //TODO remove feed from newsFeedBloc
  }

  Future<void> refreshFrom(List<EntitySummary> entities) async {
    // TODO:
    print("Unimplemented: entities > refreshFrom");
  }
}
