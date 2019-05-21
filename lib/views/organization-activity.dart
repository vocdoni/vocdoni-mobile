import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/views/feed-page.dart';
import 'package:vocdoni/widgets/feed-item-card.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class OrganizationActivity extends StatelessWidget {
  final Organization organization;

  OrganizationActivity({this.organization});

  @override
  Widget build(context) {
    final Organization organization = ModalRoute.of(context).settings.arguments;
    if (organization == null) return buildEmptyOrganization(context);

    if (newsFeedsBloc.current == null) return buildEmptyPosts(context);

    final defaultLang = "en"; // TODO: DETECT LANGUAGE
    final Map<String, Map<String, NewsFeed>> newsFeeds = newsFeedsBloc.current;
    if (newsFeeds[organization.entityId] == null ||
        newsFeeds[organization.entityId][defaultLang] == null ||
        newsFeeds[organization.entityId][defaultLang].items == null ||
        newsFeeds[organization.entityId][defaultLang].items.length == 0)
      return buildEmptyPosts(context);

    final NewsFeed feed = newsFeeds[organization.entityId][defaultLang];

    return Scaffold(
      appBar: TopNavigation(
        title: organization.name,
      ),
      backgroundColor: baseBackgroundColor,
      body: ListView.builder(
        itemCount: newsFeeds[organization.entityId][defaultLang].items.length,
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

  onTapItem(BuildContext ctx, NewsPost item) {
    Navigator.of(ctx).pushNamed("/web/viewer",
        arguments: item.contentHtml ?? "<p>${item.contentText}</p>");
  }
}
