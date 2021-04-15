import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";

final String _storageFile = PROCESSES_STORE_FILE;

class ProcessesPersistence extends BasePersistenceList<ProcessMetadata> {
  @override
  Future<List<ProcessMetadata>> readAll() async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set([]);
        return value;
      }

      final bytes = await fd.readAsBytes();
      final store = ProcessMetadataStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      logger.log(err);
      throw RestoreError(
          "There was an error while reading the local process data");
    }
  }

  @override
  Future<void> writeAll(List<ProcessMetadata> value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      final store = ProcessMetadataStore();
      store.items.addAll(value);
      await fd.writeAsBytes(store.writeToBuffer());

      // Update the in-memory current value
      set(value);
    } catch (err) {
      logger.log(err);
      throw PersistError("There was an error while storing the changes");
    }
  }

  Future<void> eraseLegacyFile() async {
    try {
      final fd = File("${storageDir.path}/$OLD_PROCESSES_STORE_FILE");
      await fd.delete();
      logger.log("Erased legacy processes file");
    } catch (_) {}
  }
}
