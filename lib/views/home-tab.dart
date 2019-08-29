import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:intl/intl.dart';

class HomeTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;
  final List<Feed> newsFeeds;

  HomeTab({this.appState, this.identities, this.newsFeeds});

  @override
  Widget build(ctx) {
    if (newsFeeds == null) return buildNoEntries(ctx);

    List<FeedPost> newsPosts = List<FeedPost>();

    if (account.ents.length == 0) return buildNoEntries(ctx);

    account.ents.forEach((ent) {
      if (ent.feed != null) newsPosts.addAll(ent.feed.items);
    });

    if (newsPosts.length == 0) return buildNoEntries(ctx);
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
          return BaseCard(
            image: post.image,
            imageTag: post.id,
            children: <Widget>[
              ListItem(
                mainText: post.title,
                mainTextFullWidth: true,
                secondaryText: post.author.name,
                rightText: DateFormat('MMMM dd')
                    .format(DateTime.parse(post.datePublished).toLocal()),
                onTap: () => onTapItem(ctx, post),
              )
            ],
          );
        });
  }

  Widget buildNoEntries(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("Pretty lonley in here...   ¯\\_(ツ)_/¯"),
    );
  }

  onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx).pushNamed("/entity/activity/post",
        arguments: FeedPostArgs(post));
  }
}
