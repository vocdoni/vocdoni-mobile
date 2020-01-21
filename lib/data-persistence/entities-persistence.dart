import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";

final String _storageFile = ENTITIES_STORE_FILE;

class EntitiesPersistence extends BasePersistenceList<EntityMetadata> {
  @override
  Future<List<EntityMetadata>> readAll() async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return [];
      }

      final bytes = await fd.readAsBytes();
      final store = EntityMetadataStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw RestoreError("There was an error while reading the local data");
    }
  }

  @override
  Future<void> writeAll(List<EntityMetadata> value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      final store = EntityMetadataStore();
      store.items.addAll(value);
      await fd.writeAsBytes(store.writeToBuffer());

      // Update the in-memory current value
      set(value);
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw PersistError("There was an error while storing the changes");
    }
  }
}
