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

class OrganizationActivity extends StatefulWidget {
  @override
  _OrganizationActivityState createState() => _OrganizationActivityState();
}

class _OrganizationActivityState extends State<OrganizationActivity> {
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  Widget build(context) {
    final Entity organization = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (organization == null) return buildEmptyOrganization(context);

    final feed = digestGivenOrganizationFeed(context, organization);
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

  Feed digestGivenOrganizationFeed(
      BuildContext context, Entity organization) {
    // Already fetched?
    if (remoteNewsFeed != null)
      return remoteNewsFeed;
    else if (newsFeedsBloc.current == null) return null;

    // TODO: DETECT LANGUAGE
    final defaultLang = organization?.languages?.elementAt(0) ?? "en";
    final newsFeeds = newsFeedsBloc.current;
    if ((newsFeeds[organization?.entityId] ?? const {})[defaultLang] == null)
      return null;

    final feed = (newsFeeds[organization?.entityId] ?? const {})[defaultLang];
    if (feed.items?.length == 0 ?? true) {
      return null;
    }

    return feed;
  }

  Future loadRemoteFeed(BuildContext ctx, Entity organization) async {
    if (remoteFetched) return;
    remoteFetched = true;
    Timer(Duration(milliseconds: 10), () {
      setState(() {
        loading = true;
      });
    });

    try {
      final result =
          await fetchEntityNewsFeed(organization, organization.languages[0]);
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
