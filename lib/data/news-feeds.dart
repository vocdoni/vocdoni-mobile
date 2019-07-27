import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "dart:convert";
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:dvote/dvote.dart';

const NEWS_FEEDS_KEY_PREFIX = "news-feeds/"; // + organization.entityId

/// STORAGE STRUCTURE
/// - SharedPreferences > "news-feeds/{organization-id}/{lang}" => "{...JSON-Feed...}"

/// STREAM DATA STRUCTURE
/// - Data > Map[organization-id] > Map[lang] > Feed

/// Provides a Business Logic Component to store and consume data related to the news feeds
/// of the subscribed organizations
class NewsFeedsBloc {
  BehaviorSubject<Map<String, Map<String, Feed>>> _state =
      BehaviorSubject<Map<String, Map<String, Feed>>>.seeded(
          Map<String, Map<String, Feed>>());

  Observable<Map<String, Map<String, Feed>>> get stream => _state.stream;
  Map<String, Map<String, Feed>> get current => _state.value;

  Future restore() {
    return readState();
  }

  /// Read the state stored as JSON text and emit the decoded class instances
  Future readState() async {
    // Read and construct the data structures

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<EntitySummary> allOrgs = List<EntitySummary>();
    Map<String, Map<String, Feed>> allFeeds =
        Map<String, Map<String, Feed>>();
    if (identitiesBloc.current == null) return;

    // Unique list
    identitiesBloc.current.forEach((ident) {
      allOrgs.forEach((org) {
        if (allOrgs.indexWhere((o) => o.entityId == org.entityId) < 0) {
          allOrgs.add(org);
        }
      });
      allOrgs.addAll(ident.subscribedEntities);
    });

    // Arrange info
    allOrgs.forEach((org) {
      allFeeds[org.entityId] = Map<String, Feed>();
      org.languages.forEach((lang) {
        final str =
            prefs.getString(NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang");
        if (str == null) return;
        final feed = Feed.fromJson(jsonDecode(str));
        allFeeds[org.entityId][lang] = feed;
      });
    });

    _state.add(allFeeds);
  }

  /// Fetch the news feeds of the given organization and update their entries
  /// on the shared storage
  Future<Map<String, Feed>> fetchEntityFeeds(Entity org) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (org.languages == null || org.languages.length < 1)
      return Map<String, Feed>();

    final Map<String, String> strFeeds = {};
    final Map<String, Feed> orgFeeds = {};
    await Future.wait(org.languages.map((lang) async {
      final strFeed = await fetchEntityNewsFeed(org, lang);
      if (strFeed != null) {
        strFeeds[lang] = strFeed;
        orgFeeds[lang] = Feed.fromJson(jsonDecode(strFeed));
      } else {
        orgFeeds[lang] = Feed.fromJson("{}");
      }
      await prefs.setString(
          NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang", strFeed);
    }));

    await readState();

    return orgFeeds;
  }
}
