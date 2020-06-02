import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote/dvote.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/card-post.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// Used to merge and sort feed items
class CardItem {
  final EntityModel entity;
  final ProcessModel process;
  final FeedPost post;
  final DateTime date;

  CardItem(
      {@required this.entity, @required this.date, this.process, this.post});
}

class HomeTab extends StatefulWidget {
  HomeTab();

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("HomeTab");
  }

  void _onRefresh() {
    final currentAccount = globalAppState.currentAccount;

    currentAccount.refresh().then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
  }

  @override
  Widget build(ctx) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) return buildNoEntries(ctx);

    return EventualBuilder(
      notifiers: [currentAccount.entities, globalProcessPool, globalFeedPool],
      builder: (context, _, __) {
        if (!currentAccount.entities.hasValue ||
            currentAccount.entities.value.length == 0)
          return buildNoEntries(ctx);

        final items = _digestCardList();
        if (items.length == 0) return buildNoEntries(ctx);

        return SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: WaterDropHeader(
            complete: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.done, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "Refresh completed"),
                      style: TextStyle(color: Colors.grey))
                ]),
            failed: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.close, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "Could not refresh"),
                      style: TextStyle(color: Colors.grey))
                ]),
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext ctx, int index) =>
                  items[index] ?? Container()),
        );
      },
    );
  }

  Widget buildNoEntries(BuildContext ctx) {
    return Center(
      child:
          Text(getText(context, "Pretty lonley in here...") + "   ¯\\_(ツ)_/¯"),
    );
  }

  // INERNAL

  List<Widget> _digestCardList() {
    if (!globalAccountPool.hasValue || globalAccountPool.value.length == 0)
      return [];

    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null ||
        !currentAccount.entities.hasValue ||
        currentAccount.entities.value.length == 0) return [];

    final availableItems = List<CardItem>();

    for (final entity in currentAccount.entities.value) {
      if (entity.feed.hasValue) {
        entity.feed.value.items.forEach((post) {
          if (!(post is FeedPost)) return;
          final date = DateTime.tryParse(post.datePublished);
          final item = CardItem(entity: entity, date: date, post: post);
          availableItems.add(item);
        });
      }

      if (entity.processes.hasValue) {
        entity.processes.value.forEach((process) {
          if (!(process is ProcessModel) || process.metadata.isLoading)
            return;
          else if (!process.metadata.hasValue) return;

          availableItems.add(CardItem(
              entity: entity, date: process.startDate, process: process));
        });
      }
    }

    availableItems.sort((a, b) {
      if (!(a?.date is DateTime) && !(b?.date is DateTime))
        return 0;
      else if (!(a?.date is DateTime))
        return -1;
      else if (!(b?.date is DateTime)) return 1;
      return b.date.compareTo(a.date);
    });

    int idx = 0;
    final result = availableItems
        .map((item) {
          if (item.process != null)
            return CardPoll(
                entity: item.entity, process: item.process, index: idx++);
          else if (item.post != null)
            return CardPost(item.entity, item.post, idx++);
          return Container();
        })
        .cast<Widget>()
        .toList();

    return result;
  }
}
