import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DevUiElements extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "Post",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(text: "Simple item"),
            ListItem(
                text: "Item with default badge",
                rightText: "3",
                rightTextStyle: RightItemStyle.BADGE),
            ListItem(
                text: "Item with long badge",
                rightText: "9323",
                rightTextStyle: RightItemStyle.BADGE),
            ListItem(
              text: "Item with danger badge",
              rightText: "!",
              rightTextStyle: RightItemStyle.BADGE_DANGER,
            ),
            ListItem(
              text: "Item with secondary text",
              rightText: "Sat, Aug 3",
            ),
            ListItem(text: "With icon", icon: FeatherIcons.anchor),
            ListItem(
                text: "Item with icon and badge ",
                rightText: "Sat, Aug 3",
                icon: FeatherIcons.anchor),
            ListItem(
                text: "Item with right icon ",
                rightIcon: FeatherIcons.info,
                icon: FeatherIcons.anchor),

            ListItem(
                text: "Item with a very very long text that doesn't fit ",
                rightIcon: FeatherIcons.info,
                icon: FeatherIcons.anchor),
          ],
        ));
  }
}
