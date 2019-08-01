import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/activity-post.dart';
import 'package:vocdoni/widgets/feedItemCard.dart';
import 'package:dvote/dvote.dart';

class FeedTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;
  final Map<String, Map<String, Feed>> newsFeeds;

  FeedTab({this.appState, this.identities, this.newsFeeds});

  @override
  Widget build(ctx) {
    if (newsFeeds == null) return buildNoVotes(ctx);

    List<FeedPost> newsPosts = List<FeedPost>();
    final Identity currentIdentity =
        identities?.elementAt(appState?.selectedIdentity ?? 0);
    if (currentIdentity == null) return buildNoVotes(ctx);
    currentIdentity.peers.entities.forEach((entity) {
      // TODO: DETECT LANGUAGE
      final lang = (entity is Entity && entity.languages is List)
          ? entity.languages[0]
          : "en";
      if (!(newsFeeds[entity.entityId] is Map) ||
          !(newsFeeds[entity.entityId][lang] is Feed)) return;
      final newsFeed = newsFeeds[entity.entityId][lang];
      newsPosts.addAll(newsFeed.items);
    });

    if (newsPosts.length == 0) return buildNoVotes(ctx);
    newsPosts.sort((a, b) {
      if (!(a?.datePublished is DateTime) && !(b?.datePublished is DateTime))
        return 0;
      else if (!(a?.datePublished is DateTime))
        return -1;
      else if (!(b?.datePublished is DateTime)) return 1;
      return b.datePublished.compareTo(a.datePublished);
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

  onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx).pushNamed("/organization/activity/post",
        arguments: ActivityPostArguments(post));
  }
}
