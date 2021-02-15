import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/logger.dart';
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
        set([]);
        return value;
      }

      final bytes = await fd.readAsBytes();
      final store = EntityMetadataStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      logger.log(err);
      throw RestoreError(
          "There was an error while reading the local entity data");
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
      logger.log(err);
      throw PersistError("There was an error while storing the changes");
    }
  }
}
