import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";

final String _storageFile = NEWSFEED_STORE_FILE;

class NewsFeedPersistence extends BasePersistenceList<Feed> {
  @override
  Future<List<Feed>> readAll() async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set([]);
        return value;
      }

      final bytes = await fd.readAsBytes();
      final store = FeedStore.fromBuffer(bytes);

      // Update the in-memory current value
      set(store.items);

      return store.items;
    } catch (err) {
      logger.log(err);
      throw RestoreError(
          "There was an error while reading the local feed data");
    }
  }

  @override
  Future<void> writeAll(List<Feed> value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      final store = FeedStore();
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
      final fd = File("${storageDir.path}/$OLD_NEWSFEED_STORE_FILE");
      await fd.delete();
      logger.log("Erased legacy newsfeed file");
    } catch (_) {}
  }
}
