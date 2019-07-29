import 'package:rxdart/rxdart.dart';
import "dart:io";
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/data/generic.dart';

/// Provides a Business Logic Component to store and consume data related to the news feeds
/// of the subscribed organizations
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
    FeedStore store;

    try {
      fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set([]);
        return;
      }
    } catch (err) {
      print(err);
      set([]);
      throw "There was an error while accessing the local data";
    }

    try {
      final bytes = await fd.readAsBytes();
      store = FeedStore.fromBuffer(bytes);
      set(store.feeds);
    } catch (err) {
      print(err);
      set([]);
      throw "There was an error processing the local data";
    }
  }

  @override
  Future<void> persist() async {
    // Gateway boot nodes
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      FeedStore store = FeedStore();
      store.feeds.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw "There was an error while storing the changes";
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  void set(List<Feed> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  // /// Read the state stored as JSON text and emit the decoded class instances
  // Future readState() async {
  //   // Read and construct the data structures

  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   List<EntitySummary> allOrgs = List<EntitySummary>();
  //   Map<String, Map<String, Feed>> allFeeds = Map<String, Map<String, Feed>>();
  //   if (identitiesBloc.current == null) return;

  //   // Unique list
  //   identitiesBloc.current.forEach((ident) {
  //     allOrgs.forEach((org) {
  //       if (allOrgs.indexWhere((o) => o.entityId == org.entityId) < 0) {
  //         allOrgs.add(org);
  //       }
  //     });
  //     allOrgs.addAll(ident.subscribedEntities);
  //   });

  //   // Arrange info
  //   allOrgs.forEach((org) {
  //     allFeeds[org.entityId] = Map<String, Feed>();
  //     org.languages.forEach((lang) {
  //       final str =
  //           prefs.getString(NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang");
  //       if (str == null) return;
  //       final feed = Feed.fromJson(jsonDecode(str));
  //       allFeeds[org.entityId][lang] = feed;
  //     });
  //   });

  //   _state.add(allFeeds);
  // }

  // /// Fetch the news feeds of the given organization and update their entries
  // /// on the shared storage
  // Future<Map<String, Feed>> fetchEntityFeeds(Entity org) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (org.languages == null || org.languages.length < 1)
  //     return Map<String, Feed>();

  //   final Map<String, String> strFeeds = {};
  //   final Map<String, Feed> orgFeeds = {};
  //   await Future.wait(org.languages.map((lang) async {
  //     final strFeed = await fetchEntityNewsFeed(org, lang);
  //     if (strFeed != null) {
  //       strFeeds[lang] = strFeed;
  //       orgFeeds[lang] = Feed.fromJson(jsonDecode(strFeed));
  //     } else {
  //       orgFeeds[lang] = Feed.fromJson("{}");
  //     }
  //     await prefs.setString(
  //         NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang", strFeed);
  //   }));

  //   await readState();

  //   return orgFeeds;
  // }
}
