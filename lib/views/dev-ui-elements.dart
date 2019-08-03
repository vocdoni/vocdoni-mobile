import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DevUiElements extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "List item variants",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(text: "Simple item"),
            ListItem(
              text: "Item with no chevron",
              rightIcon: null,
            ),
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
            ListItem(
              text:
                  "Item with an event longer very very very very long text that doesn't fit even int two lines ",
              rightIcon: null,
            ),
            ListItem(
              text:
                  "Lon text with multiline disabled. Bla bla bla bla bla bla bla bla bla bla",
              rightIcon: null,
              mainTextMultiline: false,
            ),
            ListItem(
              text: "Item with DANGER style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              style: ItemStyle.DANGER,
              onTap: () {},
            ),
            ListItem(
              text: "Item with WARNING style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              style: ItemStyle.WARNING,
              onTap: () {},
            ),
            ListItem(
              text: "Item with GOOD style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              style: ItemStyle.GOOD,
              onTap: () {},
            ),
            ListItem(
              text: "Item with HIGHLIGHT style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              style: ItemStyle.HIGHLIGHT,
              onTap: () {},
            ),
            ListItem(
              text: "Item disabled ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              onTap: () {},
              disabled: true,
            ),
            ListItem(
              text: "Item disabled with style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              style: ItemStyle.HIGHLIGHT,
              onTap: () {},
              disabled: true,
            )
          ],
        ));
  }
}
