import "package:flutter/material.dart";
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DevUiCard extends StatelessWidget {
  @override
  Widget build(ctx) {
    String headerImg =
        "https://images.unsplash.com/photo-1535485654825-17b2e804ba9c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80";
    String avatar =
        "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Anonymous_emblem.svg/320px-Anonymous_emblem.svg.png";
    return Scaffold(
      appBar: TopNavigation(
        title: "Cards variants",
      ),
      body: ListView(
        children: <Widget>[
          BaseCard(),
          BaseCard(image: headerImg),
          BaseCard(children: [ListItem(mainText: "Hello")]),
          BaseCard(image: headerImg, children: [ListItem(mainText: "Hello")]),
          BaseCard(image: headerImg, children: [
            ListItem(
              mainText: "Where would you like the next retreat?,",
              icon: FeatherIcons.barChart2,
              avatarUrl: avatar,
              secondaryText: "Vocdoni",
              iconIsSecondary: true,
              rightText: "Aug, Mon 2",
            )
          ]),
          BaseCard(children: [
            ListItem(
              mainText: "Vocdoni",
              avatarUrl: avatar,
            ),
            ListItem(
              mainText: "Claims",
              icon: FeatherIcons.award,
              rightText: "323",
              rightTextPurpose: Purpose.GUIDE,
            ),
            ListItem(
              mainText: "Feed",
              icon: FeatherIcons.mail,
              rightText: "3",
              rightTextPurpose: Purpose.GUIDE,
            ),
            ListItem(
              mainText: "Participation",
              icon: FeatherIcons.rss,
              rightText: "3",
              rightTextPurpose: Purpose.GUIDE,
            )
          ]),
          BaseCard (children: [
            ListItem(
              mainText: "Vocdoni",
              avatarUrl: avatar,
              disabled: true,
            ),
            ListItem(
              purpose: Purpose.DANGER,
              mainText: "Danger and disabled",
              disabled: true,
              icon: FeatherIcons.award,
              rightText: "323",
              rightTextPurpose: Purpose.GUIDE,
            ),
            ListItem(
              mainText: "Feed",
              icon: FeatherIcons.mail,
              rightText: "3",
              rightTextPurpose: Purpose.GUIDE,
              purpose: Purpose.WARNING,
            ),
            ListItem(
              purpose: Purpose.HIGHLIGHT,
              mainText: "Participation",
              icon: FeatherIcons.rss,
              rightText: "3",
              rightTextPurpose: Purpose.GUIDE,
            )
          ]),
        ],
      ),
    );
  }
}
