import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-notifier.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// FeedPool tracks all the registered account's feeds and provides individual instances.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
///
class FeedPool extends StateNotifier<List<Feed>> implements StatePersistable {
  FeedPool() {
    this.load(List<Feed>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.load(List<Feed>());

    try {
      this.setToLoading();
      final feedList = globalFeedPersistence
          .get()
          .where((feed) =>
              feed.meta[META_ENTITY_ID] is String &&
              feed.meta[META_FEED_CONTENT_URI] is String)
          .cast<Feed>()
          .toList();
      this.setValue(feedList);
      // notifyListeners(); // Not needed => `setValue` already does it
    } catch (err) {
      devPrint(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.load(List<Feed>());

    try {
      final feedList = this
          .value
          .where((feed) {
            if (!(feed is Feed))
              return false;
            else if (!(feed.meta[META_ENTITY_ID] is String) ||
                !(feed.meta[META_FEED_CONTENT_URI] is String)) return false;
            return true;
          })
          .cast<Feed>()
          .toList();
      await globalFeedPersistence.writeAll(feedList);
    } catch (err) {
      devPrint(err);
      throw PersistError("Cannot store the current state");
    }
  }

  // HELPERS

  /// Returns the news feed from a given entity. If no language is provided
  /// then the first matching feed by the entity Id is returned.
  Feed getFromEntityId(String entityId, [String language]) {
    if (!this.hasValue) return null;

    return this.value.firstWhere((feed) {
      if (!(feed is Feed)) return false;

      bool matching = feed.meta[META_ENTITY_ID] == entityId;

      if (language is String) {
        bool isSameLanguage = feed.meta[META_LANGUAGE] == language;
        return matching && isSameLanguage;
      }
      return matching;
    }, orElse: () => null);
  }

  /// Removes the given feed from the pool and persists the new pool.
  Future<void> remove(Feed feed) async {
    if (!this.hasValue) throw Exception("The pool has no value yet");

    final updatedList = this
        .value
        .where((existingFeed) =>
            existingFeed.meta[META_FEED_CONTENT_URI] !=
            feed.meta[META_FEED_CONTENT_URI])
        .cast<Feed>()
        .toList();
    this.setValue(updatedList);

    await this.writeToStorage();
  }
}
