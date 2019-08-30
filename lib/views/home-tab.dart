import "package:flutter/material.dart";
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/widgets/listItem.dart';

class CardContentWrapper {
  final Ent ent;
  final ProcessMetadata process;
  final FeedPost post;
  final DateTime date;

  CardContentWrapper({this.ent, this.date, this.process, this.post});
}

class HomeTab extends StatelessWidget {
  HomeTab();

  @override
  Widget build(ctx) {
    List<CardContentWrapper> items = [];
    account.ents.forEach((ent) {
      if (ent.feed != null) {
        ent.feed.items.forEach((FeedPost post) {
          DateTime date = DateTime.parse(post.datePublished);
          CardContentWrapper item = new CardContentWrapper(
              ent: ent, date: date, post: post, process: null);
          items.add(item);
        });
      }
      if (ent.processess != null) {
        ent.processess.forEach((ProcessMetadata process) {
          DateTime date = getDateFromBlockNumber(process.startBlock);
          CardContentWrapper item = new CardContentWrapper(
              ent: ent, date: date, post: null, process: process);
          items.add(item);
        });
      }
    });

    if (items.length == 0) return buildNoEntries(ctx);

    sort(items);

    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext ctx, int index) {
          final item = items[index];
          if (item.post != null)
            return buildFeedPostCard(ctx:ctx, ent:item.ent, post:item.post);
          else
            return Container();
        });
  }

  Widget buildNoEntries(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("Pretty lonley in here...   ¯\\_(ツ)_/¯"),
    );
  }

  onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx)
        .pushNamed("/entity/activity/post", arguments: FeedPostArgs(post));
  }

  sort(List<CardContentWrapper> items) {
    items.sort((a, b) {
      if (!(a?.date is DateTime) && !(b?.date is DateTime))
        return 0;
      else if (!(a?.date is DateTime))
        return -1;
      else if (!(b?.date is DateTime)) return 1;
      return b.date.compareTo(a.date);
    });
  }

  DateTime getDateFromBlockNumber(int blockNumber) {
    //Todo implement
    return DateTime.now();
  }

  
}
