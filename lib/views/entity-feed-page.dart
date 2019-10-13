import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

class EntityFeedPage extends StatefulWidget {
  @override
  _EntityFeedPageState createState() => _EntityFeedPageState();
}

class _EntityFeedPageState extends State<EntityFeedPage> {
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      EntModel ent = ModalRoute.of(super.context).settings.arguments;
      analytics.trackPage(
          pageId: "EntityFeedPage", entityId: ent.entityReference.entityId);
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    final EntModel ent = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (ent == null) return buildEmptyEntity(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.value.name[ent.entityMetadata.value.languages[0]],
      ),
      body: ListView.builder(
        itemCount: ent.feed.value.items.length,
        itemBuilder: (BuildContext context, int index) {
          final FeedPost post = ent.feed.value.items[index];
          return buildFeedPostCard(ctx: context, ent: ent, post: post);
        },
      ),
    );
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("(No entity)"),
    ));
  }

  Widget buildEmptyPosts(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("(No posts)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }
}
