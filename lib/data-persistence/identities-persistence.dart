import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";

final String _storageFile = IDENTITIES_STORE_FILE;

class IdentitiesPersistence extends BasePersistence<Identity> {
  @override
  Future<List<Identity>> readAll() async {
    await super.init();

    try {
      final File fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return [];
      }

      final bytes = await fd.readAsBytes();
      final IdentitiesStore store = IdentitiesStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      if (!kReleaseMode) print(err);
      throw RestoreError("There was an error while reading the local data");
    }
  }

  @override
  Future<void> writeAll(List<Identity> value) async {
    await super.init();

    try {
      File fd = File("${storageDir.path}/$_storageFile");
      IdentitiesStore store = IdentitiesStore();
      store.items.addAll(value);
      await fd.writeAsBytes(store.writeToBuffer());

      // Update the in-memory current value
      set(value);
    } catch (err) {
      print(err);
      throw PersistError("There was an error while storing the changes");
    }
  }
}
