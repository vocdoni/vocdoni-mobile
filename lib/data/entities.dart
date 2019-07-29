import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      state.add([]);
      throw "There was an error while accessing the local data";
    }

    try {
      final bytes = await fd.readAsBytes();
      store = EntitiesStore.fromBuffer(bytes);
      state.add(store.entities);
    } catch (err) {
      print(err);
      throw "There was an error processing the local data";
    }
  }

  @override
  Future<void> persist() async {
    // Gateway boot nodes
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      EntitiesStore store = EntitiesStore();
      store.entities.addAll(state.value);
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
}
