import "dart:convert";
import "dart:async";
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/widgets/feed-item-card.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class OrganizationActivity extends StatefulWidget {
  @override
  _OrganizationActivityState createState() => _OrganizationActivityState();
}

class _OrganizationActivityState extends State<OrganizationActivity> {
  NewsFeed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  Widget build(context) {
    final Organization organization = ModalRoute.of(context).settings.arguments;
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
        title: organization.name,
      ),
      backgroundColor: baseBackgroundColor,
      body: ListView.builder(
        itemCount: feed.items.length,
        itemBuilder: (BuildContext context, int index) {
          final NewsPost post = feed.items[index];
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

  onTapItem(BuildContext ctx, NewsPost item) {
    Navigator.of(ctx).pushNamed("/web/viewer",
        arguments: item.contentHtml ?? "<p>${item.contentText}</p>");
  }

  NewsFeed digestGivenOrganizationFeed(
      BuildContext context, Organization organization) {
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

  Future loadRemoteFeed(BuildContext ctx, Organization organization) async {
    if (remoteFetched) return;
    remoteFetched = true;
    Timer(Duration(milliseconds: 10), () {
      setState(() {
        loading = true;
      });
    });

    try {
      final result = await fetchOrganizationNewsFeed(
          organization, organization.languages[0]);
      final decoded = NewsFeed.fromJson(jsonDecode(result));

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
