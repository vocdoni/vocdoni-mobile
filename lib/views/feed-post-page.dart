import 'package:dvote/dvote.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
// import 'package:vocdoni/modals/web-viewer.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:webview_flutter/webview_flutter.dart'; // TODO: REMOVE
import 'package:vocdoni/util/net.dart';

class FeedPostArgs {
  final FeedPost post;

  FeedPostArgs(this.post);
}

class FeedPostPage extends StatelessWidget {
  @override
  Widget build(ctx) {
    final FeedPostArgs args = ModalRoute.of(ctx).settings.arguments;

    FeedPost post = args.post;

    if (post == null) return buildNoPosts(ctx);

    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            Container(
              height: 300,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xff7c94b6),
                    image: new DecorationImage(
                        image: new NetworkImage(post.image),
                        fit: BoxFit.cover)),
              ),
            ),
            PageTitle(
              title: post.title,
              subtitle: post.author.name,
            ),
            //Section(text: "HTML render 1"),
            //html1(post.contentHtml),
            //Section(text: "HTML render 2"),
            html2(post.contentHtml),
          ],
        ));
  }

  html1(String htmlBody) {
    final String html = styleHtml(htmlBody);
    final uri = uriFromContent(html);
    return Container(
        padding: EdgeInsets.fromLTRB(
            paddingPage, spaceElement, paddingPage, spaceElement),
        width: double.infinity,
        height: 500,
        child: WebView(
            navigationDelegate: (NavigationRequest request) {
              launchUrl(request.url);
              return NavigationDecision.prevent;
            },
            initialUrl: uri,
            javascriptMode: JavascriptMode.disabled));
  }

  html2(String htmlBody) {
    return Html(
      data: htmlBody,
      padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, spaceElement),
      defaultTextStyle: TextStyle(fontSize: 16),
      onLinkTap: (url) => launchUrl(url),
      /*customRender: (node, children) {
                      if (node is dom.Element) {
                        switch (node.localName) {
                          case "custom_tag": // using this, you can handle custom tags in your HTML
                            return Column(children: children);
                        }
                    },*/
    );
  }

  launchUrl(String url) async {
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildNoPosts(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No posts)"),
    );
  }

  String styleHtml(String content) {
    String hex = colorLink.value.toRadixString(16);
    String htmlLinkColor = hex.replaceRange(0, 2, '#');

    return '''<!DOCTYPE html>
<html>
		<head>
				<meta charset="utf-8">
				<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'/>

				<style>
            body {
							
              font-family: 'Open Sans' Helvetica Neue', Helvetica, Sans-serif, Arial;
              	user-select: none;
              -webkit-user-select: none;
              margin: 0px;
              line-height: 1.6;
              font-size: 16px;
            }

            a {
              color: ${htmlLinkColor};
            }

						img {
								margin: 15px 0 8px;
								/*display: none;*/
								max-width: 100% !important;
						}
				</style>
		</head>
		<body>
			$content
		</body>
''';
  }
}
