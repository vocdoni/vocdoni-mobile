import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedPage extends StatelessWidget {
  final Organization organization;
  final FeedItem feedItem;

  FeedPage({this.organization, this.feedItem});

  @override
  Widget build(context) {
    return StreamBuilder(
        stream: identitiesBloc.stream,
        builder: (BuildContext _, AsyncSnapshot<List<Identity>> identities) {
          return StreamBuilder(
              stream: appStateBloc.stream,
              builder: (BuildContext ctx, AsyncSnapshot<AppState> appState) {
                return Scaffold(
                  body: ListView(
                    children: <Widget>[
                      PageTitle(
                        title: feedItem.title,
                        subtitle: feedItem.author,
                      ),
                      Html(
                        data: feedItem.contentHtml,
                        padding: EdgeInsets.fromLTRB(pagePadding,cardSpacing,pagePadding,cardSpacing),
                        defaultTextStyle: TextStyle( fontSize: 16),
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
                  ),
                );
              });
        });
  }

  launchUrl(url) async {
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
