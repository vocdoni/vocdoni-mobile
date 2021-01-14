import 'dart:io';
import 'package:dvote/dvote.dart';

import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";
import 'package:vocdoni/lib/logger.dart';

final String _storageFile = IDENTITIES_STORE_FILE;

class IdentitiesPersistence extends BasePersistenceList<Identity> {
  @override
  Future<List<Identity>> readAll() async {
    await super.init();

    try {
      final File fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set([]);
        return value;
      }

      final bytes = await fd.readAsBytes();
      final store = IdentitiesStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      logger.log(err);
      throw RestoreError("There was an error while reading the local data");
    }
  }

  @override
  Future<void> writeAll(List<Identity> value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      final store = IdentitiesStore();
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
