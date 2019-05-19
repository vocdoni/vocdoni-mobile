import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "dart:convert";
import "dart:async";

import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';

const NEWS_FEEDS_KEY_PREFIX = "news-feeds/"; // + organization.entityId

/// STORAGE STRUCTURE
/// - SharedPreferences > "news-feeds/{organization-id}/{lang}" => "{...JSON-Feed...}"

/// STREAM DATA STRUCTURE
/// - Data > Map[organization-id] > Map[lang] > NewsFeed

/// Provides a Business Logic Component to store and consume data related to the news feeds
/// of the subscribed organizations
class NewsFeedsBloc {
  BehaviorSubject<Map<String, Map<String, NewsFeed>>> _state =
      BehaviorSubject<Map<String, Map<String, NewsFeed>>>.seeded(
          Map<String, Map<String, NewsFeed>>());

  Observable<Map<String, Map<String, NewsFeed>>> get stream => _state.stream;
  Map<String, Map<String, NewsFeed>> get current => _state.value;

  Future restore() {
    return readState();
  }

  /// Read the state stored as JSON text and emit the decoded class instances
  Future readState() async {
    // Read and construct the data structures

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<Organization> allOrgs = List<Organization>();
    Map<String, Map<String, NewsFeed>> allFeeds =
        Map<String, Map<String, NewsFeed>>();
    if (identitiesBloc.current == null) return;

    // Unique list
    identitiesBloc.current.forEach((ident) {
      allOrgs.forEach((org) {
        if (allOrgs.indexWhere((o) => o.entityId == org.entityId) < 0) {
          allOrgs.add(org);
        }
      });
      allOrgs.addAll(ident.organizations);
    });

    // Arrange info
    allOrgs.forEach((org) {
      allFeeds[org.entityId] = Map<String, NewsFeed>();
      org.languages.forEach((lang) {
        final str =
            prefs.getString(NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang");
        if (str == null) return;
        final feed = NewsFeed.fromJson(jsonDecode(str));
        allFeeds[org.entityId][lang] = feed;
      });
    });

    _state.add(allFeeds);
  }

  /// Fetch the news feeds of the given organization and update their entries
  /// on the shared storage
  Future<Map<String, NewsFeed>> fetchOrganizationFeeds(Organization org) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (org.languages == null || org.languages.length < 1)
      return Map<String, NewsFeed>();

    final Map<String, String> strFeeds = {};
    final Map<String, NewsFeed> orgFeeds = {};
    await Future.wait(org.languages.map((lang) async {
      final strFeed = await fetchOrganizationNewsFeed(org, lang);
      strFeeds[lang] = strFeed;
      orgFeeds[lang] = NewsFeed.fromJson(jsonDecode(strFeed));
      await prefs.setString(
          NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/$lang", strFeed);
    }));

    return orgFeeds;
  }
}

class NewsFeed {
  final String version;
  final String title;
  final String description;
  final String favicon;
  final String feedUrl;
  final String homePageUrl;
  final String icon;
  final List<NewsPost> items;
  final bool expired;

  NewsFeed(
      {this.version,
      this.title,
      this.description,
      this.favicon,
      this.feedUrl,
      this.homePageUrl,
      this.icon,
      this.items,
      this.expired});

  NewsFeed.fromJson(Map<String, dynamic> json)
      : version = json['version'] ?? "",
        title = json['title'] ?? "",
        description = json['description'] ?? "",
        favicon = json['favicon'] ?? "",
        feedUrl = json['feedUrl'] ?? "",
        homePageUrl = json['homePageUrl'] ?? "",
        icon = json['icon'] ?? "",
        items = ((json['items'] ?? []) as List)
            .map((i) => NewsPost.fromJson(i))
            .toList(),
        expired = json['expired'] ?? false;
}

class NewsPost {
  final String id;
  final String author;
  final String url;
  final String title;
  final String summary;
  final String contentHtml;
  final String contentText;
  final DateTime published;
  final DateTime modified;
  final String image;
  final List<String> tags;

  NewsPost(
      {this.id,
      this.author,
      this.url,
      this.title,
      this.summary,
      this.contentHtml,
      this.contentText,
      this.published,
      this.modified,
      this.image,
      this.tags});

  NewsPost.fromJson(Map json)
      : id = json['id'] ?? json["guid"] ?? "",
        author = json['author'] is Map ? json["author"]["name"] ?? "" : "",
        summary = json['summary'] ?? "",
        contentHtml = json['content_html'] ?? "",
        contentText = json['content_text'] ?? "",
        published = json['date_published'] != null
            ? DateTime.parse(json['date_published'])
            : null,
        modified = json['date_modified'] != null
            ? DateTime.parse(json['date_modified'])
            : null,
        image = json['image'] ?? "",
        tags = (json['tags'] ?? []).cast<String>().toList(),
        title = json['title'] ?? "",
        url = json['url'] ?? "";
}
