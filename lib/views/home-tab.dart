import "package:flutter/material.dart";
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/widgets/pollCard.dart';

class CardContentWrapper {
  final EntModel ent;
  final ProcessModel process;
  final FeedPost post;
  final DateTime date;

  CardContentWrapper({this.ent, this.date, this.process, this.post});
}

class HomeTab extends StatefulWidget {
  HomeTab();

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    analytics.trackPage(pageId: "HomeTab");
  }

  @override
  Widget build(ctx) {
    List<CardContentWrapper> items = [];
    account.ents.forEach((ent) {
      if (ent.feed.isValid) {
        ent.feed.value.items.forEach((FeedPost post) {
          DateTime date = DateTime.parse(post.datePublished);
          CardContentWrapper item = new CardContentWrapper(
              ent: ent, date: date, post: post, process: null);
          items.add(item);
        });
      }
      if (ent.processes.isValid) {
        ent.processes.value.forEach((ProcessModel process) {
          if (process.processMetadata == null) return;
          DateTime date =
              getDateFromBlockNumber(process.processMetadata.value.startBlock);
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
            return buildFeedPostCard(ctx: ctx, ent: item.ent, post: item.post);
          else if (item.process != null)
            return PollCard(ent: item.ent, process: item.process);
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
