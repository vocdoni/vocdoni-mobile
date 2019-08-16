import "dart:convert";
import "dart:async";
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import 'package:intl/intl.dart';

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
    final Entity entity = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (entity == null) return buildEmptyEntity(context);

    final feed = digestEntityFeed(context, entity);
    if (feed == null) {
      loadRemoteFeed(context, entity);
      return buildEmptyPosts(context);
    }

    return Scaffold(
      appBar: TopNavigation(
        title: entity.name[entity.languages[0]],
      ),
      body: ListView.builder(
        itemCount: feed.items.length,
        itemBuilder: (BuildContext context, int index) {
          final FeedPost post = feed.items[index];
          return BaseCard(
            image: post.image,
            children: <Widget>[
              ListItem(
                mainText: post.title,
                mainTextFullWidth: true,
                secondaryText: entity.name[entity.languages[0]],
                avatarUrl: entity.media.avatar,
                rightText: DateFormat('MMMM dd')
                    .format(DateTime.parse(post.datePublished).toLocal()),
                onTap: () => onTapItem(context, post),
              )
            ],
          );
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
    Navigator.of(ctx).pushNamed("/entity/activity/post",
        arguments: ActivityPostArguments(post));
  }

  Feed digestEntityFeed(BuildContext context, Entity entity) {
    // Already fetched?
    if (remoteNewsFeed != null)
      return remoteNewsFeed;
    else if (newsFeedsBloc.value == null) return null;

    // TODO: DETECT THE CURRENT LANGUAGE
    final feeds = newsFeedsBloc.value.where((feed) {
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
