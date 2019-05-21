import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/widgets/topNavigation.dart'; // TODO: REMOVE

class ActivityPostArguments {
  final NewsPost post;

  ActivityPostArguments(this.post);
}

class ActivityPostScreen extends StatelessWidget {
  @override
  Widget build(ctx) {
    final ActivityPostArguments args = ModalRoute.of(ctx).settings.arguments;

    NewsPost post = args.post;

    if (post == null) return buildNoPosts(ctx);

    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        backgroundColor: baseBackgroundColor,
        body: ListView(
          children: <Widget>[
            PageTitle(
              title: post.title,
              subtitle: post.author,
            ),
            Html(
              data: post.contentHtml,
              padding: EdgeInsets.fromLTRB(
                  pagePadding, cardSpacing, pagePadding, cardSpacing),
              defaultTextStyle: TextStyle(fontSize: 16),
              onLinkTap: (url) => launchUrl(url),
              /*customRender: (node, children) {
                      if (node is dom.Element) {
                        switch (node.localName) {
                          case "custom_tag": // using this, you can handle custom tags in your HTML
                            return Column(children: children);
                        }
                    },*/
            ),
          ],
        ));
  }

  launchUrl(url) async {
    // TODO: Uninstall url_launcher and use inapp_webview instead
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildNoOrganization(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No organizations)"),
    );
  }

  Widget buildNoPosts(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No posts)"),
    );
  }
}
