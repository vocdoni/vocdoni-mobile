import "dart:convert";
import "dart:async";
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
// import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/widgets/feedItemCard.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

import 'activity-post.dart';

class EntityActivity extends StatefulWidget {
  @override
  _EntityActivityState createState() => _EntityActivityState();
}

class _EntityActivityState extends State<EntityActivity> {
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  Widget build(context) {
    final Entity organization = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (organization == null) return buildEmptyOrganization(context);

    final feed = digestEntityFeed(context, organization);
    if (feed == null) {
      loadRemoteFeed(context, organization);
      return buildEmptyPosts(context);
    }

    return Scaffold(
      appBar: TopNavigation(
        title: organization.name[organization.languages[0]],
      ),
      body: ListView.builder(
        itemCount: feed.items.length,
        itemBuilder: (BuildContext context, int index) {
          final FeedPost post = feed.items[index];
          return FeedItemCard(
            post: post,
            onTap: () => onTapItem(context, post),
          );
        },
      ),
    );
  }

  Widget buildEmptyOrganization(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("(No organization)"),
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
    Navigator.of(ctx).pushNamed("/organization/activity/post",
        arguments: ActivityPostArguments(post));
  }

  Feed digestEntityFeed(BuildContext context, Entity entity) {
    // Already fetched?
    if (remoteNewsFeed != null)
      return remoteNewsFeed;
    else if (newsFeedsBloc.current == null) return null;

    // TODO: DETECT THE CURRENT LANGUAGE
    final feeds = newsFeedsBloc.current.where((feed) {
      if (feed.meta["entityId"] != entity.entityId)
        return false;
      else if (feed.meta["language"] != entity.languages[0]) return false;
      return true;
    }).toList();

    return feeds[0] ?? null;
  }

  Future loadRemoteFeed(BuildContext ctx, Entity entity) async {
    if (remoteFetched) return;
    remoteFetched = true;
    Timer(Duration(milliseconds: 10), () {
      setState(() {
        loading = true;
      });
    });

    try {
      final result = await fetchEntityNewsFeed(entity, entity.languages[0]);
      final decoded = Feed.fromJson(jsonDecode(result));

      setState(() {
        remoteNewsFeed = decoded;
        loading = false;
      });
    } catch (err) {
      showErrorMessage(
          Lang.of(ctx).get("The activity can not be loaded at this time"),
          context: ctx);
      setState(() {
        loading = false;
      });
    }
  }
}
