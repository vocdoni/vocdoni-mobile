import "dart:io";
import "dart:async";
import 'package:dvote/dvote.dart';
import 'package:vocdoni/data-storage/genericBloc.dart';
import "package:vocdoni/constants/meta-keys.dart";

/// Provides a Business Logic Component to store and consume data related to the news feeds
/// of the subscribed entities
class FeedBloc extends GenericBloc<List<Feed>> {
  final String _storageFile = NEWSFEED_STORE_FILE;

  FeedBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    FeedStore store;

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
      store = FeedStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while processing the local data");
    }
  }

  @override
  Future<void> persist() async {
    // Gateway boot nodes
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      FeedStore store = FeedStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw BlocPersistError("There was an error while storing the changes");
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<Feed> data) async {
    super.set(data);
    await persist();
  }

  Future<void> add(
      String language, Feed feed, EntityReference entitySummary) async {
    
    final currentIndex = value.indexWhere((f) =>
        f.meta[META_ENTITY_ID] == entitySummary.entityId &&
        f.meta[META_LANGUAGE] == language);

    // Already exists
    if (currentIndex >= 0) {
      final currentFeeds = value;
      currentFeeds[currentIndex] = feed;
      await set(currentFeeds);
    } else {
      value.add(feed);
      await set(value);
    }
  }
}
