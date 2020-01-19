import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/widgets/card-loading.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/card-post.dart';

class CardItem {
  final bool loading;
  final EntityModel entity;
  final ProcessModel process;
  final FeedPost post;
  final DateTime date;

  CardItem(
      {this.entity, this.date, this.process, this.post, this.loading = false});
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
    globalAnalytics.trackPage("HomeTab");
  }

  @override
  Widget build(ctx) {
    final items = _digestItemsList();

    if (items.length == 0) return buildNoEntries(ctx);

    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext ctx, int index) {
          final item = items[index];
          if (item.loading)
            return CardLoading();
          else if (item.post != null)
            return CardPost(item.entity, item.post, index);
          else if (item.process != null)
            return CardPoll(
                ent: item.entity, process: item.process, index: index);
          return Container();
        });
  }

  Widget buildNoEntries(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("Pretty lonley in here...   ¯\\_(ツ)_/¯"),
    );
  }

  // INERNAL

  List<CardItem> _digestItemsList() {
    if (!globalAccountPool.hasValue || globalAccountPool.value.length == 0)
      return [];

    final currentAccount = globalAppState.getSelectedAccount();
    if (currentAccount == null ||
        currentAccount.entities.hasValue ||
        currentAccount.entities.value.length == 0) return [];

    final result = List<CardItem>();
    for (final entity in currentAccount.entities.value) {
      if (entity.feed.isLoading || entity.feed.value.feed.isLoading)
        result.add(CardItem(loading: true));
      else if (entity.feed.hasValue && entity.feed.value.feed.hasValue) {
        entity.feed.value.feed.value.items.forEach((post) {
          if (!(post is FeedPost)) return;
          final date = DateTime.tryParse(post.datePublished);
          final item = CardItem(entity: entity, date: date, post: post);
          result.add(item);
        });
      }
      if (entity.processes.hasValue) {
        entity.processes.value.forEach((process) {
          if (!(process is ProcessModel))
            return;
          else if (process.metadata.isLoading) {
            result.add(CardItem(loading: true));
          } else if (process.metadata.hasError) return;

          result.add(CardItem(
              entity: entity, date: process.startDate, process: process));
        });
      }
    }

    result.sort((a, b) {
      if (!(a?.date is DateTime) && !(b?.date is DateTime))
        return 0;
      else if (!(a?.date is DateTime))
        return -1;
      else if (!(b?.date is DateTime)) return 1;
      return b.date.compareTo(a.date);
    });

    return result;
  }
}
