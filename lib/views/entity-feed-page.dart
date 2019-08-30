import "dart:convert";
import "dart:async";
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/views/feed-post-page.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import 'package:intl/intl.dart';

class EntityFeedPage extends StatefulWidget {
  @override
  _EntityFeedPageState createState() => _EntityFeedPageState();
}

class _EntityFeedPageState extends State<EntityFeedPage> {
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  Widget build(context) {
    final Ent ent = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (ent == null) return buildEmptyEntity(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      ),
      body: ListView.builder(
        itemCount: ent.feed.items.length,
        itemBuilder: (BuildContext context, int index) {
          final FeedPost post = ent.feed.items[index];
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

  onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx)
        .pushNamed("/entity/feed/post", arguments: FeedPostArgs(post));
  }

  Future loadRemoteFeed(BuildContext ctx, EntityMetadata entityMetadata) async {
    if (remoteFetched) return;
    remoteFetched = true;
    Timer(Duration(milliseconds: 10), () {
      setState(() {
        loading = true;
      });
    });

    try {
      final result = await fetchEntityNewsFeed(
          entityMetadata, entityMetadata.languages[0]);
      final decoded = Feed.fromJson(jsonDecode(result));

      setState(() {
        remoteNewsFeed = decoded;
        loading = false;
      });
    } catch (err) {
      showMessage(
          Lang.of(ctx).get("The activity can not be loaded at this time"),
          context: ctx,
          purpose: Purpose.DANGER);
      setState(() {
        loading = false;
      });
    }
  }
}
