import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeedTab extends StatelessWidget {
  final Organization organization;
  final NewsFeed newsFeed;

  NewsFeedTab({this.organization, this.newsFeed});

  @override
  Widget build(ctx) {
    if (organization == null)
      return buildNoOrganization(ctx);
    else if (newsFeed == null || newsFeed.items.length == 0)
      return buildNoPosts(ctx);

    return ListView(
      children: newsFeed.items
          .map((NewsPost item) => Column(
                children: <Widget>[
                  PageTitle(
                    title: item.title,
                    subtitle: item.author,
                  ),
                  Html(
                    data: item.contentHtml,
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
              ))
          .toList(),
    );
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
