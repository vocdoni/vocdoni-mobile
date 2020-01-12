import 'package:dvote/dvote.dart';
import 'package:vocdoni/constants/meta-keys.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/lib/singletons.dart';

/// This class should be used exclusively as a global singleton via MultiProvider.
/// FeedPoolModel tracks all the registered accounts and provides individual models that
/// can be listened to as well.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class FeedPoolModel extends StateModel<List<FeedModel>> {
  FeedPoolModel() {
    this.setValue(List<FeedModel>());
  }

  // EXTERNAL DATA HANDLERS

  /// Read the global collection of all objects from the persistent storage
  @override
  Future<void> readFromStorage() async {
    if (!hasValue) this.setValue(List<FeedModel>());

    try {
      this.setToLoading();
      final feedList = globalFeedPersistence.get();
      final feedModelList = feedList
          .map((feed) => FeedModel(feed))
          .cast<FeedModel>()
          .toList();
      this.setValue(feedModelList);
      // notifyListeners(); // Not needed => `setValue` already does it
    } catch (err) {
      print(err);
      this.setError("Cannot read the boot nodes list", keepPreviousValue: true);
      throw RestoreError("There was an error while accessing the local data");
    }
  }

  /// Write the given collection of all objects to the persistent storage
  @override
  Future<void> writeToStorage() async {
    if (!hasValue) this.setValue(List<FeedModel>());

    try {
      final feedList = this
          .value
          .where((feedModel) => feedModel.hasValue)
          .map((feedModel) => feedModel.value)
          .cast<Feed>()
          .toList();
      await globalFeedPersistence.writeAll(feedList);
    } catch (err) {
      print(err);
      throw PersistError("Cannot store the current state");
    }
  }

  @override
  Future<void> refresh() {
    throw Exception(
        "Call refresh() on the individual models instead of the global list");
  }

  // HELPERS

  /// Returns the news feed from a given entity. If no language is provided
  /// then the first matching feed by the entity Id is returned.
  FeedModel getFromEntityId(String entityId, [String language]) {
    return this.value.firstWhere((feed) {
      if(!feed.hasValue) return false;

      bool isFromEntity =
          feed.value.meta[META_ENTITY_ID] == entityId;
      
      if(language is String) {
        bool isSameLanguage =
            feed.value.meta[META_LANGUAGE] == language;
        return isFromEntity && isSameLanguage;
      }
      else {
        return isFromEntity;
      }
    }, orElse: () => null);
  }
}

/// FeedModel encapsulates the relevant information of a Vocdoni Feed.
/// This includes its metadata and the participation processes.
///
/// IMPORTANT: Any **updates** on the own state must call `notifyListeners()` or use `setValue()`.
/// Updates on the children models will be handled by the object itself.
///
class FeedModel extends StateModel<Feed> {
  FeedModel(Feed value) {
    this.setValue(value);
  }

  @override
  Future<void> refresh() async {
    // TODO: Implement refetch of the metadata
    // TODO: Check the last time that data was fetched
    // TODO: Don't refetch if the IPFS hash is the same

    this.setToLoading();
    try {
      await fetchEntityFeed(
          this.entityReference, this.entityMetadata.value, this.lang)
      this.setValue(newValue);
    } catch (error) {
      this.setError("Unable to fetch the news feed");
    }
  }
}
