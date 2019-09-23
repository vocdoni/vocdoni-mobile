import "package:flutter/material.dart";
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/constants/colors.dart';


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
          BaseCard(image: headerImg),
          BaseCard(children: [ListItem(mainText: "Hello")]),
          BaseCard(image: headerImg, children: [ListItem(mainText: "Hello")]),
          BaseCard(image: headerImg, children: [
            ListItem(
              mainText: "Where would you like the next retreat?",
              icon: FeatherIcons.barChart2,
              avatarUrl: avatar,
              secondaryText: "Vocdoni",
              mainTextFullWidth: true,
              rightText: "Aug, Mon 2",
            )
          ]),
          BaseCard(image: headerImg, children: [
            ListItem(
              mainText: "Where would you like the next retreat?",
              icon: FeatherIcons.barChart2,
              avatarUrl: avatar,
              secondaryText: "Vocdoni",
              mainTextFullWidth: true,
              rightText: "Aug, Mon 2",
              isBold: true,
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
              rightTextIsBadge: true,
            ),
            ListItem(
              mainText: "Feed",
              icon: FeatherIcons.mail,
              rightText: "3",
              rightTextPurpose: Purpose.HIGHLIGHT,
              rightTextIsBadge: true,
            ),
            ListItem(
              mainText: "Participation",
              icon: FeatherIcons.rss,
              rightText: "3",
              rightTextPurpose: Purpose.GUIDE,
              rightTextIsBadge: true,
            )
          ]),
          BaseCard(children: [
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
            ),
          ]),
          BaseCard(
            children: [
              ListItem(
                mainText: "Alice",
                avatarUrl:
                    "https://i.pinimg.com/originals/23/4c/88/234c888d9ffb6955eb440b0d99a37fd1.jpg",
              )
            ],
          ),
          BaseCard(
            children: [
              ListItem(
                mainText: "Bob",
                avatarUrl:
                    "https://i.pinimg.com/236x/bb/16/8f/bb168fccd16e48dc2850377c2203b065--spongebob-birthday-party-th-birthday.jpg",
              )
            ],
          ),
          BaseCard(
            children: [
              ListItem(
                purpose: Purpose.GOOD,
                disabled:  true,
                secondaryText: "Secondary text",
                mainText: "Avatar disabled",
                avatarUrl:
                    "https://i.pinimg.com/originals/23/4c/88/234c888d9ffb6955eb440b0d99a37fd1.jpg",
              )
            ],
          ),
        ],
      ),
    );
  }
}
