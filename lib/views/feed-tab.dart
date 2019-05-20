import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/feed-item-card.dart';

class FeedTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;
  final Map<String, Map<String, NewsFeed>> newsFeeds;

  FeedTab({this.appState, this.identities, this.newsFeeds});

  @override
  Widget build(ctx) {
    if (newsFeeds == null) return buildNoVotes(ctx);

    List<NewsPost> newsPosts = List<NewsPost>();
    final Identity currentIdentity =
        identities?.elementAt(appState?.selectedIdentity ?? 0);
    if (currentIdentity == null) return buildNoVotes(ctx);
    currentIdentity.organizations.forEach((org) {
      // TODO: DETECT LANGUAGE
      final lang = (org is Organization && org.languages is List)
          ? org.languages[0]
          : "en";
      if (!(newsFeeds[org.entityId] is Map) ||
          !(newsFeeds[org.entityId][lang] is NewsFeed)) return;
      final newsFeed = newsFeeds[org.entityId][lang];
      newsPosts.addAll(newsFeed.items);
    });

    if (newsPosts.length == 0) return buildNoVotes(ctx);
    newsPosts.sort((a, b) {
      if (!(a?.published is DateTime) && !(b?.published is DateTime))
        return 0;
      else if (!(a?.published is DateTime))
        return -1;
      else if (!(b?.published is DateTime)) return 1;
      return b.published.compareTo(a.published);
    });

    // TODO: UI

    return ListView.builder(
        itemCount: newsPosts.length,
        itemBuilder: (BuildContext ctx, int index) {
          final post = newsPosts[index];
          return FeedItemCard(
            post: post,
            onTap: () => onTapItem(ctx, post),
          );
        });
  }

  Widget buildNoVotes(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No votes available)"),
    );
  }

  onTapItem(BuildContext ctx, NewsPost item) {
    Navigator.of(ctx).pushNamed("/web/viewer",
        arguments: item.contentHtml ?? "<p>${item.contentText}</p>");
  }
}
