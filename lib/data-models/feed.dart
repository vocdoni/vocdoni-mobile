import 'package:dvote/dvote.dart';
import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/state-base.dart';
import 'package:vocdoni/lib/state-notifier.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// FeedPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateContainer or StateNotifier.
///
class FeedPoolModel extends StateNotifier<List<FeedModel>>
    implements StatePersistable, StateRefreshable {
  FeedPoolModel() {
    this.load(List<FeedModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.load(List<FeedModel>());

    try {
      this.setToLoading();
      final feedList = globalFeedPersistence.get();
      final feedModelList = feedList
          .where((feedMeta) =>
              feedMeta.meta[META_ENTITY_ID] is String &&
              feedMeta.meta[META_FEED_CONTENT_URI] is String)
          .map((feedMeta) => FeedModel(feedMeta.meta[META_FEED_CONTENT_URI],
              feedMeta.meta[META_ENTITY_ID], feedMeta))
          .cast<FeedModel>()
          .toList();
      this.setValue(feedModelList);
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
    if (!hasValue) this.load(List<FeedModel>());

    try {
      final feedList = this
          .value
          .where((feedModel) => feedModel.feed.hasValue)
          .map((feedModel) {
            // COPY STATE FIELDS INTO META
            final val = feedModel.feed.value;
            val.meta[META_ENTITY_ID] = feedModel.entityId ?? "";
            val.meta[META_FEED_CONTENT_URI] = feedModel.contentUri ?? "";
            return val;
          })
          .cast<Feed>()
          .toList();
      await globalFeedPersistence.writeAll(feedList);
    } catch (err) {
      devPrint(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh([bool force = false]) async {
    if (!hasValue ||
        globalAppState.currentAccount == null ||
        !globalAppState.currentAccount.entities.hasValue) return;

    try {
      // Get a filtered list of the Entities of the current user
      final entityIds = globalAppState.currentAccount.entities.value
          .map((entity) => entity.reference.entityId)
          .toList();

      // This will call `setValue` on the individual models that are already within the pool.
      // No need to update the pool list itself.
      await Future.wait(this
          .value
          .where((feedModel) => entityIds.contains(feedModel.entityId))
          .map((feedModel) => feedModel.refresh(force))
          .toList());

      await this.writeToStorage();
    } catch (err) {
      devPrint(err);
      throw err;
    }
  }

  // HELPERS

  /// Returns the news feed from a given entity. If no language is provided
  /// then the first matching feed by the entity Id is returned.
  FeedModel getFromEntityId(String entityId, [String language]) {
    return this.value.firstWhere((feedModel) {
      if (!feedModel.feed.hasValue) return false;

      bool isFromEntity = feedModel.feed.value.meta[META_ENTITY_ID] == entityId;

      if (language is String) {
        bool isSameLanguage =
            feedModel.feed.value.meta[META_LANGUAGE] == language;
        return isFromEntity && isSameLanguage;
      } else {
        return isFromEntity;
      }
    }, orElse: () => null);
  }

  /// Removes the given feed from the pool and persists the new pool.
  Future<void> remove(FeedModel feedModel) async {
    if (!this.hasValue) throw Exception("The pool has no value yet");

    final updatedValue = this
        .value
        .where(
            (existingFeed) => existingFeed.contentUri != feedModel.contentUri)
        .cast<FeedModel>()
        .toList();
    this.setValue(updatedValue);

    await this.writeToStorage();
  }
}

/// FeedModel encapsulates the relevant information of a Vocdoni Feed.
/// This includes its metadata and the participation processes.
///
/// IMPORTANT: **Updates** on the own state must call `notifyListeners()` or use `setXXX()`.
/// Updates on the children models will be notified by the objects themselves if using StateContainer or StateNotifier.
///
class FeedModel implements StateRefreshable {
  final String contentUri;
  final String entityId;
  final String lang = "default";
  final StateNotifier<Feed> feed = StateNotifier<Feed>();

  FeedModel(this.contentUri, this.entityId, [Feed feed]) {
    if (feed is Feed) this.feed.load(feed);
  }

  static FeedModel fromFeed(Feed feed) {
    if (!(feed is Feed)) return null;
    return FeedModel(
        feed.meta[META_FEED_CONTENT_URI], feed.meta[META_ENTITY_ID], feed);
  }

  @override
  Future<void> refresh([bool force = false]) async {
    if (!force && this.feed.isFresh)
      return;
    else if (!force && this.feed.isLoading) return;

    // TODO: Don't refetch if the IPFS hash is the same

    try {
      final dvoteGw = getDVoteGateway();
      final ContentURI cUri = ContentURI(contentUri);

      final result = await fetchFileString(cUri, dvoteGw);
      final Feed feed = parseFeed(result);
      feed.meta[META_FEED_CONTENT_URI] = contentUri;
      feed.meta[META_ENTITY_ID] = entityId;
      feed.meta[META_LANGUAGE] = lang;

      this.feed.setValue(feed);
    } catch (err) {
      devPrint(err);
      this.feed.setError("Unable to fetch the news feed");
    }
  }
}
