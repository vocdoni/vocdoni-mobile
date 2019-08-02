import "dart:io";
import "dart:async";

// import 'package:vocdoni/util/singletons.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/util/api.dart';
import 'package:dvote/dvote.dart';
import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/data/generic.dart';

/// Provides a Business Logic Component to store and consume data related to the news feeds
/// of the subscribed entities
class NewsFeedsBloc extends BlocComponent<List<Feed>> {
  final String _storageFile = NEWSFEED_STORE_FILE;

  NewsFeedsBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    File fd;
    FeedsStore store;

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
      store = FeedsStore.fromBuffer(bytes);
      state.add(store.items);
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
      FeedsStore store = FeedsStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw FlutterError("There was an error while storing the changes");
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<Feed> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  /// Fetch the feeds of the given entity and update their entries
  /// on the local storage
  Future<void> fetchFromEntity(Entity entity) async {
    if (entity.languages == null || entity.languages.length < 1) return;
    final feeds = current;

    await Future.wait(entity.languages.map((lang) async {
      final strFeed = await fetchEntityNewsFeed(entity, lang);
      final newFeed = parseFeed(strFeed);
      newFeed.meta["entityId"] = entity.entityId; // metadata
      newFeed.meta["language"] = lang;

      final alreadyIdx = feeds.indexWhere((feed) =>
          feed.meta["entityId"] == entity.entityId && // metadata
          feed.meta["language"] == lang);
      if (alreadyIdx >= 0) {
        // Update existing
        feeds[alreadyIdx] = newFeed;
      } else {
        // Add
        feeds.add(newFeed);
      }
    }));

    await set(feeds);
  }
}
