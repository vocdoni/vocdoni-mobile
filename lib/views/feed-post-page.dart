import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/i18n.dart';
import "dart:developer";
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedPostArgs {
  final EntityModel entity;
  final FeedPost post;
  final int index;

  FeedPostArgs(
      {@required this.entity, @required this.post, @required this.index});
}

class FeedPostPage extends StatefulWidget {
  @override
  _FeedPostPageState createState() => _FeedPostPageState();
}

class _FeedPostPageState extends State<FeedPostPage> {
  FeedPostArgs args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      this.args = ModalRoute.of(super.context).settings.arguments;

      if (args != null) {
        Globals.analytics.trackPage("FeedPostPage",
            entityId: args.entity.reference.entityId,
            postTitle: args.post.title);
      }
    } catch (err) {
      log(err);
    }
  }

  @override
  Widget build(ctx) {
    FeedPost post = args.post;
    EntityModel entity = args.entity;
    int index = args.index ?? 0;

    if (post == null) return buildNoPost(ctx);

    return ScaffoldWithImage(
        headerImageUrl: post.image,
        headerTag: makeElementTag(entity.reference.entityId, post.id, index),
        avatarUrl: entity.metadata.value.media.avatar,
        avatarText:
            entity.metadata.value.name[Globals.appState.currentLanguage],
        avatarHexSource: post.id,
        appBarTitle: getText(context, "main.post"),
        //actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(
                  getScaffoldChildren(ctx, entity, post)),
            );
          },
        ));
  }

  getScaffoldChildren(BuildContext context, EntityModel ent, FeedPost post) {
    List<Widget> children = [];
    children.add(buildTitle(context, ent, post));
    children.add(renderHtmlBody(post.contentHtml));
    return children;
  }

  buildTitle(BuildContext context, EntityModel ent, FeedPost post) {
    return ListItem(
      //mainTextTag: process.meta['processId'] + title,
      mainText: post.title,
      mainTextMultiline: 3,
      secondaryText: ent.metadata.value.name['default'],
      isTitle: true,
      rightIcon: null,
      isBold: true,
      //avatarUrl: ent.metadata.media.avatar,
      //avatarText: process.details.title['default'],
      //avatarHexSource: ent.entitySummary.entityId,
      mainTextFullWidth: true,
    );
  }

  renderHtmlBody(String htmlBody) {
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
    // print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  Widget buildNoPost(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text(getText(context, "main.noPosts")),
    );
  }

//   String styleHtml(String content) {
//     String hex = colorLink.value.toRadixString(16);
//     String htmlLinkColor = hex.replaceRange(0, 2, '#');

//     return '''<!DOCTYPE html>
// <html>
// 		<head>
// 				<meta charset="utf-8">
// 				<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'/>

// 				<style>
//             body {

//               font-family: 'Open Sans' Helvetica Neue', Helvetica, Sans-serif, Arial;
//               	user-select: none;
//               -webkit-user-select: none;
//               margin: 0px;
//               line-height: 1.6;
//               font-size: 16px;
//             }

//             a {
//               color: $htmlLinkColor;
//             }

// 						img {
// 								margin: 15px 0 8px;
// 								/*display: none;*/
// 								max-width: 100% !important;
// 						}
// 				</style>
// 		</head>
// 		<body>
// 			$content
// 		</body>
// ''';
//   }
}
