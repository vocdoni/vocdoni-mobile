import 'package:dvote_common/widgets/spinner.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote/dvote.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/card-post.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import "package:vocdoni/lib/extensions.dart";
import 'package:vocdoni/widgets/infinite-content-feed.dart';

// Used to merge and sort feed items
class CardItem {
  final EntityModel entity;
  final ProcessModel process;
  final FeedPost post;
  final DateTime date;

  CardItem(
      {@required this.entity, @required this.date, this.process, this.post});

  CardItem.fromProcess(ProcessModel process)
      : entity = process.entity,
        date = process.startDate.value,
        process = process,
        post = null;

  Widget toWidget(listIdx) {
    if (this.process != null)
      return CardPoll(this.process, this.entity, listIdx);
    else if (this.post != null)
      return CardPost(this.post, this.entity, listIdx);
    return Container();
  }
}

class HomeContentTab extends StatefulWidget {
  HomeContentTab();

  @override
  _HomeContentTabState createState() => _HomeContentTabState();
}

class _HomeContentTabState extends State<HomeContentTab> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("Home");
  }

  void _onRefresh() {
    final currentAccount = Globals.appState.currentAccount;

    currentAccount.refresh().then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
  }

  @override
  Widget build(ctx) {
    return EventualBuilder(
      notifiers: [
        Globals.appState.selectedAccount,
        Globals.oldProcessFeed.processes,
      ],
      builder: (context, _, __) {
        final currentAccount = Globals.appState.currentAccount;
        if (currentAccount == null) return buildNoEntries(ctx);
        // final items = _digestInitialCardList();
        return EventualBuilder(
          notifiers: [
            // currentAccount.entities,
            // Globals.processPool,
            // Globals.feedPool
          ],
          builder: (context, _, __) {
            if (!currentAccount.entities.hasValue ||
                currentAccount.entities.value.length == 0)
              return buildNoEntries(ctx);

            if (Globals?.oldProcessFeed == null) return buildLoading(ctx);
            // if (items.length == 0) return buildNoEntries(ctx);
            Globals.oldProcessFeed.resetIndex();
            if (!Globals.oldProcessFeed.hasNextItem) return buildNoEntries(ctx);
            return ContentListView();

            // return SmartRefresher(
            //   enablePullDown: true,
            //   enablePullUp: false,
            //   header: WaterDropHeader(
            //     complete: Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: <Widget>[
            //           const Icon(Icons.done, color: Colors.grey),
            //           Container(width: 10.0),
            //           Text(getText(context, "main.refreshCompleted"),
            //               style: TextStyle(color: Colors.grey))
            //         ]),
            //     failed: Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: <Widget>[
            //           const Icon(Icons.close, color: Colors.grey),
            //           Container(width: 10.0),
            //           Text(getText(context, "main.couldNotRefresh"),
            //               style: TextStyle(color: Colors.grey))
            //         ]),
            //   ),
            //   controller: _refreshController,
            //   onRefresh: _onRefresh,
            //   child: ListView.builder(
            //       itemCount: items.length,
            //       itemBuilder: (BuildContext ctx, int index) {
            //         try {
            //           print(index);
            //           if (items.length <= index + 2 &&
            //               Globals.oldProcessFeed.hasNextItem) {
            //             print("adding");
            //             final item = CardItem.fromProcess(
            //                 Globals.oldProcessFeed.getNextProcess());
            //             items.add(item);
            //           }
            //         } catch (err) {
            //           log("Error building next list item: $err");
            //         }
            //         if (index < items.length)
            //           return items[index].toWidget(index) ?? Container();
            //         return Container();
            //         // return items[index] ?? Container();
            //       }),
            // );
          },
        );
      },
    );
  }

  Widget buildNoEntries(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 50.0,
              color: Colors.black38,
            ),
            Text(getText(context, "main.prettyLonleyInHere") + "   ¯\\_(ツ)_/¯")
                .withTopPadding(20),
          ],
        ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SpinnerCircular(),
            Text(getText(context, "main.loading") + "...").withTopPadding(20),
          ],
        ));
  }

  // INTERNAL

  List<CardItem> _digestInitialCardList() {
    if (!Globals.accountPool.hasValue || Globals.accountPool.value.length == 0)
      return [];

    final currentAccount = Globals.appState.currentAccount;
    if (currentAccount == null ||
        !currentAccount.entities.hasValue ||
        currentAccount.entities.value.length == 0) return [];

    final availableItems = List<CardItem>();

    Globals.oldProcessFeed.resetIndex();

    for (int i = 0; i < 5; i++) {
      if (!Globals.oldProcessFeed.hasNextItem) break;
      availableItems
          .add(CardItem.fromProcess(Globals.oldProcessFeed.getNextProcess()));
    }

    return availableItems;

    // for (final entity in currentAccount.entities.value) {
    //   if (entity.feed.hasValue) {
    //     entity.feed.value.items.forEach((post) {
    //       if (!(post is FeedPost)) return;
    //       final date = DateTime.tryParse(post.datePublished);
    //       final item = CardItem(entity: entity, date: date, post: post);
    //       availableItems.add(item);
    //     });
    //   }

    // if (entity.processes.hasValue) {
    //   entity.processes.value.forEach((process) {
    //     if (!(process is ProcessModel) || process.metadata.isLoading)
    //       return;
    //     else if (!process.metadata.hasValue) return;

    //     availableItems.add(CardItem(
    //         entity: entity, date: process.endDate.value, process: process));
    //   });
    // }
    // }

    // availableItems.sort((a, b) {
    //   if (!(a?.date is DateTime) && !(b?.date is DateTime))
    //     return 0;
    //   else if (!(a?.date is DateTime))
    //     return -1;
    //   else if (!(b?.date is DateTime)) return 1;
    //   return b.date.compareTo(a.date);
    // });
    //   int listIdx = 0;
    //   final result = availableItems
    //       .map((item) {
    //         if (item.process != null)
    //           return CardPoll(item.process, item.entity, listIdx++);
    //         else if (item.post != null)
    //           return CardPost(item.post, item.entity, listIdx++);
    //         return Container();
    //       })
    //       .cast<Widget>()
    //       .toList();

    //   return result;
  }
}
