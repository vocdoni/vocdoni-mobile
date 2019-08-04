import "package:flutter/material.dart";
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class DevUiListItem extends StatelessWidget {
  @override
  Widget build(ctx) {
    String avatarUrl =
        "https://i.pinimg.com/originals/23/4c/88/234c888d9ffb6955eb440b0d99a37fd1.jpg";
    return Scaffold(
        appBar: TopNavigation(
          title: "List item variants",
        ),
        body: ListView(
          children: <Widget>[
            ListItem(mainText: "Simple item"),
            ListItem(
              mainText: "Item with no chevron",
              rightIcon: null,
            ),
            ListItem(
                mainText: "Item with default badge",
                rightText: "3",
                rightTextStyle: RightTextStyle.BADGE),
            ListItem(
                mainText: "Item with long badge",
                rightText: "9323",
                rightTextStyle: RightTextStyle.BADGE),
            ListItem(
              mainText: "Item with danger badge",
              rightText: "!",
              rightTextStyle: RightTextStyle.BADGE_DANGER,
            ),
            ListItem(
              mainText: "Item with secondary text",
              rightText: "Sat, Aug 3",
            ),
            ListItem(mainText: "With icon", icon: FeatherIcons.anchor),
            ListItem(
                mainText: "Item with icon and badge ",
                rightText: "Sat, Aug 3",
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "Item with right icon ",
                rightIcon: FeatherIcons.info,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "Item with a very very long text that doesn't fit ",
                rightIcon: FeatherIcons.info,
                icon: FeatherIcons.anchor),
            ListItem(
              mainText:
                  "Item with an event longer very very very very long text that doesn't fit even int two lines ",
              rightIcon: null,
            ),
            ListItem(
              mainText:
                  "Lon text with multiline disabled. Bla bla bla bla bla bla bla bla bla bla",
              rightIcon: null,
              mainTextMultiline: false,
            ),
            ListItem(
              mainText: "Item with DANGER style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              itemStyle: ItemStyle.DANGER,
              onTap: () {},
            ),
            ListItem(
              mainText: "Item with WARNING style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              itemStyle: ItemStyle.WARNING,
              onTap: () {},
            ),
            ListItem(
              mainText: "Item with GOOD style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              itemStyle: ItemStyle.GOOD,
              onTap: () {},
            ),
            ListItem(
              mainText: "Item with HIGHLIGHT style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              itemStyle: ItemStyle.HIGHLIGHT,
              onTap: () {},
            ),
            ListItem(
              mainText: "Item disabled ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              onTap: () {},
              disabled: true,
            ),
            ListItem(
              mainText: "Item disabled with style ",
              rightText: "Sat, Aug 3",
              icon: FeatherIcons.anchor,
              itemStyle: ItemStyle.HIGHLIGHT,
              onTap: () {},
              disabled: true,
            ),
            ListItem(
              mainText: "Simple item",
              secondaryText: "With secondary text",
            ),
            ListItem(
              mainText: "Item with no chevron",
              secondaryText: "With secondary text",
              rightIcon: null,
            ),
            ListItem(
                mainText: "Item with default badge",
                secondaryText: "With secondary text",
                rightText: "3",
                rightTextStyle: RightTextStyle.BADGE),
            ListItem(
                mainText: "Item with long badge",
                secondaryText: "With secondary text",
                rightText: "9323",
                rightTextStyle: RightTextStyle.BADGE),
            ListItem(
              mainText: "Item with secondary text",
              secondaryText: "With secondary text",
              rightText: "Sat, Aug 3",
            ),
            ListItem(
                mainText: "With icon",
                secondaryText: "With secondary text",
                secondaryTextMultiline: true,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "With icon",
                secondaryText: "With very very very very long secondary text",
                secondaryTextMultiline: true,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "With icon",
                secondaryText:
                    "With a very very very very long secondary text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                secondaryTextMultiline: true,
                icon: FeatherIcons.anchor),

            ListItem(
                mainText: "With icon",
                secondaryText:
                    "Multiline disabled. text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                icon: FeatherIcons.anchor),

            //ICON IS SECONDARY
            ListItem(
                mainText: "With secondary icon",
                secondaryText: "With secondary text",
                secondaryTextMultiline: true,
                iconIsSecondary: true,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "With secondary icon",
                secondaryText: "With very very very very long secondary text",
                secondaryTextMultiline: true,
                iconIsSecondary: true,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText: "With secondary icon",
                secondaryText:
                    "With a very very very very long secondary text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                secondaryTextMultiline: true,
                iconIsSecondary: true,
                icon: FeatherIcons.anchor),

            ListItem(
                mainText: "With iconWith secondary icon",
                secondaryText:
                    "Multiline disabled. text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                iconIsSecondary: true,
                icon: FeatherIcons.anchor),
            ListItem(
                mainText:
                    "Very long main text with more than one line. Bla bla bla bla bla",
                secondaryText:
                    "With a very very very very long secondary text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                secondaryTextMultiline: true,
                iconIsSecondary: true,
                icon: FeatherIcons.anchor),

            ListItem(
                mainText:
                    "Very long main text with more than one line. Bla bla bla bla blan",
                secondaryText:
                    "Multiline disabled. text that does not not fit in three lines. Bla bla bla bla bla bla bla",
                iconIsSecondary: true,
                secondaryTextMultiline: true,
                icon: FeatherIcons.anchor),
            ListItem(
              mainText: "Item with avatar",
              avatarUrl: avatarUrl,
            ),

            ListItem(
              mainText: "Item with avatar and subtitle",
              avatarUrl: avatarUrl,
              secondaryText: "This is a secondary text",
            ),
            ListItem(
              mainText: "Item with secondary avatar and subtitle ",
              avatarUrl: avatarUrl,
              secondaryText: "This is a secondary text",
              iconIsSecondary: true,
            ),

            ListItem(
              mainText: "Item with avatar",
              avatarUrl: avatarUrl,
            ),

            ListItem(
              mainText: "Item with avatar and subtitle",
              //avatarUrl: avatarUrl,
              secondaryText: "This is a secondary text",
            ),
            ListItem(
              mainText: "Item with secondary avatar and subtitle ",
              //avatarUrl: avatarUrl,
              secondaryText: "This is a secondary text",
              iconIsSecondary: true,
            ),
          ],
        ));
  }
}
