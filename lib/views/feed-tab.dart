import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/activity-post.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:intl/intl.dart';

class FeedTab extends StatelessWidget {
  final AppState appState;
  final List<Identity> identities;
  final List<Feed> newsFeeds;

  FeedTab({this.appState, this.identities, this.newsFeeds});

  @override
  Widget build(ctx) {
    if (newsFeeds == null) return buildNoEntries(ctx);

    List<FeedPost> newsPosts = List<FeedPost>();
    final Identity currentIdentity =
        identities?.elementAt(appState?.selectedIdentity ?? 0);
    if (currentIdentity == null) return buildNoEntries(ctx);

    final entities = entitiesBloc.current.where((entity) {
      return currentIdentity.peers.entities
              .indexWhere((e) => e.entityId == entity.entityId) >=
          0;
    }).toList();

    newsFeedsBloc.current.forEach((feed) {
      final matched = 0 <=
          entities.indexWhere((entity) {
            if (feed.meta["entityId"] != entity.entityId)
              return false;
            // TODO: DETECT THE CURRENT LANGUAGE
            else if (feed.meta["language"] != entity.languages[0]) return false;
            return true;
          });
      if (!matched) return;
      newsPosts.addAll(feed.items);
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
            children: <Widget>[
              ListItem(
                mainText: post.title,
                mainTextFullWidth: true,
                secondaryText: post.author.name,
                rightText: DateFormat('MMMM dd').format(DateTime.parse(post.datePublished).toLocal()),
                onTap: () => onTapItem(ctx, post),
              )
            ],
          );
        });
  }

  Widget buildNoEntries(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No votes available"),
    );
  }

  onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx).pushNamed("/entity/activity/post",
        arguments: ActivityPostArguments(post));
  }
}
